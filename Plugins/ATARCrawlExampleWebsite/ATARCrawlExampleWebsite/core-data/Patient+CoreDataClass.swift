//
//  Patient+CoreDataClass.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/26/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import CoreData

@objc
public class Patient: Crawlable {

    var age: Int64? {
        get {
            return value(forKey: "age_") as? Int64
        }
        set {
            setValue(newValue as AnyObject?, forKey: "age_")
        }
    }

}
