//
//  OperationDialogControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/5/4.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging
import LarkAccountInterface
import ECOInfra

// 运营弹窗
struct OperationDialogBody: PlainBody {
    static let pattern = "//client/workplace/operation_dialog"

    let trace: OPTrace
    let dialogData: OperationDialogData
    let delegate: OperationDialogControllerDelegate

    init(
        trace: OPTrace,
        dialogData: OperationDialogData,
        delegate: OperationDialogControllerDelegate
    ) {
        self.trace = trace
        self.dialogData = dialogData
        self.delegate = delegate
    }
}

final class OperationDialogControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(OperationDialogControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: OperationDialogBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle OperationDialogBody route")
        let userService = try userResolver.resolve(assert: PassportUserService.self)
        let context = try userResolver.resolve(assert: WorkplaceContext.self, argument: body.trace)
        let vc = OperationDialogController(
            context: context,
            dialogData: body.dialogData,
            delegate: body.delegate,
            userService: userService
        )
        res.end(resource: vc)
    }
}
