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

    public var crawlableObjectTypes: [CrawlableManagedObject.Type] {
        return [Test.self as CrawlableManagedObject.Type]
    }

    public var allObjectTypes: [NSManagedObject.Type] {
        return crawlableObjectTypes as [NSManagedObject.Type]
    }

    public func crawlObject(object: CrawlableObject) {
    }

    public let name = "TestPlugin"

    public var repository: Repository? = nil

    public var settingsViewController: NSViewController? = nil
}

