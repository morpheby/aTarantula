//
//  SynchronizedBox.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/11/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

fileprivate class ActualBox<T> {
    var boxed: T

    init(_ value: T) {
        boxed = value
    }

    func exec(_ e: (inout T) -> ()) {

    }
}

public protocol GenericSynchronizedBox {
    associatedtype Box

    var unsafeBoxed: Box { get set }

    func lock()
    func tryLock() -> Bool
    func unlock()

    func read<U>(_ closure: (Box) throws -> U) rethrows -> U
    mutating func modify<U>(_ closure: (inout Box) throws -> U) rethrows -> U
}

public extension GenericSynchronizedBox {

    public func read<U>(_ closure: (Box) throws -> U) rethrows -> U {
        lock()
        defer {
            unlock()
        }
        let result = try closure(unsafeBoxed)
        return result
    }

    public mutating func modify<U>(_ closure: (inout Box) throws -> U) rethrows -> U {
        lock()
        defer {
            unlock()
        }
        let result = try closure(&unsafeBoxed)
        return result
    }
}

public struct SynchronizedBox<T>: GenericSynchronizedBox {
    public typealias Box = T

    private var actualBox: ActualBox<Box>
    public var unsafeBoxed: Box {
        get {
            return actualBox.boxed
        }
        set {
            actualBox.boxed = newValue
        }
    }
    private let synchroLock = NSRecursiveLock()

    public init(_ object: Box) {
        actualBox = ActualBox(object)
    }

    public func lock() {
        synchroLock.lock()
    }

    public func tryLock() -> Bool {
        return synchroLock.try()
    }

    public func unlock() {
        synchroLock.unlock()
    }

    public func map<U>(_ transform: (Box) throws -> U) rethrows -> SynchronizedBox<U> {
        // XXX unimplemented
        fatalError("Uimplemented")
        let newValue = try transform(unsafeBoxed)
        return SynchronizedBox<U>(newValue)
    }

    public func flatMap<U>(_ transform: (Box) throws -> SynchronizedBox<U>) rethrows -> SynchronizedBox<U> {
        // XXX unimplemented
        fatalError("Uimplemented")
        return try transform(unsafeBoxed)
    }
}

// Until we have inout stored variables, this will not work, and this will *probably* not happen till Swift 6 (at least)

//public struct ZipBox2<Box1, Box2>: GenericSynchronizedBox where Box1: GenericSynchronizedBox, Box2: GenericSynchronizedBox {
//    public typealias Box = (Box1.Box, Box2.Box)
//
//    private var box1: Box1
//    private var box2: Box2
//
//    public init(_ box1: Box1, _ box2: Box2) {
//        self.box1 = box1
//        self.box2 = box2
//    }
//
//    public var unsafeBoxed: (Box1.Box, Box2.Box) {
//        get {
//            return (box1.unsafeBoxed, box2.unsafeBoxed)
//        }
//        set {
//            (box1.unsafeBoxed, box2.unsafeBoxed) = newValue
//        }
//    }
//
//    public func lock() {
//        while true {
//            box1.lock()
//            if box2.tryLock() { break }
//            box1.unlock()
//
//            box2.lock()
//            if box1.tryLock() { break }
//            box2.unlock()
//        }
//    }
//
//    public func tryLock() -> Bool {
//        if !box1.tryLock() { return false }
//        if !box2.tryLock() { box1.unlock() ; return false }
//        return true
//    }
//
//    public func unlock() {
//        box1.unlock()
//        box2.unlock()
//    }
//}
//
//public func zip<Box1, Box2>(_ box1: Box1, _ box2: Box2) -> ZipBox2<Box1, Box2> where Box1 : GenericSynchronizedBox, Box2 : GenericSynchronizedBox {
//    return ZipBox2(box1, box2)
//}

// Instead, we will have this for now

public func zipModify<Box1, Box2, U>(_ box1: inout Box1, _ box2: inout Box2, _ closure: (inout Box1.Box, inout Box2.Box) throws -> U) rethrows -> U where Box1 : GenericSynchronizedBox, Box2 : GenericSynchronizedBox {
    while true {
        box1.lock()
        if box2.tryLock() { break }
        box1.unlock()

        box2.lock()
        if box1.tryLock() { break }
        box2.unlock()
    }

    defer {
        box1.unlock()
        box2.unlock()
    }
    return try closure(&box1.unsafeBoxed, &box2.unsafeBoxed)
}

public func zipRead<Box1, Box2, U>(_ box1: Box1, _ box2: Box2, _ closure: (Box1.Box, Box2.Box) throws -> U) rethrows -> U where Box1 : GenericSynchronizedBox, Box2 : GenericSynchronizedBox {
    while true {
        box1.lock()
        if box2.tryLock() { break }
        box1.unlock()

        box2.lock()
        if box1.tryLock() { break }
        box2.unlock()
    }

    defer {
        box1.unlock()
        box2.unlock()
    }
    return try closure(box1.unsafeBoxed, box2.unsafeBoxed)
}
