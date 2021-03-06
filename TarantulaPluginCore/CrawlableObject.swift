//
//  CrawlableObject.swift
//  Crawler
//
//  Created by Анастасия Василевская on 6/18/17.
//
//

import Foundation

/// The protocol that defines an object as capable of being crawled, and, thus, supporting
/// some mechanics of such object
@objc public protocol CrawlableObject {

    /// Object `id` for CoreData
    /// - Important: This property needs to be defined in the CoreData Model, not
    ///    as the computed or stored property of the object
    /// Default value: unspecified
    @objc var id: String? { get set }

    /// Object crawl URL for CoreData
    /// - Important: This property needs to be defined in the CoreData Model, not
    ///    as the computed or stored property of the object
    /// Default value: unspecified
    @objc var crawl_url: String? { get set }

    /// Object marker of presence for CoreData
    /// - Important: This property needs to be defined in the CoreData Model, not
    ///    as the computed or stored property of the object
    /// Default value: unspecified
    @objc var obj_deleted: Bool { get set }

    /// Object marker of filtering for CoreData
    /// - Important: This property needs to be defined in the CoreData Model, not
    ///    as the computed or stored property of the object
    /// Default value: `true`
    @objc var disabled: Bool { get set }
}

public protocol CrawlableObjectCustomId {
    static func id(fromUrl: URL) -> String
}

public extension CrawlableObject {
    var objectUrl: URL {
        get {
            return url(string: crawl_url!)!
        }
    }

    /// Is `true` when the object has been successfuly crawled and is present in the database
    /// in a manner more than just its URL (i.e. all the fields are set and all the relationships
    /// have been added do the database)
    var objectIsCrawled: Bool {
        get {
            return !self.obj_deleted
        }
        set {
            self.obj_deleted = !newValue
        }
    }

    /// Shows that the object has been marked as selected under current filtering criteria.
    /// If `false`, object is supposed to be *not* crawled, and so is not intented to be, and
    /// hence will be omitted in the request for all uncrawled objects.
    var objectIsSelected: Bool {
        get {
            return !self.disabled
        }
        set {
            self.disabled = !newValue
        }
    }
}

public func url(string: String) -> URL? {
    return URL(string: string)?.standardized
}

public func string(url: URL) -> String {
    return url.standardized.absoluteString
}

public typealias CrawlableManagedObject = NSManagedObject & CrawlableObject
