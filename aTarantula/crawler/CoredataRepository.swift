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

    func newObject<T: NSManagedObject>(type: T.Type) -> T {
        return T(context: self.context)
    }

    func newObject<T: NSManagedObject>(forUrl url: URL, type: T.Type) -> T where T: CrawlableObject {
        let o = self.newObject(type:T.self)
        o.setValue(url, forKey: "\(#selector(getter: CrawlableObject.id))")
        return o
    }

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

