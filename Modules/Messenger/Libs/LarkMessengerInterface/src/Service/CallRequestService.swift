//
//  CallRequestService.swift
//  LarkInterface
//
//  Created by 李勇 on 2019/6/19.
//

import Foundation
import EENavigator

/// 拨打电话请求
public protocol CallRequestService {
    // 拨打电话请求工具方法
    func callChatter(chatterId: String, chatId: String, deniedAlertDisplayName: String, from: NavigatorFrom, errorBlock: ((Error?) -> Void)?, actionBlock: ((String) -> Void)?)
    // 显示电话号码请求
    func showPhoneNumber(chatterId: String, from: NavigatorFrom, callBack: @escaping (String) -> Void)
    // 拨打电话请求
    func callByPhone(chatterId: String, from: NavigatorFrom, callBack: @escaping (String) -> Void)
}
