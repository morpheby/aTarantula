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

    func perform(_ closure: @escaping () -> ()) {
        self.context.perform {
            closure()
            self.save()
        }
    }

    func performAndWait<U>(_ closure: @escaping () -> U) -> U {
        var result: U! = nil
        self.context.performAndWait {
            result = closure()
            self.save()
        }
        return result
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
        o.obj_deleted = true
        o.disabled = false
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

    func makeFetchRequest(type: NSManagedObject.Type, withSelection selection: RepositoryCrawlableSelection) -> NSFetchRequest<NSFetchRequestResult> {
        let request: NSFetchRequest = type.fetchRequest()
        switch (selection) {
        case let .object(url):
            request.predicate = NSPredicate(format: "\(#keyPath(CrawlableObject.id)) == %@", argumentArray: [cleanedStringForUrl(url)])
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
        return request
    }

    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withSelection selection: RepositoryCrawlableSelection, max: Int) -> [T] {
        assert(type is CrawlableObject.Type, "Type has to be CrawlableObject")
        let request = makeFetchRequest(type: type, withSelection: selection)
        if max != 0 {
            request.fetchLimit = max
        }
        return (try? self.context.fetch(request).flatMap { x in x as? T }) ?? []
    }

    func countAllObjects<T: NSManagedObject>(_ type: T.Type, withSelection selection: RepositoryCrawlableSelection) -> Int {
        assert(type is CrawlableObject.Type, "Type has to be CrawlableObject")
        let request = makeFetchRequest(type: type, withSelection: selection)
        return (try? self.context.count(for: request)) ?? 0
    }
}

