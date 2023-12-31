//
//  FeedCardSpecialFocusComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import LarkTag

// MARK: - Factory
public class FeedCardSpecialFocusFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .specialFocus
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardSpecialFocusComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardSpecialFocusComponentView()
    }
}

// MARK: - ViewModel
final class FeedCardSpecialFocusComponentVM: FeedCardBaseComponentVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .specialFocus
    }

    // VM 数据
    let isShowSpecialFocus: Bool
    let tags: [LarkTag.TagType]

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        let isShowSpecialFocus = feedPreview.preview.chatData.isSpecialFocus
        self.isShowSpecialFocus = isShowSpecialFocus
        self.tags = isShowSpecialFocus ? [.specialFocus] : []
    }
}

// MARK: - View
class FeedCardSpecialFocusComponentView: FeedCardBaseComponentView {
    // 组件类别
    var type: FeedCardComponentType {
        return .specialFocus
    }

    var layoutInfo: FeedCardComponentLayoutInfo? {
        return FeedCardComponentLayoutInfo(padding: nil, width: nil, height: Cons.size.auto())
    }

    func creatView() -> UIView {
        let starView = TagWrapperView()
        return starView
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? TagWrapperView,
              let vm = vm as? FeedCardSpecialFocusComponentVM else { return }
        view.isHidden = !vm.isShowSpecialFocus
        view.setTags(vm.tags)
    }

    enum Cons {
        static let size: CGFloat = 16.0
    }
}
