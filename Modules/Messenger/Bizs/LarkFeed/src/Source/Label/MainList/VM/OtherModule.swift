//
//  OtherModule.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/21.
//

import UIKit
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
import LarkEMM
import LarkSensitivityControl
import LarkOpenFeed

final class OtherModule {
    private let dependency: LabelDependency
    private let disposeBag = DisposeBag()

    init(dependency: LabelDependency) {
        self.dependency = dependency
    }

    func preloadDetail(feeds: [FeedPreview]) {
        guard !feeds.isEmpty else { return }
        let chatIds = feeds.filter({ $0.basicMeta.feedPreviewPBType == .chat })
            .map({ $0.id })
        guard !chatIds.isEmpty else { return }
        preloadChatFeed(chatIds)
    }

    private func preloadChatFeed(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        RunloopDispatcher.shared.addTask(priority: .medium) { [weak self] in
            guard let self = self else { return }
            self.dependency.preloadChatFeed(by: ids).subscribe().disposed(by: self.disposeBag)
        }.waitCPUFree()
    }

    func handleDebugEvent(label: LabelViewModel, feed: FeedCardViewModelInterface, view: UIView) {
        let info = "labelId: \(label.item.id), feedId: \(feed.feedPreview.id)"
        let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
        SCPasteboard.general(config).string = info
        FeedContext.log.info("feedlog/label/debug/feed: label: \(label.meta.description), feed: \(feed.feedPreview.description)")
        UDToast.showTips(with: info, on: view)
    }

    func handleDebugEvent(label: LabelViewModel, view: UIView) {
        let info = "labelId: \(label.item.id)"
        let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
        SCPasteboard.general(config).string = info
        FeedContext.log.info("feedlog/label/debug/label: label: \(label.meta.description)")
        UDToast.showTips(with: info, on: view)
    }
}
