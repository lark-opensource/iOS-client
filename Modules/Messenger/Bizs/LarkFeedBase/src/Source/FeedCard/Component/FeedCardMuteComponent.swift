//
//  FeedCardMuteComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import LarkFeatureGating

// MARK: - Factory
public class FeedCardMuteFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .mute
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardMuteComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardMuteComponentView()
    }
}

// MARK: - ViewModel
final class FeedCardMuteComponentVM: FeedCardBaseComponentVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .mute
    }

    // VM 数据
    let isShowMute: Bool

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        self.isShowMute = (!feedPreview.basicMeta.isRemind) && (feedPreview.basicMeta.feedPreviewPBType != .box)
    }
}

// MARK: - View
class FeedCardMuteComponentView: FeedCardBaseComponentView {
    var layoutInfo: FeedCardComponentLayoutInfo? = FeedCardComponentLayoutInfo(padding: Cons.padding,
                                                                               width: .auto(Cons.size),
                                                                               height: .auto(Cons.size))
    // 组件类别
    var type: FeedCardComponentType {
        return .mute
    }

    func creatView() -> UIView {
        let muteIcon = UIImageView(image: Resources.LarkFeedBase.feedAlertsOff)
        return muteIcon
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? UIImageView,
              let vm = vm as? FeedCardMuteComponentVM else { return }
        view.isHidden = !vm.isShowMute
    }

    enum Cons {
        static let padding: CGFloat = 16.0
        static let size: CGFloat = 14.0
    }
}
