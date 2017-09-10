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
        return [Test.self as CrawlableManagedObject.Type]
    }

    public var allObjectTypes: [NSManagedObject.Type] {
        return crawlableObjectTypes as [NSManagedObject.Type] + []
    }

    public func crawlObject(object: CrawlableObject, inRepository repository: Repository) -> [CrawlableObject] {
        return []
    }

    public let name = "ATARCrawlExampleWebsiteCrawlerPlugin"

    public var repository: Repository? = nil
}
