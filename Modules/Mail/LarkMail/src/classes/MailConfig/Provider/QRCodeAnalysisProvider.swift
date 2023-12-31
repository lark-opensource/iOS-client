//
//  QRCodeAnalysisProvider.swift
//  LarkMail
//
//  Created by Quanze Gao on 2022/11/21.
//

import Foundation
import MailSDK
import LarkContainer
import LarkQRCode
import UniverseDesignToast

class QRCodeAnalysisProvider: QRCodeAnalysisProxy {
    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func handle(code: String, fromVC: UIViewController, errorHandler: @escaping (String?) -> Void) {
        guard let service = try? resolver.resolve(assert: QRCodeAnalysisService.self) else {
            assertionFailure("Failed to get QRCode Service")
            return
        }
        let status: QRCodeAnalysisCallBack = { [weak fromVC] status, callback in
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
