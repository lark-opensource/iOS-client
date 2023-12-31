//
//  E2EeToastUtil.swift
//  ByteView
//
//  Created by ZhangJi on 2023/6/5.
//

import Foundation
import ByteViewMeeting

final class E2EeToastUtil {
    private let session: MeetingSession

    private var showE2EeConnectingJob: DispatchWorkItem?
    private var e2EeHud: LarkToast?
    private var toastDuration: TimeInterval = 30

    init(session: ByteViewMeeting.MeetingSession) {
        self.session = session
    }

    func showE2EeConnectingIfNeed(_ showToast: ((ToastType) -> Void)? = nil) {
        if !session.isE2EeMeeting { return }

        if showE2EeConnectingJob != nil {
            return
        }
        let job = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.showE2EeConnectingJob = nil
            if let showToast = showToast {
                // preview UI异化,走这里
                showToast(.resident(I18n.View_G_EncryptionConnectingState, self.toastDuration))
            } else {
                let view = self.session.service?.router.window
                self.e2EeHud = self.session.service?.larkRouter.showToast(with: I18n.View_G_EncryptionConnectingState, delay: self.toastDuration, on: view)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: job)
        self.showE2EeConnectingJob = job
    }

    func removeE2EeConnectingIfNeed() {
        if showE2EeConnectingJob != nil {
            showE2EeConnectingJob?.cancel()
            showE2EeConnectingJob = nil
        }

        if e2EeHud != nil {
            e2EeHud?.remove()
            e2EeHud = nil
        }
    }
}

extension MeetingSession {
    var e2EeToastUtil: E2EeToastUtil? {
        get { attr(.e2EeToastUtil, type: E2EeToastUtil.self) }
        set { setAttr(newValue, for: .e2EeToastUtil) }
    }
}

private extension MeetingAttributeKey {
    static let e2EeToastUtil: MeetingAttributeKey = "vc.e2EeToastUtil"
}
