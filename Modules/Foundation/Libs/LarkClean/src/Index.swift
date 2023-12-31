//
//  Index.swift
//  LarkClean
//
//  Created by 7Up on 2023/6/28.
//

import Foundation
import LarkStorage

public enum CleanIndex {
    /// Represents a path index
    public enum Path {
        /// Absolute Path String
        case abs(String)
    }

    case path(Path)

    /// Represents a key-value index
    public enum Vkey {
        /// based on `LarkStorage.KVStore`
        public struct Unified {
            public var space: Space
            public var domain: DomainType
            public var type: KVStoreType

            public init(space: Space, domain: DomainType, type: KVStoreType) {
                self.space = space
                self.domain = domain
                self.type = type
            }
        }

        case unified(Unified)
    }

    case vkey(Vkey)
}

extension CleanIndex.Vkey.Unified: Hashable {
    public static func == (lhs: CleanIndex.Vkey.Unified, rhs: CleanIndex.Vkey.Unified) -> Bool {
        return lhs.space == rhs.space
            && lhs.domain.isSame(as: rhs.domain)
            && lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(space.isolationId)
        hasher.combine(domain.asComponents().map(\.isolationId))
        hasher.combine(type.rawValue)
    }
}

/// Index Factory
public extension CleanIndex {
    typealias Factory = (CleanContext) -> [CleanIndex]
    typealias PathFactory = (CleanContext) -> [Path]
    typealias VkeyFactory = (CleanContext) -> [Vkey]
}
