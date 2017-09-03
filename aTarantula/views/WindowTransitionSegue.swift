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
                assertionFailure("No window present for source")
                fatalError()
            }
            guard let wndController = window.windowController else {
                assertionFailure("Source window must be managed by a controller")
                fatalError()
            }
            sourceWindowController = wndController
        default:
            assertionFailure("Invalid source controller")
            fatalError()
        }

        destinationWindowController.window?.makeKeyAndOrderFront(self)
        destinationWindowController.showWindow(self)

        NSApplication.shared.controller.mainWindow = destinationWindowController

        sourceWindowController.close()
    }
    
}
