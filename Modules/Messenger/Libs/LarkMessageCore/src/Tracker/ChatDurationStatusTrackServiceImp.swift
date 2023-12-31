//
//  ChatDurationStatusTrackServiceImp.swift
//  LarkMessageCore
//
//  Created by bytedance on 3/30/22.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LarkModel
import LarkUIKit
import RxSwift

final class ChatDurationStatusTrackServiceImp: ChatDurationStatusTrackService {
    private var getChatBlock: (() -> Chat?)?
    private var appearTime: Date?

    private var isAppear: Bool = false {
        didSet {
            statusChanged()
        }
    }

    private var appIsActive: Bool = true {
        didSet {
            statusChanged()
        }
    }

    //视图的window是否被(视频会议等)遮挡
    private var viewIsNotShow: Bool = false {
        didSet {
            statusChanged()
        }
    }
    private var disposeBag = DisposeBag()

    //当(viewIsAppear&&!viewIsNotShow&&appIsActive的)时计时；当这一状态结束时则上报埋点
    private func statusChanged() {
        if isAppear,
           !viewIsNotShow,
           appIsActive {
            appearTime = Date()
        } else {
            trackIfNeed()
        }
    }

    private func trackIfNeed() {
        guard let time = self.appearTime else { return }
        if let getChatBlock = getChatBlock,
           let chat = getChatBlock() {
            LarkMessageCoreTracker.trackDurationStatus(chat: chat, duration: Date().timeIntervalSince(time))
        }
        self.appearTime = nil
    }

    public func setGetChatBlock(block: @escaping () -> Chat?) {
        self.getChatBlock = block
    }

    public func markIfViewControllerIsAppear(value: Bool) {
        isAppear = value
    }

    public func markIfViewIsNotShow(value: Bool) {
        self.viewIsNotShow = value
    }

    init() {
        NotificationCenter.default.rx
            .notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.appIsActive = false
            }).disposed(by: disposeBag)
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.appIsActive = true
            }).disposed(by: disposeBag)
    }
}
