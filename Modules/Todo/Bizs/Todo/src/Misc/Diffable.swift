//
//  Diffable.swift
//  Todo
//
//  Created by 张威 on 2020/11/13.
//

import Differentiator

protocol DiffableType: IdentifiableType where Identity == DiffIdentifier {
    associatedtype DiffIdentifier: Hashable

    var diffId: DiffIdentifier { get }
}

extension DiffableType {
    var identity: Identity { diffId }
}
