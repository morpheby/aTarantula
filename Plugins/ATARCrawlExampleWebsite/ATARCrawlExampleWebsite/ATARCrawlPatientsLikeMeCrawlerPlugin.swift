//
//  ATARCrawlExampleWebsiteCrawlerPlugin.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/10/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore
import Kanna

@objc(ATARCrawlExampleWebsiteCrawlerPlugin) public class ATARCrawlExampleWebsiteCrawlerPlugin: NSObject, TarantulaCrawlingPlugin {

    public override init() {
        super.init()
    }


    /// ManagedObjectModel for the plugin data
    public var managedObjectModel: NSManagedObjectModel {
        return NSManagedObjectModel(contentsOf: Bundle(for: ATARCrawlExampleWebsiteCrawlerPlugin.self)
            .url(forResource: "ATARCrawlExampleWebsiteCrawlerPlugin", withExtension: "momd")!)!
    }

    public var crawlableObjectTypes: [CrawlableManagedObject.Type] {
        return []
    }

    public var allObjectTypes: [NSManagedObject.Type] {
        return crawlableObjectTypes as [NSManagedObject.Type] + []
    }

    public func crawlObject(object: CrawlableObject) {
    }

    public let name = "ATARCrawlExampleWebsiteCrawlerPlugin"

    public var repository: Repository? = nil

    let storyboard = NSStoryboard(name: "Settings", bundle: Bundle(for: ATARCrawlExampleWebsiteCrawlerPlugin.self))

    public lazy var settingsViewController: NSViewController? = {
        guard let rootObject = self.storyboard.instantiateInitialController() else {
            fatalError("Invalid root object")
        }
        guard let viewController = rootObject as? SettingsViewController else {
            fatalError("Storyboard provides wrong controller: should be SettingsViewController or subclass, given \(type(of:rootObject)): \(rootObject)")
        }
        viewController.plugin = self
        return viewController
    }()
}
