//
//  QRLoginConfirmHandlerProtocol.swift
//  LarkAccount
//
//  Created by au on 2023/5/29.
//

import Foundation

/// qrlogin_confirm step's handler
protocol QRLoginConfirmHandlerProtocol {
    func handle(info: QRCodeLoginConfirmInfo,
                context: UniContextProtocol,
                payload: Codable?,
                success: @escaping EventBusSuccessHandler,
                failure: @escaping EventBusErrorHandler)
}
