//
//  FilterSupport.swift
//  TarantulaPluginCore
//
//  Created by Ilya Mikhaltsou on 9/19/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

public extension CrawlableObject {

    private func filter(filter: Bool, newObjects: [CrawlableObject]) {
        // We assume all newObjects are singly-referenced at this moment in time
        // (we also expect this method to be run synchronously in the repository, so
        // we don't need to consider that this can change while we perform this method).

        // In a scenario where an uncrawled object U is created in the context of object A,
        // then referenced from object B:
        // - if object B has finished crawling earlier, it will set the filter on object U (initially
        //    it was supposed to be true), and object A will then AND the result
        // - if object A is first, the same will happen in regard to object B
        //

        self.objectIsFiltered = filter

        for object in newObjects {
            guard !object.objectIsCrawled else {
                // If the object has already been crawled, then it needs a separate call to its
                // own filter, we are not doing this.
                continue
            }
            object.objectIsFiltered = object.objectIsFiltered && filter
        }
    }

    public func filter(newObjects: [CrawlableObject]) {
        filter(filter: true, newObjects: newObjects)
    }

    public func unfilter(newObjects: [CrawlableObject]) {
        filter(filter: false, newObjects: newObjects)
    }
    
}
