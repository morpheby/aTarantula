//___FILEHEADER___

import Cocoa
import TarantulaPluginCore

class SettingsViewController: NSViewController {
    var plugin: ___PACKAGENAMEASIDENTIFIER___CrawlerPlugin!
    @objc dynamic var filterDrugName: String? = UserDefaults.standard.filterDrugName {
        didSet {
            UserDefaults.standard.filterDrugName = filterDrugName
        }
    }
    var filterSetting: FilterSetting = (UserDefaults.standard.filterSetting.flatMap { x in FilterSetting(rawValue: x) }) ?? .noFilter {
        didSet {
            UserDefaults.standard.filterSetting = filterSetting.rawValue
        }
    }
    @IBOutlet var noFilterButton: NSButton!
    @IBOutlet var filterByNameButton: NSButton!

    enum FilterSetting: Int {
        case noFilter = 0
        case drugNameFilter = 1
    }

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

    @IBAction func selectFilter(_ sender: NSButton!) {
        switch sender {
        case noFilterButton:
            filterSetting = .noFilter
        case filterByNameButton:
            filterSetting = .drugNameFilter
        default:
            fatalError("Choice not implemented")
        }
    }

    @IBAction func eraseDatabase(_ sender: Any?) {
        guard let repository = plugin.repository else {
            fatalError("Repository uninitialized")
        }

        var objectCount = 0
        repository.performAndWait {
            for type in self.plugin.allObjectTypes {
                objectCount += repository.countAllObjects(type)
            }
        }

        let alert = NSAlert()
        alert.addButton(withTitle: "Yes, delete \(objectCount) objects")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Delete all \(objectCount) objects from the database?"
        alert.informativeText = "Deleted objects cannot be restored."
        alert.alertStyle = .warning;

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        repository.performAndWait {
            for type in self.plugin.allObjectTypes {
                let allObjects = repository.readAllObjects(type)
                for object in allObjects {
                    repository.delete(object: object)
                }
            }
        }
    }

    @IBAction func unfilterAll(_ sender: Any?) {
        guard let repository = plugin.repository else {
            fatalError("Repository uninitialized")
        }

        repository.performAndWait {
            for type in self.plugin.crawlableObjectTypes {
                let allObjects = repository.readAllObjects(type, withSelection: .unselectedObjects) as! [CrawlableObject]
                for object in allObjects {
                    object.objectIsSelected = true
                }
            }
        }
    }

    @IBAction func assignFilter(_ sender: Any?) {
        switch filterSetting {
        case .noFilter:
            self.plugin.filterMethod = .none
        case .drugNameFilter:
            guard let drugName = filterDrugName else {
                let alert = NSAlert()
                alert.addButton(withTitle: "OK")
                alert.messageText = "Enter drug name"
                alert.alertStyle = .warning
                alert.runModal()
                return
            }
            self.plugin.filterMethod = .closure({ object in
                switch object {
                // TODO: Input filter methods here
                default:
                    return false
                }
            })
        }
    }

    @IBAction func invokeFilter(_ sender: Any?) {
        guard let repository = plugin.repository else {
            fatalError("Repository uninitialized")
        }

        repository.performAndWait {
            for type in self.plugin.crawlableObjectTypes {
                let allObjects = repository.readAllObjects(type, withSelection: .all) as! [CrawlableObject]
                for object in allObjects {
                    object.objectIsSelected = needsToBeSelected(object: object, filterMethod: self.plugin.filterMethod)
                }
            }
        }
    }

    @IBAction func specialButton(_ sender: Any?) {
        // A special place to implement any temporary function :)
        Configuration.specialButton(self.plugin)
    }
}

extension UserDefaults {
    var filterDrugName: String? {
        get {
            return self.string(forKey: "\(Configuration.pluginName)_filterDrugName")
        }
        set {
            self.set(newValue, forKey: "\(Configuration.pluginName)_filterDrugName")
        }
    }

    var filterSetting: Int? {
        get {
            return self.integer(forKey: "\(Configuration.pluginName)_filterSetting")
        }
        set {
            self.set(newValue, forKey: "\(Configuration.pluginName)_filterSetting")
        }
    }
}
