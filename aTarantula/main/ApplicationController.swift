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

    let pluginController: PluginController
//    let dataController: DataController

    init() {
        do {
            pluginController = try PluginController()
//            dataController = try DataController()
        }
        catch let error {
            application.presentError(error)
            fatalError("ApplicationController failed to initialize")
        }
    }

    func loadPluginsInBackground(finished: @escaping () -> Void) {
        let startupOperation = BlockOperation {
            do {
                try self.pluginController.loadPlugins()
            }
            catch let error {
                OperationQueue.main.addOperation {
                    self.application.presentError(error)
                    fatalError("Error while loading plugins")
                }
            }

            OperationQueue.main.addOperation(finished)
        }

        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.addOperation(startupOperation)
    }

}
