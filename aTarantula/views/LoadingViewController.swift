//
//  LoadingViewController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/3/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Cocoa

class LoadingViewController: NSViewController {

    @objc dynamic var status: String = "Initializing…"
    @objc dynamic var log: [String] = [] {
        didSet {
            tableLogView.noteHeightOfRows(withIndexesChanged: [log.count-1])
        }
    }
    @objc dynamic var triggerState: Bool = false
    @IBOutlet var logView: NSView!
    @IBOutlet var tableLogView: NSTableView!
    lazy var logViewConstraints: [NSLayoutConstraint] = {
        return self.view.constraints.filter { c in
            c.identifier == "logView"
        }
    }()

    var task: Task = .initialLoad

    override func viewDidLoad() {
        super.viewDidLoad()

        for constraint in logViewConstraints {
            constraint.isActive = triggerState
        }

        initializeObservations()

        switch (task) {
        case .initialLoad:
            beginStartup()
        case let .migrate(source: source, to: url):
            beginMigration(source: source, to: url)
        }
    }

    func initializeObservations() {
        let appController = NSApplication.shared.controller

        appController.pluginLoader.pluginLoadingObservable ∆= self >> { (self: LoadingViewController, pc: PluginLoader) in
            let state = pc.state
            appController.mainQueue.addOperation {
                switch (state) {
                case .waiting:
                    break
                case let .enumerating(dirUrl):
                    self.status = "Enumerating \(dirUrl.path)"
                    self.log.append(self.status)
                case let .skipping(dirUrl):
                    self.status = "Skipping \(dirUrl.path)"
                    self.log.append(self.status)
                case let .loading(pluginUrl):
                    self.status = "Loading \(pluginUrl.path)"
                    self.log.append(self.status)
                case let .error(error):
                    self.status = "Error"
                    self.log.append(error.localizedDescription)
                case .success:
                    self.status = "All plugins loaded"
                    self.log.append(self.status)
                }
            }
        }

        appController.dataLoader.dataLoadingObservable ∆= self >> { (self: LoadingViewController, dl: DataLoader) in
            let state = dl.loadingState
            appController.mainQueue.addOperation {
                switch (state) {
                case .na:
                    break
                case let .loadingStore(name):
                    self.status = "Loading data for \(name)"
                    self.log.append(self.status)
                case let .loadedStore(name):
                    self.status = "Loaded data for \(name)"
                    self.log.append(self.status)
                case let .asyncError(error):
                    self.status = "Unable to load: \(error.localizedDescription)"
                    self.log.append(self.status)
                }
            }
        }

        appController.dataLoader.dataMigrationObservable ∆= self >> { (self: LoadingViewController, dl: DataLoader) in
            let state = dl.migrationState
            appController.mainQueue.addOperation {
                switch (state) {
                case .na:
                    break
                case let .migratingStore(name):
                    self.status = "Migrating store for \(name)"
                    self.log.append(self.status)
                case let .disconnectingStore(name):
                    self.status = "Disconnecting store \(name) after migration"
                    self.log.append(self.status)
                case let .reconnectingStore(name):
                    self.status = "Reconnecting original store \(name) after migration"
                    self.log.append(self.status)
                case let .migratedStore(name):
                    self.status = "Store \(name) succesfully migrated"
                    self.log.append(self.status)
                case let .asyncError(error):
                    self.status = "Unable to migrate: \(error.localizedDescription)"
                    self.log.append(self.status)
                }
            }
        }
    }

    func beginMigration(source: String, to: URL) {
        let appController = NSApplication.shared.controller

        appController.backgroundQueue().addOperation {
            appController.withDefaultError {
                try appController.dataLoader.exportStore(named: source, to: to) {
                    appController.mainQueue.addOperation {
                        appController.delay(2.0) {
                            self.dismiss(self)
                        }
                    }
                }
            }
        }
    }

    func beginStartup() {
        let appController = NSApplication.shared.controller

        appController.backgroundQueue().addOperation {
            appController.withDefaultError {
                try appController.loadPlugins()
                appController.loadAllDataInBackground {
                    appController.mainQueue.addOperation {
                        self.status = "All data loaded"
                        self.log.append(self.status)
                        appController.delay(2.0) {
                            self.performSegue(withIdentifier: .StartupSegue, sender: self)
                        }
                    }
                }
            }
        }
    }

    @IBAction func triggerLog(sender: Any) {
        NSAnimationContext.runAnimationGroup({ (context) in
            logView.animator().isHidden = !triggerState

            // Animate
            for constraint in logViewConstraints {
                constraint.animator().isActive = triggerState
            }
        }) {
        }
    }
    var rowHeights: [Int: Float] = [:]

    enum Task {
        case initialLoad
        case migrate(source: String, to: URL)
    }
}

extension LoadingViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        rowHeights[row] = Float((rowView.view(atColumn: 0) as! NSView).fittingSize.height)
        tableView.noteHeightOfRows(withIndexesChanged: [row])
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(rowHeights[row] ?? Float(tableView.rowHeight))
    }
}

extension NSStoryboardSegue.Identifier {
    static let StartupSegue = NSStoryboardSegue.Identifier("startup")
}

