//
//  CertDependency.swift
//  ByteViewLiveCert
//
//  Created by kiri on 2023/2/14.
//

import Foundation

public protocol CertDependency {
    /// 开始活体检测
    /// - Parameters:
    ///   - appID: app id
    ///   - ticket: 一次完整业务流程的票据
    ///   - scene: 场景
    ///   - callback: callback 回调
    func doFaceLiveness(appID: String, ticket: String, scene: String,
                        callback: @escaping (_ data: [AnyHashable: Any]?, _ errmsg: String?) -> Void)

    /// 跳转到H5
    func openURL(_ url: URL, from: UIViewController)
}
