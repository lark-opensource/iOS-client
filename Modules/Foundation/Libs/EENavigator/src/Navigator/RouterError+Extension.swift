//
//  RouterError+Extension.swift
//  EENavigator
//
//  Created by liuwanlin on 2019/7/29.
//

import UIKit
import Foundation

extension RouterError {
    /// Resource with wrong format
    public static var resourceWithWrongFormat: RouterError {
        let message = "Resource with a wrong format"
        return RouterError(code: 11000, message: message)
    }
    /// Cann't push because the resource is empty or the resource is UINavigationController
    public static var cannotPush: RouterError {
        let message = "Cann't push because the resource is empty or the resource is UINavigationController"
        return RouterError(code: 11001, message: message)
    }
    /// Cann't present because the resource is empty or cann't find top most controller
    public static var cannotPresent: RouterError {
        let message = "Cann't present because the resource is empty or cann't find top most controller"
        return RouterError(code: 11002, message: message)
    }
    /// Cann't showDetail because the resource is empty or cann't find top most controller
    public static var cannotShowDetail: RouterError {
        let message = "Cann't showDetail because the resource is empty or cann't find top most controller"
        return RouterError(code: 11003, message: message)
    }
}
