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

    @objc dynamic var crawler: Crawler = Crawler()
    @IBOutlet var objectController: NSObjectController!
    @IBOutlet var secondProgressIndicator: NSProgressIndicator!
    @IBOutlet var tableLogView: NSTableView!

    @objc dynamic var pluginNames: [String]  {
        return NSApplication.shared.controller.pluginLoader.crawlers.map { plugin in plugin.name }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        crawler.logChangeObservable ∆= self >> { s, c in
            s.tableLogView.noteHeightOfRows(withIndexesChanged: [c.log.count-1])
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        if let layer = secondProgressIndicator.layer {
            layer.anchorPoint = CGPoint(x: 1, y: 0)
            layer.transform = CATransform3DMakeScale(-1.0, 1.0, 1.0)
        }
    }

    @IBAction func start(_ sender: Any?) {
        crawler.running = true
    }

    @IBAction func stop(_ sender: Any?) {
        crawler.running = false
    }

    @IBAction func clearLog(_ sender: Any?) {
        crawler.log = []
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
            crawler.updateCrawllist()
        }
    }

    var autoscrollLastRow = 0

    func autoscrollToBottom() {
        if crawler.log.count >= 4,
        let docRect = tableLogView.enclosingScrollView?.documentVisibleRect,
        docRect.maxY >= tableLogView.rect(ofRow: autoscrollLastRow).minY - 20.0 {
            autoscrollLastRow = crawler.log.count - 1
            tableLogView.scrollRowToVisible(crawler.log.count - 1)
        }
    }

    var rowHeights: [Int: Float] = [:]
}

extension ViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        rowHeights[row] = Float((rowView.view(atColumn: 0) as! NSView).fittingSize.height)
        tableView.noteHeightOfRows(withIndexesChanged: [row])
        autoscrollToBottom()
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(rowHeights[row] ?? Float(tableView.rowHeight))
    }
}
