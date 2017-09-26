//
//  WindowTransitionSegue.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/3/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

class WindowTransitionSegue: NSStoryboardSegue {

    override func perform() {
        assert(destinationController is NSWindowController)

        let sourceWindowController: NSWindowController
        let destinationWindowController: NSWindowController = destinationController as! NSWindowController

        switch sourceController {
        case let wnd as NSWindowController:
            sourceWindowController = wnd
        case let vc as NSViewController:
            guard let window = vc.view.window else {
                fatalError("No window present for source")
            }
            guard let wndController = window.windowController else {
                fatalError("Source window must be managed by a controller")
            }
            sourceWindowController = wndController
        default:
            fatalError("Invalid source controller")
        }

        destinationWindowController.window?.makeKeyAndOrderFront(self)
        destinationWindowController.showWindow(self)

        NSApplication.shared.controller.mainWindow = destinationWindowController

        sourceWindowController.close()
    }

}
