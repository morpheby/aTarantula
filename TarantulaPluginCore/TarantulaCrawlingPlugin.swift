//
//  TarantulaCrawlingPlugin
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 8/18/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

public protocol TarantulaCrawlingPlugin {

    /// ManagedObjectModel for the plugin data
    var managedObjectModel: NSManagedObjectModel { get }

    var crawlableTypes: [CrawlableObject.Type] { get }

    func crawlObject(object: CrawlableObject, inRepository repository: Repository) -> [CrawlableObject]
}
