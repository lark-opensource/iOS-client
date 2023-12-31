//
//  KeyValueService.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public final class KeyValueService {
    let space: Space
    let domain: DomainType

    public init(space: Space, domain: DomainType) {
        self.space = space
        self.domain = domain
    }
}
