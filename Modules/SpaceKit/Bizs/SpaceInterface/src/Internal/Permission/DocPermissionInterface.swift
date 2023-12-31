//
//  DocPermissionInterface.swift
//  SpaceInterface
//
//  Created by liweiye on 2020/11/16.
//

import Foundation
import EENavigator

public protocol DocPermissionProtocol {

    func deleteCollaborators(type: Int, token: String, ownerID: String, ownerType: Int, permType: Int, complete: @escaping (Swift.Result<Void, Error>) -> Void)

    // 显示对外分享弹窗，提供给日历调用
    func showAdjustExternalPanel(from: EENavigator.NavigatorFrom, docUrl: String, callback: @escaping ((Swift.Result<Void, AdjustExternalError>) -> Void))
}

public enum AdjustExternalError: Error {
    /// 修改权限设置失败
    case fail
    /// 权限设置弹框不可用
    case disabled
}
