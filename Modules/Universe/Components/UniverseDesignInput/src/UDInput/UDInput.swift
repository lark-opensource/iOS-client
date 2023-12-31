//
//  UDInput.swift
//  UniverseDesignInput
//
//  Created by 姚启灏 on 2020/9/20.
//

import Foundation

/// UDInput Delegate
public protocol UDInput {}

/// UDInput Status
public enum UDInputStatus {
    /// normal status
    case normal

    /// activated status
    case activated

    /// disable status
    case disable

    /// error status
    case error
}
