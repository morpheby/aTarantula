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

    func makeFetchRequest(type: NSManagedObject.Type, withSelection selection: RepositoryCrawlableSelection) -> NSFetchRequest<NSFetchRequestResult> {
        let request: NSFetchRequest = type.fetchRequest()
        switch (selection) {
        case let .object(url):
            let cleanedUrlString = customId(fromUrl: url, forType: type)
            request.predicate = NSPredicate(format: "\(#keyPath(CrawlableObject.id)) == %@", argumentArray: [cleanedUrlString])
        case .crawledObjects:
            request.predicate = NSPredicate(
                format: "\(#keyPath(CrawlableObject.obj_deleted)) == %@ && \(#keyPath(CrawlableObject.disabled)) == %@",
                argumentArray: [false, false])
        case .objectsToCrawl:
            request.predicate = NSPredicate(
                format: "\(#keyPath(CrawlableObject.obj_deleted)) == %@ && \(#keyPath(CrawlableObject.disabled)) == %@",
                argumentArray: [true, false])
        case .unselectedObjects:
            request.predicate = NSPredicate(
                format: "\(#keyPath(CrawlableObject.disabled)) == %@",
                argumentArray: [true])
        case .all:
            break
        }
        return request
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

    func batch<U>(_ closure: @escaping (Repository) throws -> U) rethrows -> U {
        return try closure(ShadowRepository(main: self))
    }

    func delete<T: NSManagedObject>(object: T) {
        context.delete(object)
    }

    func customId<T: NSManagedObject>(fromUrl url: URL, forType type: T.Type) -> String {
        if let t = type as? CrawlableObjectCustomId.Type {
            return t.id(fromUrl: url)
        } else {
            return string(url: url)
        }
    }

    func newObject<T: NSManagedObject>(type: T.Type) -> T {
        return type.init(context: self.context)
    }

    func newObject<T: NSManagedObject>(forUrl url: URL, type: T.Type) -> T where T: CrawlableObject {
        let o = self.newObject(type: type)
        o.id = customId(fromUrl: url, forType: type)
        o.crawl_url = string(url: url)
        o.obj_deleted = true
        o.disabled = false
        return o
    }

    func readAllObjects<T: NSManagedObject>(_ type: T.Type) -> [T] {
        let request: NSFetchRequest = type.fetchRequest()
        return (try? self.context.fetch(request).flatMap { x in x as? T }) ?? []
    }

    func countAllObjects<T: NSManagedObject>(_ type: T.Type) -> Int {
        let request: NSFetchRequest = type.fetchRequest()
        return (try? self.context.count(for: request)) ?? 0
    }

    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withPredicate predicate: NSPredicate) -> [T] {
        let request: NSFetchRequest = type.fetchRequest()
        request.predicate = predicate
        return (try? self.context.fetch(request).flatMap { x in x as? T }) ?? []
    }

    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withSelection selection: RepositoryCrawlableSelection, max: Int) -> [T] {
        assert(type is CrawlableObject.Type, "Type has to be CrawlableObject")
        let request = makeFetchRequest(type: type, withSelection: selection)
        if max != 0 {
            if max < 0 { debugPrint("Warning: max fetch is negative") }
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

fileprivate class ShadowRepository: Repository {
    var main: CoredataRepository
    init(main: CoredataRepository) {
        self.main = main
    }

    deinit {
        self.main.context.performAndWait {
            self.main.save()
        }
    }

    func perform(_ closure: @escaping () -> ()) {
        self.main.context.perform {
            closure()
        }
    }

    func performAndWait<U>(_ closure: @escaping () -> U) -> U {
        var result: U! = nil
        self.main.context.performAndWait {
            result = closure()
        }
        return result
    }

    func batch<U>(_ closure: @escaping (Repository) throws -> U) rethrows -> U {
        return try closure(self)
    }

    func delete<T: NSManagedObject>(object: T) {
        main.delete(object: object)
    }

    func customId<T: NSManagedObject>(fromUrl url: URL, forType type: T.Type) -> String {
        return main.customId(fromUrl: url, forType: type)
    }

    func newObject<T: NSManagedObject>(type: T.Type) -> T {
        return main.newObject(type: type)
    }

    func newObject<T: NSManagedObject>(forUrl url: URL, type: T.Type) -> T where T: CrawlableObject {
       return main.newObject(forUrl: url, type: type)
    }

    func readAllObjects<T: NSManagedObject>(_ type: T.Type) -> [T] {
        return main.readAllObjects(type)
    }

    func countAllObjects<T: NSManagedObject>(_ type: T.Type) -> Int {
        return main.countAllObjects(type)
    }

    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withPredicate predicate: NSPredicate) -> [T] {
        return main.readAllObjects(type, withPredicate: predicate)
    }

    func readAllObjects<T: NSManagedObject>(_ type: T.Type, withSelection selection: RepositoryCrawlableSelection, max: Int) -> [T] {
        return main.readAllObjects(type, withSelection: selection, max: max)
    }

    func countAllObjects<T: NSManagedObject>(_ type: T.Type, withSelection selection: RepositoryCrawlableSelection) -> Int {
        return main.countAllObjects(type, withSelection: selection)
    }
}

