//
//  ZeroTrustAssembly.swift
//  ZeroTrust
//
//  Created by kongkaikai on 2020/10/27.
//

import Foundation
import Swinject
import EENavigator
import LarkFoundation
import LarkExtensions
import LKCommonsLogging
import LarkFeatureGating
import LarkAssembler

final public class ZeroTrustAssembly: LarkAssemblyInterface {
    private static let logger = Logger.log(ZeroTrustAssembly.self, category: "ZeroTrustAssembly")

    public init() {}

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute_(type: InstallCertificateBody.self, cacheHandler: true) {
            return InstallCertificateHandler()
        }
    }

    public func registURLInterceptor(container: Container) {
        (InstallCertificateBody.pattern, { (url: URL, from: NavigatorFrom) in
            if LarkFeatureGating.shared.getFeatureBoolValue(for: ZeroTrustConfig.zeroTrustFeatureGatingKey) {
                guard let body = InstallCertificateBody(info: url.lf.queryDictionary) else {
                    Self.logger.error("ZeroTrust: Intsall cert body init failed.")
                    return
                }
                Navigator.shared.open(body: body, from: from)
            } else {
                Self.logger.error("ZeroTrust: Feature not enable.")
            }
        })
    }
}
