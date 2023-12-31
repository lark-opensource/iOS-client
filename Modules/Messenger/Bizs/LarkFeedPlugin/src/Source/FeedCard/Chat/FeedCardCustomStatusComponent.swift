//
//  FeedCardCustomStatusComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import LarkFocus

// MARK: - Factory
public class FeedCardCustomStatusFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .customStatus
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardCustomStatusComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardCustomStatusComponentView()
    }
}

// MARK: - ViewModel
public class FeedCardCustomStatusComponentVM: FeedCardBaseComponentVM {
    // 组件类别
    public var type: FeedCardComponentType {
        return .customStatus
    }

    // VM 数据
    let isShow: Bool
    let focusStatus: Chatter.FocusStatus?

    // 在子线程生成view data
    public required init(feedPreview: FeedPreview) {
        focusStatus = feedPreview.preview.chatData.chatType == .p2P ? feedPreview.preview.chatData.chatterStatus.topActive : nil
        isShow = focusStatus != nil
    }
}

// MARK: - View
public class FeedCardCustomStatusComponentView: FeedCardBaseComponentView {
    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    public var layoutInfo: LarkOpenFeed.FeedCardComponentLayoutInfo? {
        return nil
    }

    // 组件类别
    public var type: FeedCardComponentType {
        return .customStatus
    }

    public func creatView() -> UIView {
        let focusDisplayView = FocusTagView()
        return focusDisplayView
    }

    public func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? FocusTagView,
              let vm = vm as? FeedCardCustomStatusComponentVM else { return }
        if let focus = vm.focusStatus {
            view.config(with: focus)
        }
        view.isHidden = !vm.isShow
    }

    public func subscribedEventTypes() -> [FeedCardEventType] {
        return [.prepareForReuse]
    }

    public func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any) {
        if case .prepareForReuse = type, let view = object as? UIView {
            view.isHidden = true
        }
    }
}
