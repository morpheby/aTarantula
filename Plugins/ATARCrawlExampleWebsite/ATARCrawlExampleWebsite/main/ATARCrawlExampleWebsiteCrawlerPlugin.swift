//
//  ATARCrawlExampleWebsiteCrawlerPlugin.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/10/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

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
        return [
            Treatment.self, TreatmentPurposes.self, DrugCategory.self, DrugPatients.self, DrugSideEffects.self,
            DrugSwitches.self,
        ]
    }

    public var allObjectTypes: [NSManagedObject.Type] {
        return crawlableObjectTypes as [NSManagedObject.Type] + [
            DrugAdherence.self, DrugBurden.self, DrugCost.self, DrugDosageCount.self, DrugDuration.self,
            DrugSideEffectSeverity.self, DrugStopReason.self, DrugSwitch.self,
        ]
    }

    public func crawlObject(object: CrawlableObject) throws  {
        guard let repository = repository else {
            fatalError("Repository uninitialized")
        }
        try crawl(object: object, usingRepository: repository, withPlugin: self)
    }

    let baseUrl: URL = URL(string: "https://examplewebsite")!

    public let name = "ATARCrawlExampleWebsiteCrawlerPlugin"

    public var repository: Repository? = nil

    public var networkManager: NetworkManager? = nil

    let storyboard = NSStoryboard(name: .settings, bundle: Bundle(for: ATARCrawlExampleWebsiteCrawlerPlugin.self))

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

    var filterMethod: FilterMethod = .none
}
