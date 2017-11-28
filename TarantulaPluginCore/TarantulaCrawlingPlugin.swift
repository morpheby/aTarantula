//
//  TarantulaCrawlingPlugin
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 8/18/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

public protocol TarantulaCrawlingPlugin: AnyObject {

    /// ManagedObjectModel for the plugin data
    var managedObjectModel: NSManagedObjectModel { get }

    var crawlableObjectTypes: [CrawlableManagedObject.Type] { get }
    var allObjectTypes: [NSManagedObject.Type] { get }

    var name: String { get }

    var baseUrl: URL { get }

    var repository: Repository? { get set }

    var networkManager: NetworkManager? { get set }

    func crawlObject(object: CrawlableObject) throws

    var settingsViewController: NSViewController? { get }
}

public struct CrawlError: Error {
    public init(url: URL, info: String) {
        self.url = url
        self.info = info
    }
    public var url: URL
    public var info: String
}

extension CrawlError: LocalizedError {
    public var errorDescription: String? {
        return "Couldn't crawl \(url.path): \(info)"
    }
}

public protocol TarantulaExportable {
    func export(for profile: ExportProfile) -> [Encodable]
}

public protocol TarantulaBatchCapable {
    func addInitialObject(by: String) throws
    func configureFilter(withClosure: @escaping (String) -> Bool)
}

