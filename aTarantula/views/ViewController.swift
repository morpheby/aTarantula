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
        // test
//        let appController = NSApplication.shared.controller
        self.performSegue(withIdentifier: .restartSegue, sender: self)
    }

    @IBAction func start(_ sender: Any?) {
        self.crawler?.name = "Other"
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.identifier {
        case .some(.exportingSegue):
            guard let editorViewController = segue.destinationController as? CDEEditorViewController else {
                fatalError("Invalid segue: \(segue)")
            }
            let configuration = CDEConfiguration()
            let appController = NSApplication.shared.controller
            let testPlugin = appController.pluginLoader.crawlers[0]
            let testStore = appController.dataLoader.stores[testPlugin.name]!
            try! editorViewController.configure(with: configuration, model: testPlugin.managedObjectModel, objectContext: testStore.persistentContainer.viewContext)
        case .some(.restartSegue):
            guard let loadingViewController = segue.destinationController as? LoadingViewController else {
                fatalError("Invalid segue: \(segue)")
            }
            loadingViewController.task = .migrate(source: "TestPlugin", to: URL(string: "file:///Users/morpheby/Downloads/test.aqlite")!)
        default:
            break
        }
    }

    override func dismissViewController(_ viewController: NSViewController) {
        super.dismissViewController(viewController)
        for (_, store) in NSApplication.shared.controller.dataLoader.stores {
            try? store.persistentContainer.viewContext.save()
            store.repository.perform { }
        }
    }

}

extension NSStoryboardSegue.Identifier {
    static let exportingSegue = NSStoryboardSegue.Identifier("exporting")
    static let restartSegue = NSStoryboardSegue.Identifier("restart")
}

