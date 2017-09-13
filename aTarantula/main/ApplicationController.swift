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

    func loadPlugins() throws {
        try self.pluginLoader.loadPlugins()
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

}
