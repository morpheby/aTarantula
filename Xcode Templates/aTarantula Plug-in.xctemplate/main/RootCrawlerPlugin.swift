//___FILEHEADER___

import Foundation
import TarantulaPluginCore

@objc(___PACKAGENAMEASIDENTIFIER___CrawlerPlugin) public class ___PACKAGENAMEASIDENTIFIER___CrawlerPlugin: NSObject, TarantulaCrawlingPlugin {

    public override init() {
        super.init()
    }


    /// ManagedObjectModel for the plugin data
    public var managedObjectModel: NSManagedObjectModel {
        return NSManagedObjectModel(contentsOf: Bundle(for: ___PACKAGENAMEASIDENTIFIER___CrawlerPlugin.self)
            .url(forResource: Configuration.pluginName, withExtension: "momd")!)!
    }

    public var crawlableObjectTypes: [CrawlableManagedObject.Type] {
        return [
            // TODO: Put here all crawlable types
        ]
    }

    public var allObjectTypes: [NSManagedObject.Type] {
        return crawlableObjectTypes as [NSManagedObject.Type] + [
            // TODO: Put here all other types
        ]
    }

    public func crawlObject(object: CrawlableObject) throws  {
        guard let repository = repository else {
            fatalError("Repository uninitialized")
        }
        try crawl(object: object, usingRepository: repository, withPlugin: self)
    }

    public let baseUrl: URL = URL(string: Configuration.websiteBaseUrl)!

    public let name = Configuration.pluginName

    public var repository: Repository? = nil

    public var networkManager: NetworkManager? = nil

    let storyboard = NSStoryboard(name: .settings, bundle: Bundle(for: ___PACKAGENAMEASIDENTIFIER___CrawlerPlugin.self))

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
