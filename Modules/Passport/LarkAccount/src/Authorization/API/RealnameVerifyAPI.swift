//
//  RealnameVerifyAPI.swift
//  LarkAccount
//
//  Created by zhaojingxin on 2022/1/18.
//

import Foundation
import RxSwift

protocol RealnameVerifyAPI {
    /// 扫描二维码触发 实名认证流程
    /// - Returns: 实名认证 第一步 详细信息
    func startVerificationFromQRCode(params: [String: Any]) -> Observable<V3.Step>

    /// 取消二维码 实名认证
    /// - Returns: Void
    func cancelQRCodeVerification(serverInfo: ServerInfo) -> Void
}
