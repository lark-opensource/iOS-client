//
//  Identifiable.swift
//  TodoInterface
//
//  Created by 张威 on 2020/11/11.
//

import Foundation

protocol Identifiable {
    /// A type representing the stable identity of the entity associated with
    /// an instance.
    associatedtype ID: Hashable

    /// The stable identity of the entity associated with this instance.
    var id: Self.ID { get }
}

extension Identifiable where Self: AnyObject {

    /// The stable identity of the entity associated with this instance.
    var id: ObjectIdentifier { ObjectIdentifier(self) }
}
