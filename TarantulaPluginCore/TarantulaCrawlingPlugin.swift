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

    var repository: Repository? { get set }

    func crawlObject(object: CrawlableObject) throws

    var settingsViewController: NSViewController? { get }
}
