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
            crawler.running = false
        default:
            break
        }
    }

    override func dismissViewController(_ viewController: NSViewController) {
        super.dismissViewController(viewController)
        for (_, store) in NSApplication.shared.controller.dataLoader.stores {
            try? store.persistentContainer.viewContext.save()
            store.repository.perform { }
            crawler.resetLists()
            crawler.updateCrawllist()
        }
    }

    @IBAction func batch(_ sender: Any?) {
        // FIXME: Needs separate dialogue with batch configuration

        let openPanel = NSOpenPanel()
        openPanel.message = "Select file for batch data"
        openPanel.nameFieldLabel = "Batch file:"
        openPanel.nameFieldStringValue = "Batch job"
        openPanel.allowedFileTypes = nil
        openPanel.allowsOtherFileTypes = true

        openPanel.beginSheetModal(for: view.window!, completionHandler: { response in
            switch (response) {
            case .OK:
                self.prepareForBatch(with: openPanel.url!)
            default:
                break
            }
        })
    }

    // FIXME: Needs separate location
    func prepareForBatch(with fileUrl: URL) {
        do {
            let fileData = try String(contentsOf: fileUrl)
            let values = Set(fileData.lazy.split(separator: "\n").map(String.init))
            let batchPlugins = NSApplication.shared.controller.crawlers.flatMap { p in p as? TarantulaBatchCapable&TarantulaCrawlingPlugin }

            for plugin in batchPlugins {
                try plugin.repository?.batch { shadow in
                    for value in values {
                        try plugin.addInitialObject(by: value, shadowRepository: shadow)
                    }
                }
            }
            for plugin in batchPlugins {
                plugin.configureFilter(withClosure: { (s) -> Bool in
                    values.contains(s)
                })
            }

            for (_, store) in NSApplication.shared.controller.dataLoader.stores {
                // wait
                store.repository.perform { }
                crawler.resetLists()
                crawler.updateCrawllist()
            }
        }
        catch let e {
            self.presentError(e)
        }
    }

    @IBAction func exporting(_ sender: Any?) {
        // FIXME: Needs separate dialogue with export configuration

        let savePanel = NSSavePanel()
        savePanel.message = "Select export location"
        savePanel.nameFieldLabel = "Export file:"
        savePanel.nameFieldStringValue = "Export" // FIXME: STUB
        savePanel.allowedFileTypes = ["json"]
        savePanel.allowsOtherFileTypes = false

        savePanel.beginSheetModal(for: view.window!, completionHandler: { response in
            switch (response) {
            case .OK:
                self.exportData(url: savePanel.url!)
            default:
                break
            }
        })
    }

    // TEMP EXPORT IMPLEMENTATION BEGIN
    struct Container: Encodable {
        var value: Encodable
        func encode(to encoder: Encoder) throws {
            try value.encode(to: encoder)
        }
    }

    func exportData(url: URL) {
        // Temporary function implementation for exporting

        let tempId = ExportProfile("tempIdStub")
        let exporters = NSApplication.shared.controller.crawlers.flatMap { p in p as? TarantulaExportable }

        let data = exporters.flatMap { e in e.export(for: tempId) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        do {
            let preOutput = data.map { d in Container(value: d) }
            let output = try encoder.encode(preOutput)

            try output.write(to: url)
        }
        catch let e {
            self.presentError(e)
        }
    }
    // TEMP EXPORT IMPLEMENTATION END

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
