//
//  SettingsViewController.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/11/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController {
    var plugin: ATARCrawlExampleWebsiteCrawlerPlugin!

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch (segue.identifier) {
        case .some(.initialObject):
            guard let viewController = segue.destinationController as? InitialObjectViewController else {
                fatalError("Invalid segue")
            }
            viewController.plugin = plugin
            break
        default:
            break
        }
    }

    @IBAction func eraseDatabase(_ sender: Any?) {
        guard let repository = plugin.repository else {
            fatalError("Repository uninitialized")
        }

        repository.performAndWait {
            for type in self.plugin.allObjectTypes {
                let allObjects = repository.readAllObjects(type, withSelection: .all)
                for object in allObjects {
                    repository.delete(object: object)
                }
            }
        }
    }
}
