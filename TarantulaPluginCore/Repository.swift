//
//  Repository.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 8/21/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

public protocol Repository {

    /// Performs given operations on the repository asynchronously. The save is performed after the operation.
    /// - Important: Always use either of the perform methods for any operations, including changes in
    ///   the objects themselves
    func perform(_ closure: @escaping () -> ())

    /// Performs given operations on the repository. The save is performed after the operation.
    /// - Important: Always use either of the perform methods for any operations, including changes in
    ///   the objects themselves
    func performAndWait<U>(_ closure: @escaping () -> U) -> U

    /// Removes given object from the repository
    func delete<T: NSManagedObject>(object: T)

    /// Creates a new object of type `type` in the repository and returns it
    /// - Parameter type: The type of the object to be created
    func newObject<T: NSManagedObject>(type: T.Type) -> T

    /// Creates a new CrawlableObject of specific type `type` with URL `url`.
    /// 
    /// The difference from the `newObject<T: NSManagedObject>(type: T.Type) -> T` method is that
    /// this one presets the URL (which is considered read-only otherwise)
    func newObject<T: NSManagedObject>(forUrl url: URL, type: T.Type) -> T where T: CrawlableObject

    /// Fetches all objects of the type T (given through the parameter `type`) from the repository
    /// - Parameters:
    ///    - type: The type of the objects requested
    func readAllObjects<T: NSManagedObject>(_ type: T.Type) -> [T]

//    /// Fetches all objects of the type T (given through the parameter `type`) from the repository by using
//    /// the predicate `predicate`
//    /// - Parameters:
//    ///    - type: The type of the objects requested
//    ///    - predicate: The predicate used to find objects in the repository
//    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withPredicate predicate: NSPredicate) -> [T]

    /// Fetches all objects of the type T (given through the parameter `type`) from the repository by using
    /// the selection `selection`
    /// - Parameters:
    ///    - type: The type of the objects requested
    ///    - selection: The selection used to find objects in the repository
    ///    - max: maximum number of objects to fetch (0 equals all)
    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withSelection selection: RepositoryCrawlableSelection, max: Int) -> [T]

    /// Returns count of all objects of the type T (given through the parameter `type`) from the repository by using
    /// the selection `selection` (count of objects to be returned by readAllObjects)
    /// - Parameters:
    ///    - type: The type of the objects requested
    ///    - selection: The selection used to find objects in the repository
    func countAllObjects<T: NSManagedObject>(_ type: T.Type, withSelection selection: RepositoryCrawlableSelection) -> Int
}

public extension Repository {

    /// Fetches all objects of the type T (given through the parameter `type`) from the repository by using
    /// the selection `selection`
    /// - Parameters:
    ///    - type: The type of the objects requested
    ///    - selection: The selection used to find objects in the repository
    func readAllObjects<T>(_ type: T.Type, withSelection selection: RepositoryCrawlableSelection) -> [T] where T : NSManagedObject {
        return readAllObjects(type, withSelection: selection, max: 0)
    }
}

public enum RepositoryCrawlableSelection {
    case object(url: URL)
    case crawledObjects
    case objectsToCrawl
    case filteredObjects
    case all
}


