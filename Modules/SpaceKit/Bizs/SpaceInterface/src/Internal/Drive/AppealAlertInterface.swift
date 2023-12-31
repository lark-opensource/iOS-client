//
//  AppealAlertInterface.swift
//  SpaceInterface
//
//  Created by huangzhikai on 2023/3/16.
//

import Foundation
public protocol AppealAlertDependency {
    func openAppealAlert(objToken: String, version: Int, locale: String)
}
