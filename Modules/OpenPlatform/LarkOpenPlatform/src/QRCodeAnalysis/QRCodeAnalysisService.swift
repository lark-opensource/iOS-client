//
//  QRCodeAnalysisService.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/6/26.
//

import Foundation
import Swinject
import LarkQRCode
import OPPlugin

final class OPQRCodeAnalysisProxyProvider: OPQRCodeAnalysisProxy {
    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func handle(code: String, fromVC: UIViewController, errorHandler: @escaping (String?) -> Void) {
        guard let service = resolver.resolve(QRCodeAnalysisService.self) else {
            assertionFailure("Failed to get QRCode Service")
            errorHandler("Failed to get QRCode Service")
            return
        }
        let status: QRCodeAnalysisCallBack = { status, callback in
            switch status {
            case .preFinish:
                break
            case .fail(errorInfo: let errorInfo):
                errorHandler(errorInfo)
            @unknown default:
                break
            }
            callback?()
        }
        service.handle(code: code, status: status, from: .pressImage, fromVC: fromVC)
    }
}
