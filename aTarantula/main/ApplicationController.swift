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
            application.presentError(error)
            fatalError("ApplicationController failed to initialize")
        }
    }

    func loadPluginsInBackground(finished: @escaping () -> Void) {
        let startupOperation = BlockOperation {
            do {
                try self.pluginLoader.loadPlugins()
            }
            catch let error as PluginLoader.LoadingError {
                OperationQueue.main.addOperation {
                    self.application.presentError(NSError(domain: self.application.name, code: -1, userInfo: [kCFErrorDescriptionKey as String: error.localizedDescription]))
                    fatalError("Error while loading plugins")
                }
            }
            catch let error {
                fatalError(error.localizedDescription)
            }

            OperationQueue.main.addOperation(finished)
        }

        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.addOperation(startupOperation)
    }

    func loadDataSingle(plugin: TarantulaCrawlingPlugin, finished: @escaping () -> ()) throws {
        do {
            try self.dataLoader.loadStore(named: plugin.name, managedObjectModel: plugin.managedObjectModel) { controller in
                plugin.repository = controller.repository
                OperationQueue.main.addOperation(finished)
            }
        }
        catch let error {
            OperationQueue.main.addOperation {
                self.application.presentError(NSError(domain: self.application.name, code: -1, userInfo: [kCFErrorDescriptionKey as String: error.localizedDescription]))
            }
            throw error
        }
    }

    func loadDataInBackground(finished: @escaping () -> Void) {
        let errorOperation = { (error: Error) -> () in
            OperationQueue.main.addOperation {
                fatalError("Error while loading data: \(error)")
            }
        }

        let startupOperation = BlockOperation {
            var tail: (([TarantulaCrawlingPlugin]) -> ())! = nil

            tail = { (rest: [TarantulaCrawlingPlugin]) -> () in
                let recursion: () -> () = {
                    tail(Array(rest.dropFirst()))
                }
                if let plugin = rest.first {
                    do {
                        try self.loadDataSingle(plugin: plugin, finished: recursion)
                    }
                    catch let error {
                        errorOperation(error)
                    }
                } else {
                    OperationQueue.main.addOperation(finished)
                }
            }
            tail(self.pluginLoader.crawlers)
        }

        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.addOperation(startupOperation)
    }

}
