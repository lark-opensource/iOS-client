//
//  Debug+Unregister.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/11/26.
//

import UIKit

extension DebugFactory {
    public func unregisterVC(from: UINavigationController) {
        return launcher.unRegisterUser(complete: nil)
    }
}
