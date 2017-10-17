//
//  Utils.swift
//  TarantulaPluginCore
//
//  Created by Ilya Mikhaltsou on 10/17/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

public func random_gauss(m: Double = 0.0, sigma: Double = 1.0) -> Double {
    // https://www.taygeta.com/random/gaussian.html
    let (x1, x2, t): (Double, Double, Double) = {
        var x1: Double
        var x2: Double
        var w: Double
        repeat {
            x1 = Double(arc4random()) / Double(UInt32.max)
            x2 = Double(arc4random()) / Double(UInt32.max)
            w = x1 * x1 + x2 * x2
        } while w >= 1.0
        return (x1, x2, w)
    }()

    let w = sqrt((-2.0 * log(t)) / t)
    let y1 = x1*w
    let y2 = x2*w

    return (y1 * sigma) + m
}

