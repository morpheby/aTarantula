//
//  Delay.swift
//  TarantulaPluginCore
//
//  Created by Ilya Mikhaltsou on 10/17/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

public func randomDelay(mean: Double, sigma: Double) {
    let delay = random_gauss(m: mean, sigma: sigma)
    let clamped = delay < 0.5 ? 0.5 : delay
    sleep(UInt32(clamped.rounded()))
}
