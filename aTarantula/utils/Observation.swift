//
//  Observation.swift
//  velo
//
//  Created by Илья Михальцов on 10/18/14.
//  Copyright (c) 2014 CommonSense Projects. All rights reserved.
//

import Foundation


struct ObservationInfo<T: AnyObject, U: AnyObject> {
    weak var observer: T?
    unowned let observable: Observable<U>
}

typealias ObservationCaller = () -> Bool


/** Provides capability to add alien observers with their own observation context
 *  Usage:
 *  Create instance variable (that would be observation container) and assign to it value
 *  Observable(##your_class##). That would do. To fire just call .fire on the variable.
 *  To add observer use observe function and pass the observation variable
 *  as observable.
 */
public class Observable<T: AnyObject> {
    public typealias Observant = T
    fileprivate var callers: [ObservationCaller] = []
    weak var observantWeak: Observant?
    public var observant: Observant {
        get {
            return observantWeak!
        }
        set {
            observantWeak = newValue
        }
    }

    public init (_ observant: Observant) {
        self.observant = observant
    }

    func append(caller: @escaping ObservationCaller) {
        self.callers.append(caller)
    }

    public func fire() {
        self.callers = self.callers.filter { c -> Bool in return c() }
    }
}

public func observe<A: AnyObject, B: AnyObject> (observable: Observable<B>, observer: A, fire: @escaping (A, B) -> ()) {
    let info = ObservationInfo(observer: observer, observable: observable)
    let caller: ObservationCaller = {
        if let observer = info.observer {
            fire(observer, info.observable.observant)
            return true
        } else {
            // Apparently, no more observer
            return false
        }
    }
    observable.callers.append(caller)
}

infix operator ∆= : AssignmentPrecedence

public struct _TmpObservationOperatorStruct <A: AnyObject, B: AnyObject> {
    let observer: A
    let fire: (A, B) -> ()
}

public func >><A: AnyObject, B: AnyObject> (observer: A, fire: @escaping (A, B) -> ()) -> _TmpObservationOperatorStruct<A, B> {
    return _TmpObservationOperatorStruct(observer: observer, fire: fire)
}

public func ∆=<A: AnyObject, B: AnyObject> (observable: Observable<B>, info: _TmpObservationOperatorStruct<A, B>) {
    observe(observable: observable, observer: info.observer, fire: info.fire)
}

