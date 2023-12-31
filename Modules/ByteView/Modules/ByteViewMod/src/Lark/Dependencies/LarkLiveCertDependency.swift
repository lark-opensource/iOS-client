//
//  LarkLiveCertDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2023/2/15.
//

import Foundation
import ByteViewLiveCert
import ByteViewCommon
import LarkContainer
import LarkBytedCert
import LarkUIKit

final class LarkLiveCertDependency: CertDependency {
    let logger = Logger.getLogger("Cert")

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 开始活体检测
    /// - Parameters:
    ///   - appID: app id
    ///   - ticket: 一次完整业务流程的票据
    ///   - scene: 场景
    ///   - callback: callback 回调
    func doFaceLiveness(appID: String, ticket: String, scene: String,
                        callback: @escaping (_ data: [AnyHashable: Any]?, _ errmsg: String?) -> Void) {
        LarkBytedCert().doFaceLiveness(appId: appID, ticket: ticket, scene: scene, callback: callback)
    }

    /// 跳转到H5
    func openURL(_ url: URL, from: UIViewController) {
        logger.info("openURL: \(url.hashValue)")
        if let req = URL(string: "//client/web/simple") {
            userResolver.navigator.present(req, context: ["url": url], wrap: LkNavigationController.self, from: from, prepare: { $0.modalPresentationStyle = .fullScreen })
        }
    }
}
