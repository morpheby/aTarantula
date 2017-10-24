//
//  Treatment+CoreDataClass.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/11/17.
//  Copyright © 2017 morpheby. All rights reserved.
//
//

import Foundation
import CoreData
import TarantulaPluginCore

@objc
public class Treatment: Crawlable {

}

extension Treatment: CrawlableObjectCustomId {
    public static func id(fromUrl url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            fatalError("Malformed URL for Treatment — Can't convert")
        }
        components.query = nil
        let tokens = components.path.split(separator: "/")
        guard let last = tokens.last else {
            fatalError("Malformed URL for Treatment — No path")
        }
        if let idRange = last.index(where: { (c: Character) -> Bool in
            CharacterSet.decimalDigits.isDisjoint(with: CharacterSet(charactersIn: String(c)))
        }) {
            // Clean everything past numerical ID
            guard let removalIndex = idRange.samePosition(in: components.path) else {
                fatalError("Malformed URL for Treatment — ID not present at start")
            }
            components.path.removeSubrange(removalIndex...)
        }

        guard let result = components.url?.standardized.absoluteString else {
            fatalError("Malformed URL for Treatment — unable to rebuild URL")
        }
        
        return result
    }
}
