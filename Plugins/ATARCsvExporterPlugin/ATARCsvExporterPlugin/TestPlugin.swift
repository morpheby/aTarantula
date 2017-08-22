//
//  TestPlugin.swift
//  ATARCsvExporterPlugin
//
//  Created by Ilya Mikhaltsou on 8/20/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore
import Kanna

@objc(TestPlugin) public class TestPlugin: NSObject, TarantulaCrawlingPlugin {
    public override init() {
        super.init()
    }


    /// ManagedObjectModel for the plugin data
    public var managedObjectModel: NSManagedObjectModel {
        return NSManagedObjectModel(contentsOf: Bundle(for: TestPlugin.self)
            .url(forResource: "Model", withExtension: "momd")!)!
    }

    public var crawlableObjectTypes: [CrawlableObject.Type] {
        return [Test.self as CrawlableObject.Type]
    }

    public var allObjectTypes: [NSManagedObject.Type] {
        let data = try! String(contentsOf: URL(string: "https://google.com")!)

        guard let html = Kanna.HTML(html: data, encoding: .utf8) else {
            fatalError("Unable to parse HTML")
        }
        return crawlableObjectTypes as! [NSManagedObject.Type]
    }

    public func crawlObject(object: CrawlableObject, inRepository repository: Repository) -> [CrawlableObject] {
        return []
    }
}

