//
//  GuideDialogHandlerProtocol.swift
//  LarkAccount
//
//  Created by au on 2023/5/18.
//

import Foundation

/// guide_dialog step's handler
protocol GuideDialogHandlerProtocol {
    func handle(info: GuideDialogStepInfo,
                context: UniContextProtocol,
                vcHandler: EventBusVCHandler?,
                success: @escaping EventBusSuccessHandler,
                failure: @escaping EventBusErrorHandler)
}
