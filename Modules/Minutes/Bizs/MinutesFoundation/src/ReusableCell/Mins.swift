//
//  Mins.swift
//  MinutesFoundation
//
//  Created by chenlehui on 2021/6/18.
//

import Foundation
import UIKit

public struct MinsWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol MinsCompatible { }

extension MinsCompatible {
    public var mins: MinsWrapper<Self> {
        get { return MinsWrapper(self) }
    }
}

extension UITableView: MinsCompatible {}
extension UICollectionView: MinsCompatible {}
extension Date: MinsCompatible {}
extension String: MinsCompatible {}
