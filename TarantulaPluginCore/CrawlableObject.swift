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
    @objc var id: String? { get set }

    /// Object marker of presence for CoreData
    /// - Important: This property needs to be defined in the CoreData Model, not
    ///    as the computed or stored property of the object
    @objc var obj_deleted: Bool { get set }

    /// Object marker of filtering for CoreData
    /// - Important: This property needs to be defined in the CoreData Model, not
    ///    as the computed or stored property of the object
    @objc var disabled: Bool { get set }
}

public extension CrawlableObject {
    var objectUrl: URL {
        get {
            return URL(string: self.id!)!.standardized
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

    /// Shows that the object has been marked as *not satisfying filtering criteria*.
    /// Such object is supposed to be *not* crawled, and so is not intented to be, and
    /// hence will be omitted in the request for all uncrawled objects.
    var objectIsFiltered: Bool {
        get {
            return self.disabled
        }
        set {
            self.disabled = newValue
        }
    }
}

public typealias CrawlableManagedObject = NSManagedObject & CrawlableObject
