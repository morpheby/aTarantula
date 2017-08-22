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
    func perform(closure: @escaping () -> ())

    /// Performs given operations on the repository. The save is performed after the operation.
    /// - Important: Always use either of the perform methods for any operations, including changes in
    ///   the objects themselves
    func performAndWait(closure: @escaping () -> ())

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

    /// Fetches all objects of the type T (given through the parameter `type`) from the repository by using
    /// the predicate `predicate`
    /// - Parameters:
    ///    - type: The type of the objects requested
    ///    - predicate: The predicate used to find objects in the repository
    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withPredicate predicate: RepositoryPredicate) -> [T]
}

public enum RepositoryPredicate {
    case CrawlableObject(url: URL)
    case CrawlableObjects(alreadyCrawled: Bool)
    case All
}

func cleanedStringForUrl(_ url: URL) -> String {
    return url.standardized.absoluteString
}

