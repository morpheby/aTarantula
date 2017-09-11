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
        return type.init(context: self.context)
    }

    func newObject<T: NSManagedObject>(forUrl url: URL, type: T.Type) -> T where T: CrawlableObject {
        let o = self.newObject(type: type)
        o.id = cleanedStringForUrl(url)
        return o
    }


    func readAllObjects<T: NSManagedObject>(_ type: T.Type) -> [T] {
        let request: NSFetchRequest = type.fetchRequest()
        return (try? self.context.fetch(request).flatMap { x in x as? T }) ?? []
    }

    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withPredicate predicate: NSPredicate) -> [T] {
        let request: NSFetchRequest = type.fetchRequest()
        request.predicate = predicate
        return (try? self.context.fetch(request).flatMap { x in x as? T }) ?? []
    }

    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withSelection selection: RepositoryCrawlableSelection) -> [T] {
        assert(type is CrawlableObject.Type, "Type has to be CrawlableObject")
        let request: NSFetchRequest = type.fetchRequest()
        switch (selection) {
        case let .object(url):
            request.predicate = NSPredicate(format: "\(#keyPath(CrawlableObject.id)) == %@", argumentArray: [url])
        case .crawledObjects:
            request.predicate = NSPredicate(
                format: "\(#keyPath(CrawlableObject.obj_deleted)) == %@ && \(#keyPath(CrawlableObject.disabled)) == %@",
                argumentArray: [false, false])
        case .objectsToCrawl:
            request.predicate = NSPredicate(
                format: "\(#keyPath(CrawlableObject.obj_deleted)) == %@ && \(#keyPath(CrawlableObject.disabled)) == %@",
                argumentArray: [true, false])
        case .filteredObjects:
            request.predicate = NSPredicate(
                format: "\(#keyPath(CrawlableObject.disabled)) == %@",
                argumentArray: [true])
        case .all:
            break
        }
        return (try? self.context.fetch(request).flatMap { x in x as? T }) ?? []
    }
}

func cleanedStringForUrl(_ url: URL) -> String {
    return url.standardized.absoluteString
}
