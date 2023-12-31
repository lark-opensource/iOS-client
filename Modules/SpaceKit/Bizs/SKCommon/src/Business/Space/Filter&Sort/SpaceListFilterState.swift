//
//  SpaceListFilterState.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/4.
//

import Foundation

public enum SpaceListFilterState: Equatable {
    case deactivated
    case activated(type: String?, sortOption: String?, descending: Bool)

    public var isActive: Bool {
        switch self {
        case .deactivated:
            return false
        case .activated:
            return true
        }
    }

    public enum GenerateType {
        case sort
        case filter
        case all
    }
}
