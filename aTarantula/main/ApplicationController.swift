//
//  ApplicationController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/3/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

class ApplicationController {
    weak var application: NSApplication! = NSApplication.shared

    // Since we have no way to retain window after segue natively, we have to retain it somewhere...
    var mainWindow: NSWindowController? = NSApplication.shared.keyWindow?.windowController

    var pluginLoader: PluginLoader
    var dataController: DataController?

    init() {
        do {
            pluginLoader = try PluginLoader()
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

    func tmpLoadDataController() {
        let allMomd = pluginLoader.crawlers.map { plugin in plugin.managedObjectModel}
        let momd = NSManagedObjectModel(byMerging: allMomd)!
        dataController = try! DataController(modelName: "TmpModel", managedObjectModel: momd)
    }

}
