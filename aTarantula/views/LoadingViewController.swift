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

    override func viewDidLoad() {
        super.viewDidLoad()

        for constraint in logViewConstraints {
            constraint.isActive = triggerState
        }

        beginStartup()
    }

    func beginStartup() {
        let appController = NSApplication.shared.controller

        appController.pluginLoader.pluginLoadingObservable ∆= self >> { (self: LoadingViewController, pc: PluginLoader) in
            let state = pc.state
            OperationQueue.main.addOperation {
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
                    self.status = "Done"
                    self.log.append(self.status)
                }
            }
        }

        appController.loadPluginsInBackground {
            self.performSegue(withIdentifier: .StartupSegue, sender: self)
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
}

extension LoadingViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        rowHeights[row] = Float((rowView.view(atColumn: 0) as! NSView).fittingSize.height)
        tableView.noteHeightOfRows(withIndexesChanged: [row])
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//        if let rowView = tableView.rowView(atRow: row, makeIfNecessary: false) {
//            debugPrint("Updating")
//            return rowView.fittingSize.height
//        } else {
//            debugPrint("No row yet")
//            return tableView.rowHeight
//        }
        return CGFloat(rowHeights[row] ?? Float(tableView.rowHeight))
    }
}

extension NSStoryboardSegue.Identifier {
    static let StartupSegue = NSStoryboardSegue.Identifier("startup")
}

