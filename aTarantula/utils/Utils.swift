//
//  Utils.swift
//  CrossroadRegex
//
//  Created by Ilya Mikhaltsou on 6/16/17.
//
//

import Foundation

public protocol WeakType {
    associatedtype Element: AnyObject
    var value: Element? {get set}
    init(_ value: Element)
}

public class Weak<T: AnyObject>: WeakType {
    public typealias Element = T
    weak public var value : Element?
    required public init (_ value: Element) {
        self.value = value
    }
}

public extension Array where Element: WeakType {
    public init(_ arr: Array<Element.Element>) {
        self.init(arr.map { (x: Element.Element) -> Element in
            Element(x)
        })
    }

    public mutating func reap() {
        self = self.filter { x in x.value != nil }
    }
}

public extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    public subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public func synchronized<T>(_ lockObj: AnyObject!, do closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lockObj)
    defer {
        objc_sync_exit(lockObj)
    }
    return try closure()
}

public struct IOError: Error {
    public let path: String
}

public class FileTextOutputStream: TextOutputStream {
    var file: FileHandle

    public init(fileAtPath: String, append: Bool) throws {
        if !FileManager.default.fileExists(atPath: fileAtPath) {
            FileManager.default.createFile(atPath: fileAtPath, contents: nil, attributes: nil)
        }
        if let s = FileHandle(forWritingAtPath: fileAtPath) {
            if append {
                s.seekToEndOfFile()
            }
            s.truncateFile(atOffset: s.offsetInFile)
            file = s
        } else {
            throw IOError(path: fileAtPath)
        }
    }

    deinit {
        file.closeFile()
    }

    public func write(_ s: String) {
        let data = s.data(using: .utf8)!
        file.write(data)
    }
}

public extension Dictionary {

}

@inline(__always)
public func logDebug(file: String = #file, line: Int = #line, function: String = #function, _ log: @autoclosure () -> Any) {
    #if DEBUG
    debugPrint("\(Date().description) \(file):\(line):\(function)", log())
    #endif
}
