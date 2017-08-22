//
//  CoredataRepository.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 8/21/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

class CoredataRepository {
    var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Saves the changes made to the repository
    func save() {
        do {
            try self.context.save()
        }
        catch let e {
            fatalError("Error committing: \(e) ")
        }
    }
}

extension CoredataRepository: Repository {

    func perform(closure: @escaping () -> ()) {
        self.context.perform {
            closure()
            self.save()
        }
    }

    func performAndWait(closure: @escaping () -> ()) {
        self.context.performAndWait {
            closure()
            self.save()
        }
    }

    func delete<T: NSManagedObject>(object: T) {
        context.delete(object)
    }

    /// Creates a new object of type `type` in the repository and returns it
    /// - Parameter type: The type of the object to be created
    func newObject<T: NSManagedObject>(type: T.Type) -> T {
        return T(context: self.context)
    }

    /// Creates a new CrawlableObject of specific type `type` with URL `url`.
    ///
    /// The difference from the `newObject<T: NSManagedObject>(type: T.Type) -> T` method is that
    /// this one presets the URL (which is considered read-only otherwise)
    func newObject<T: NSManagedObject>(forUrl url: URL, type: T.Type) -> T where T: CrawlableObject {
        let o = self.newObject(type:T.self)
        o.setValue(url, forKey: "\(#selector(getter: CrawlableObject.id))")
        return o
    }

    /// Fetches all objects of the type T (given through the parameter `type`) from the repository by using
    /// the predicate `predicate`
    /// - Parameters:
    ///    - type: The type of the objects requested
    ///    - predicate: The predicate used to find objects in the repository
    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withPredicate predicate: RepositoryPredicate) -> [T] {
        let request: NSFetchRequest = T.fetchRequest()
        switch (predicate) {
        case let .CrawlableObject(url):
            request.predicate = NSPredicate(format: "\(#selector(getter: CrawlableObject.id)) == %@", argumentArray: [url])
        case let .CrawlableObjects(alreadyCrawled):
            request.predicate = NSPredicate(format: "obj_deleted == %@", argumentArray: [!alreadyCrawled])
        case .All:
            break
        }
        return (try? self.context.fetch(request).flatMap { x in x as? T }) ?? []
    }
}

