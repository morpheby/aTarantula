//
//  PluginDrawerViewController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/10/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Cocoa

class PluginDrawerViewController: NSViewController {

    var rowHeights: [Int: Float] = [:]
    var activeObject: AnyObject?

    @objc dynamic var overwriteDatabaseFlag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func openEditor(_ object: AnyObject) {
        assert(object is String, "Invalid object supplied to action")

        activeObject = object
        performSegue(withIdentifier: .editorSegue, sender: self)
    }

    @IBAction func exportData(_ object: AnyObject) {
        guard let selectedName = object as? String else {
            fatalError("Invalid object supplied")
        }

        let savePanel = NSSavePanel()
        savePanel.message = "Select export location"
        savePanel.nameFieldLabel = "Export file:"
        savePanel.nameFieldStringValue = selectedName
        savePanel.allowedFileTypes = ["sqlite"]
        savePanel.allowsOtherFileTypes = false

        savePanel.beginSheetModal(for: view.window!, completionHandler: { response in
            switch (response) {
            case .OK:
                self.activeObject = (selectedName, savePanel.url) as AnyObject
                self.performSegue(withIdentifier: .migrateSegue, sender: self)
            default:
                break
            }
        })
    }

    @IBAction func importData(_ object: AnyObject) {
        guard let selectedName = object as? String else {
            fatalError("Invalid object supplied")
        }

        let openPanel = NSOpenPanel()
        openPanel.message = "Select database to import for \(selectedName)"
        openPanel.nameFieldLabel = "Database file:"
        openPanel.nameFieldStringValue = selectedName
        openPanel.allowedFileTypes = ["sqlite"]
        openPanel.allowsOtherFileTypes = false

        var objects: [AnyObject] = []
        var objRef: NSArray? = nil

        let nib = NSNib(nibNamed:  .openPanelAccessoryNib, bundle: Bundle(for: PluginDrawerViewController.self))!
        guard nib.instantiate(withOwner: self, topLevelObjects: &objRef) else {
            fatalError("No nib \(NSNib.Name.openPanelAccessoryNib.rawValue) is present")
        }
        objects = objRef! as [AnyObject]

        guard let rootUntyped = (objects.filter { o in (o as? NSView)?.identifier == .rootIdentifier }.first),
        let root = rootUntyped as? NSView else {
            fatalError("Invalid nib file — no root view present")
        }
        
        openPanel.accessoryView = root

        openPanel.beginSheetModal(for: view.window!, completionHandler: { response in
            switch (response) {
            case .OK:
                self.activeObject = (openPanel.url, selectedName) as AnyObject
                self.performSegue(withIdentifier: .migrateSegue, sender: self)
            default:
                break
            }
        })
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.identifier {
        case .some(.editorSegue):
            guard let editorViewController = segue.destinationController as? CDEEditorViewController else {
                fatalError("Invalid segue: \(segue)")
            }
            guard let selectedName = activeObject as? String else {
                fatalError("Invalid state of activeObject")
            }
            let configuration = CDEConfiguration()
            let appController = NSApplication.shared.controller
            guard let plugin = (appController.pluginLoader.crawlers.filter { plugin in plugin.name == selectedName } .first) else {
                fatalError("Plugin was reported, but doesn't exist")
            }
            let store = appController.dataLoader.stores[plugin.name]!
            appController.withDefaultError {
                try editorViewController.configure(with: configuration, model: plugin.managedObjectModel, objectContext: store.persistentContainer.viewContext)
            }
        case .some(.migrateSegue):
            guard let loadingViewController = segue.destinationController as? LoadingViewController else {
                fatalError("Invalid segue: \(segue)")
            }

            switch (activeObject) {
            case let (selectedName, targetUrl) as (String, URL):
                // Export
                loadingViewController.task = .exportStore(name: selectedName, to: targetUrl)
            case let (targetUrl, selectedName) as (URL, String):
                // Import (yep, this is ugly, and I'm lazy)
                loadingViewController.task = .importStore(name: selectedName, from: targetUrl, destroy: overwriteDatabaseFlag)
            default:
                fatalError("Invalid state of activeObject")
            }

        default:
            break
        }
    }

    override func dismissViewController(_ viewController: NSViewController) {
        super.dismissViewController(viewController)
        activeObject = nil
    }
    
}

extension PluginDrawerViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        rowHeights[row] = Float((rowView.view(atColumn: 0) as! NSView).fittingSize.height)
        tableView.noteHeightOfRows(withIndexesChanged: [row])
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(rowHeights[row] ?? Float(tableView.rowHeight))
    }
}
