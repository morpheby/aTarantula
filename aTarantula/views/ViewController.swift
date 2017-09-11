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
    @IBOutlet var secondProgressIndicator: NSProgressIndicator!

    @objc dynamic var pluginNames: [String]  {
        return NSApplication.shared.controller.pluginLoader.crawlers.map { plugin in plugin.name }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.crawler = Crawler()
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        if let layer = secondProgressIndicator.layer {
            layer.anchorPoint = CGPoint(x: 1, y: 0)
            layer.transform = CATransform3DMakeScale(-1.0, 1.0, 1.0)
        }
    }

    @IBAction func start(_ sender: Any?) {
        self.crawler?.name = "Other"
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.identifier {
        case .some(.pluginDrawerSegue):
            guard let destinationViewController = segue.destinationController as? NSViewController else {
                fatalError("Invalid segue: \(segue)")
            }
            destinationViewController.representedObject = pluginNames
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
