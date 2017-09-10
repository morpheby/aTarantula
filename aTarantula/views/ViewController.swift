//
//  ViewController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 8/18/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Cocoa
import TarantulaPluginCore

class ViewController: NSViewController {

    @objc dynamic var crawler: Crawler?
    @IBOutlet var objectController: NSObjectController!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.crawler = Crawler()

    }

    @IBAction func loadPlugin(_ sender: Any?) {
        NSApplication.shared.controller.tmpLoadDataController()
    }

    @IBAction func start(_ sender: Any?) {
        self.crawler?.name = "Other"
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.identifier {
        case .some(.ExportingSegue):
            guard let editorViewController = segue.destinationController as? CDEEditorViewController else {
                fatalError("Invalid segue: \(segue)")
            }
            let configuration = CDEConfiguration()
//            configuration
            let appController = NSApplication.shared.controller
            try! editorViewController.configure(with: configuration, model: appController.dataController!.managedObjectModel, objectContext: appController.dataController!.persistentContainer.viewContext)
        default:
            break
        }

    }

}

extension NSStoryboardSegue.Identifier {
    static let ExportingSegue = NSStoryboardSegue.Identifier("exporting")
}

