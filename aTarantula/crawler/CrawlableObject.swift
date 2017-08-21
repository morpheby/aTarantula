//
//  CrawlableObject.swift
//  Crawler
//
//  Created by Анастасия Василевская on 6/18/17.
//
//

import Foundation

protocol CrawlableObject {
    var objectUrl: URL { get }
    var objectIsCrawled: Bool { get set }
}
