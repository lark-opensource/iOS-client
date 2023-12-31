//
//  Chatter+Ext.swift
//  SKComment
//
//  Created by huayufan on 2023/4/4.
//  


import Foundation
import LarkReactionDetailController

extension Chatter: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Chatter, rhs: Chatter) -> Bool {
        var lhsHasher = Hasher()
        var rhsHasher = Hasher()
        lhs.hash(into: &lhsHasher)
        rhs.hash(into: &rhsHasher)
        return lhsHasher.finalize() == rhsHasher.finalize()
    }
}
