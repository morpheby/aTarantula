//
//  PluginDrawerViewController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/10/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Cocoa
import TarantulaPluginCore

class PluginDrawerViewController: NSViewController {

    var rowHeights: [Int: Float] = [:]
    var activeObject: PluginInfoWrapper?
    var exportData: (PluginInfoWrapper, URL)? = nil
    var importData: (PluginInfoWrapper, URL)? = nil

    @objc class PluginInfoWrapper: NSObject {
        typealias Index = Array<ApplicationController.PluginInfo>.Index
        let pluginIndex: Index

        var plugin: TarantulaCrawlingPlugin {
            get { return NSApplication.shared.controller.crawlingPlugins[pluginIndex].plugin }
        }

        @objc dynamic var name: String {
            get { return NSApplication.shared.controller.crawlingPlugins[pluginIndex].plugin.name }
        }

        @objc dynamic var enabled: Bool {
            get { return NSApplication.shared.controller.crawlingPlugins[pluginIndex].enabled }
            set { NSApplication.shared.controller.crawlingPlugins[pluginIndex].enabled = newValue }
        }

        init(pluginIndex: Index) {
            self.pluginIndex = pluginIndex
        }
    }

    @objc dynamic var plugins = NSApplication.shared.controller.crawlingPlugins.indices.map { i in PluginInfoWrapper(pluginIndex: i) }

    @objc dynamic var overwriteDatabaseFlag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func openEditor(_ object: AnyObject) {
        guard let selected = object as? PluginInfoWrapper else {
            fatalError("Invalid object supplied")
        }

        activeObject = selected
        performSegue(withIdentifier: .editorSegue, sender: self)
    }

    @IBAction func exportData(_ object: AnyObject) {
        guard let selected = object as? PluginInfoWrapper else {
            fatalError("Invalid object supplied")
        }

        let savePanel = NSSavePanel()
        savePanel.message = "Select export location"
        savePanel.nameFieldLabel = "Export file:"
        savePanel.nameFieldStringValue = selected.name
        savePanel.allowedFileTypes = ["sqlite"]
        savePanel.allowsOtherFileTypes = false

        savePanel.beginSheetModal(for: view.window!, completionHandler: { response in
            switch (response) {
            case .OK:
                self.exportData = (selected, savePanel.url!)
                self.performSegue(withIdentifier: .migrateSegue, sender: self)
            default:
                break
            }
        })
    }

    @IBAction func importData(_ object: AnyObject) {
        guard let selected = object as? PluginInfoWrapper else {
            fatalError("Invalid object supplied")
        }

        let openPanel = NSOpenPanel()
        openPanel.message = "Select database to import for \(selected.name)"
        openPanel.nameFieldLabel = "Database file:"
        openPanel.nameFieldStringValue = selected.name
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
                self.importData = (selected, openPanel.url!)
                self.performSegue(withIdentifier: .migrateSegue, sender: self)
            default:
                break
            }
        })
    }

    @IBAction func openSettings(_ object: AnyObject) {
        guard let selected = object as? PluginInfoWrapper else {
            fatalError("Invalid object supplied")
        }

        let plugin = selected.plugin

        guard let viewController = plugin.settingsViewController else {
            presentError(PluginError.noSettings)
            return
        }
        presentViewControllerAsModalWindow(viewController)
    }

    @IBAction func openNetworkSettings(_ object: AnyObject) {
        guard let selected = object as? PluginInfoWrapper else {
            fatalError("Invalid object supplied")
        }

        activeObject = selected
        performSegue(withIdentifier: .networkSettingsSegue, sender: self)
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.identifier {
        case .some(.editorSegue):
            guard let editorViewController = segue.destinationController as? CDEEditorViewController else {
                fatalError("Invalid segue: \(segue)")
            }
            let configuration = CDEConfiguration()
            let appController = NSApplication.shared.controller
            guard let plugin = activeObject?.plugin else {
                fatalError("Button was pushed, but no information persisted")
            }
            let store = appController.dataLoader.stores[plugin.name]!
            appController.withDefaultError {
                try editorViewController.configure(with: configuration, model: plugin.managedObjectModel, objectContext: store.persistentContainer.viewContext)
            }
        case .some(.migrateSegue):
            guard let loadingViewController = segue.destinationController as? LoadingViewController else {
                fatalError("Invalid segue: \(segue)")
            }

            if let (selected, targetUrl) = exportData {
                loadingViewController.task = .exportStore(name: selected.name, to: targetUrl)
            } else if let (selected, targetUrl) = importData {
                loadingViewController.task = .importStore(name: selected.name, from: targetUrl, destroy: overwriteDatabaseFlag)
            } else {
                fatalError("Button was pushed, but no information persisted")
            }
        case .some(.networkSettingsSegue):
            guard let networkViewController = segue.destinationController as? NetworkSettingsViewController else {
                fatalError("Invalid segue: \(segue)")
            }

            let appController = NSApplication.shared.controller
            guard let plugin = activeObject?.plugin else {
                fatalError("Button was pushed, but no information persisted")
            }
            guard let networkManager = plugin.networkManager as? DefaultNetworkManager else {
                fatalError("Internal Error: Network Manager unset or invalid")
            }
            networkViewController.networkManager = networkManager
            networkViewController.plugin = plugin
        default:
            break
        }

        // Reset active objects
        activeObject = nil
        exportData = nil
        importData = nil
    }

    override func dismissViewController(_ viewController: NSViewController) {
        super.dismissViewController(viewController)
        activeObject = nil
    }

    enum PluginError: LocalizedError {
        case noSettings

        var errorDescription: String? {
            switch (self) {
            case .noSettings:
                return "Plugin doesn't have settings"
            }
        }
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
