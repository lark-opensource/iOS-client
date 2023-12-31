//
//  FeedTeamViewModel+PreloadFeedDetail.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import AppReciableSDK

extension FeedTeamViewModel {
    func preloadDetail(_ chats: [FeedTeamChatItemViewModel]) {
        guard !chats.isEmpty else { return }
        let chatIds = chats.filter({ $0.chatEntity.basicMeta.feedPreviewPBType == .chat })
            .map({ $0.chatEntity.id })
        guard !chatIds.isEmpty else { return }
        preloadChatFeed(chatIds)
    }

    private func preloadChatFeed(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        // RustFeedAPI中有去重逻辑，此处不用去重
        RunloopDispatcher.shared.addTask(priority: .medium) { [weak self] in
            guard let self = self else { return }
            self.dependency.preloadChatFeed(by: ids).subscribe().disposed(by: self.disposeBag)
        }.waitCPUFree()
    }
}
