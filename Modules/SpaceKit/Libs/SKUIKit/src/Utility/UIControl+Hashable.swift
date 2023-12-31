//
//  UIControl+Hashable.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/12/13.
//

import Foundation

extension UIControl.State: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
