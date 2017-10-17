//
//  ApplicationController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/3/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

class ApplicationController {
    weak var application: NSApplication! = NSApplication.shared

    // Since we have no way to retain window after segue natively, we have to retain it somewhere...
    var mainWindow: NSWindowController? = NSApplication.shared.keyWindow?.windowController

    var pluginLoader: PluginLoader
    var dataLoader: DataLoader

    struct PluginInfo {
        private let key: String

        init(plugin: TarantulaCrawlingPlugin) {
            self.plugin = plugin
            self.key = "aTarantula_PluginEnabled_\(plugin.name)"
            if UserDefaults.standard.value(forKey: key) == nil {
                UserDefaults.standard.set(true, forKey: key)
            }
        }

        var plugin: TarantulaCrawlingPlugin
        var enabled: Bool {
            get {
                return UserDefaults.standard.bool(forKey: key)
            }
            set {
                UserDefaults.standard.set(newValue, forKey: key)
            }
        }
    }

    var crawlingPlugins: [PluginInfo] = []
    var crawlers: [TarantulaCrawlingPlugin] {
        return crawlingPlugins.lazy.filter { pi in pi.enabled } .map { pi in pi.plugin }
    }

    init() {
        do {
            pluginLoader = try PluginLoader()
            dataLoader = DataLoader()
        }
        catch let error  {
            ApplicationController.showDescribedErrorUnbound(error: error)
            fatalError("ApplicationController failed to initialize")
        }
    }

    @discardableResult
    class func showDescribedErrorUnbound(error: Error) -> Bool {
        let firstResponder: NSResponder = NSApplication.shared.keyWindow?.firstResponder ?? NSApplication.shared
        let result = firstResponder.presentError(error)
        return result
    }

    class func showDescribedErrorAsyncUnbound(error: Error, failure: @escaping () -> ()) {
        OperationQueue.main.addOperation {
            let result = showDescribedErrorUnbound(error: error)
            if !result {
                failure()
            }
        }
    }

    func showDescribedErrorAsync(error: Error, failure: @escaping () -> ()) {
        ApplicationController.showDescribedErrorAsyncUnbound(error: error, failure: failure)
    }

    func withDefaultError(_ closure: @escaping () throws -> ()) {
        withDefaultError(closure, failure: nil)
    }

    func withDefaultError(_ closure: @escaping () throws -> (), failure: (() -> ())?) {
        do {
            try closure()
        }
        catch let error {
            showDescribedErrorAsync(error: error) {
                if let f = failure {
                    f()
                }
            }
        }
    }

    func backgroundQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        return queue
    }

    var mainQueue: OperationQueue {
        return OperationQueue.main
    }

    func delay(_ time: TimeInterval, _ closure: @escaping () -> ()) {
        guard let queue = OperationQueue.current else {
            // No queue, but don't despair, just report and do
            debugPrint("ApplicationController.delay called, but no queue present")
            debugPrint("Set a breakpoint at ApplicationController.delay to investigate")
            closure()
            return
        }

        let bkgQueue = DispatchQueue(label: "delay_queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)
        
        let timeInt = Int((time * 1e9).rounded())
        bkgQueue.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.nanoseconds(timeInt), execute: {
            queue.addOperation {
                closure()
            }
        })
    }

    func initPlugin(plugin: TarantulaCrawlingPlugin) {
        let nm = DefaultNetworkManager()
        nm.configuration.httpCookieStorage = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: plugin.name)
        nm.configuration.httpCookieStorage?.cookieAcceptPolicy = .always
        plugin.networkManager = nm
    }

    func initAllPlugins() {
        for plugin in pluginLoader.crawlers {
            initPlugin(plugin: plugin)
        }
    }

    func loadPlugins() throws {
        try self.pluginLoader.loadPlugins()
        self.crawlingPlugins = self.pluginLoader.crawlers.map { plugin in
            PluginInfo(plugin: plugin)
        }
    }

    func loadDataSingle(plugin: TarantulaCrawlingPlugin, finished: @escaping () -> ()) throws {
        try self.dataLoader.loadStore(named: plugin.name, managedObjectModel: plugin.managedObjectModel) { controller in
            plugin.repository = controller.repository
            finished()
        }
    }

    func loadAllDataInBackground(finished: @escaping () -> ()) {
        var tail: (([TarantulaCrawlingPlugin]) -> ())! = nil
        let queue = backgroundQueue()

        tail = { (rest: [TarantulaCrawlingPlugin]) -> () in
            let recursion: () -> () = {
                queue.addOperation {
                    tail(Array(rest.dropFirst()))
                }
            }
            if let plugin = rest.first {
                do {
                    try self.loadDataSingle(plugin: plugin, finished: recursion)
                }
                catch let error {
                    self.showDescribedErrorAsync(error: error) { }
                }
            } else {
                OperationQueue.main.addOperation(finished)
            }
        }
        queue.addOperation {
            tail(self.pluginLoader.crawlers)
        }
    }

    func cookies(inPlugin plugin: TarantulaCrawlingPlugin) -> [HTTPCookie] {
        guard let nm = plugin.networkManager as? DefaultNetworkManager else {
            fatalError("Invalid NetworkManager instance")
        }
        let cookieStorage = nm.session.configuration.httpCookieStorage!
        return cookieStorage.cookies ?? []
    }

    func setCookies(_ cookies: [HTTPCookie], inPlugin plugin: TarantulaCrawlingPlugin) {
        let cookieCopy = cookies.map { c in HTTPCookie(properties: c.properties!)! }
        guard let nm = plugin.networkManager as? DefaultNetworkManager else {
            fatalError("Invalid NetworkManager instance")
        }
        let cookieStorage = nm.session.configuration.httpCookieStorage!
        cookieStorage.removeCookies(since: .distantPast)
        mainQueue.addOperation {
            for cookie in cookieCopy {
                cookieStorage.setCookie(cookie)
            }
        }
    }

}
