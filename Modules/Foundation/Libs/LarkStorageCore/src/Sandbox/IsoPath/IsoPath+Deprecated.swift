//
//  IsoPath+Deprecated.swift
//  LarkStorage
//
//  Created by 7Up on 2023/7/28.
//

import Foundation

public extension IsoPath {

    @available(*, deprecated, message: "Please use global.in(domain:).build(.temporary)")
    static func glboalTemporary(in domain: DomainType) -> IsoPath {
        return .global.in(domain: domain).build(forType: .temporary)
    }

}
