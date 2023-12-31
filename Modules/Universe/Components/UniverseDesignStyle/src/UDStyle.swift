//
//  UDStyle.swift
//  UniverseDesignStyle
//
//  Created by 姚启灏 on 2020/11/13.
//

import UIKit
import Foundation
import UniverseDesignTheme

/// UniverseDesign Style
public struct UDStyle: UDResource {

    public struct Name: UDKey {
        public let key: String

        public init(_ key: String) {
            self.key = key
        }
    }

    public static var current: Self = Self()

    public var store: SafeDictionary<UDStyle.Name, CGFloat> = SafeDictionary()

    /// Style Init
    /// - Parameter styleMap:
    public init(store: [UDStyle.Name: CGFloat] = [:]) {
        self.store = UniverseDesignTheme.SafeDictionary(store)
    }
}
