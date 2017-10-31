//
//  ExportProfile.swift
//  TarantulaPluginCore
//
//  Created by Ilya Mikhaltsou on 10/24/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation

public struct ExportProfile {
    public var profileId: String
    public init(_ id: String) {
        self.profileId = id
    }
}

extension ExportProfile: Equatable {
    public static func == (lhv: ExportProfile, rhv: ExportProfile) -> Bool {
        return lhv.profileId == rhv.profileId
    }
}

extension ExportProfile: Hashable {
    public var hashValue: Int {
        return profileId.hashValue
    }
}

extension ExportProfile: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: ExportProfile.RawValue) {
        self.init(rawValue)
    }

    public var rawValue: ExportProfile.RawValue {
        return profileId
    }
}
