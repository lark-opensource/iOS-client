//
//  AccountInterruptTask.swift
//  ByteViewMod
//
//  Created by kiri on 2022/3/23.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import BootManager
import LarkContainer
import LarkAccountInterface
import ByteViewCommon
import ByteViewUI
import ByteViewInterface
import RxSwift
import LarkShortcut

final class AccountInterruptTask: UserFlowBootTask, Identifiable {
    static let identify: TaskIdentify = "ByteView.AccountInterruptTask"

    override func execute(_ context: BootContext) {
        guard let service = try? userResolver.resolve(assert: PassportService.self) else { return }
        service.register(interruptOperation: ByteViewInterruptOperation(userResolver: userResolver))
    }
}

private final class ByteViewInterruptOperation: InterruptOperation {
    private let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func getInterruptObservable(type: LarkAccountInterface.InterruptOperationType) -> Single<Bool> {
        Single<Bool>.deferred { [weak self] () -> PrimitiveSequence<SingleTrait, Bool> in
            Single<Bool>.create { callback in
                guard let self = self else {
                    callback(.success(true))
                    return Disposables.create()
                }
                self.allowsAccountInterrupt(type: type) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let b):
                            callback(.success(b))
                        case .failure(let error):
                            callback(.error(error))
                        }
                    }
                }
                return Disposables.create()
            }
        }
    }

    func allowsAccountInterrupt(type: LarkAccountInterface.InterruptOperationType, completion: @escaping (Result<Bool, Error>) -> Void) {
        let logger = Logger.interface
        guard let shortcutClient = try? userResolver.resolve(assert: ShortcutService.self).getClient(.vc),
              let meetingService = try? userResolver.resolve(assert: MeetingService.self),
              let meeting = meetingService.currentMeeting, meeting.isActive else {
            logger.info("allowsAccountInterrupt(type: \(type)), session is nil")
            completion(.success(true))
            return
        }

        logger.info("allowsAccountInterrupt(type: \(type))")
        let meetType = meeting.type
        let isBoxSharing = meeting.isBoxSharing
        let title: String
        switch (meetType, type, isBoxSharing) {
        case (_, .switchAccount, true):
            title = I18n.View_G_IfSwitchIdentityLeaveMeetingScreenShare_PopUpWindow
        case (_, .relogin, true):
            title = I18n.View_G_ExitScreenSharingIfLogOut_PopUpWindow
        case (.meet, .switchAccount, false):
            title = I18n.View_M_LeaveIfSwitchInfo
        case (.meet, .relogin, false):
            title = I18n.View_M_LeaveIfLogOutInfo
        case (.call, .switchAccount, false):
            title = I18n.View_G_LeaveCallIfSwitchInfo
        case (.call, .relogin, false):
            title = I18n.View_G_LeaveCallIfLogOutInfo
        case (_, .sessionInvalid, _):
            let action = LeaveMeetingAction(sessionId: meeting.sessionId, reason: .accountInterruption, shouldWaitServerResponse: true)
            shortcutClient.run(action) { _ in
                completion(.success(true))
            }
            return
        default:
            completion(.success(true))
            return
        }
        ByteViewDialog.Builder()
            .id(.exitMeetingByLogout)
            .title(title)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                completion(.success(false))
            })
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ _ in
                guard let meeting = meetingService.currentMeeting, meeting.isActive else {
                    completion(.success(true))
                    return
                }
                let action = LeaveMeetingAction(sessionId: meeting.sessionId, reason: .accountInterruption)
                shortcutClient.run(action) { _ in
                    completion(.success(true))
                }
            })
            .show()
    }

    var description: String {
        "ByteViewInterruptOperation"
    }
}
