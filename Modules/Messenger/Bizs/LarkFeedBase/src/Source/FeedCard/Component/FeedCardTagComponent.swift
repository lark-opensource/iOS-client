//
//  FeedCardTagComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkBizTag
import LarkModel
import LarkOpenFeed
import LarkTag
import RustPB
import SnapKit

// MARK: - Factory
public class FeedCardTagFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .tag
    }

    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardTagComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardTagComponentView()
    }
}

// MARK: - ViewModel
public protocol FeedCardTagVM: FeedCardBaseComponentVM {
    var tagBuilder: TagViewBuilder { get }
}

final class FeedCardTagComponentVM: FeedCardTagVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .tag
    }

    // VM 数据
    let tagBuilder: TagViewBuilder

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        self.tagBuilder = TagViewBuilder()
    }
}

// MARK: - View
class FeedCardTagComponentView: FeedCardBaseComponentView {
    var layoutInfo: FeedCardComponentLayoutInfo? {
        return FeedCardComponentLayoutInfo(padding: 6, width: nil, height: Cons.height.auto())
    }

    // 组件类别
    var type: FeedCardComponentType {
        return .tag
    }

    func creatView() -> UIView {
        let tagStackView = TagWrapperView()
        tagStackView.lastTagTrailingPriority = .medium
        tagStackView.maxTagCount = 3
        tagStackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        tagStackView.setContentHuggingPriority(.required, for: .horizontal)
        return tagStackView
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let tagStackView = view as? TagWrapperView,
              let vm = vm as? FeedCardTagVM else { return }
        let tagDatas = vm.tagBuilder.getSupportTags()
        if !vm.tagBuilder.isDisplayedEmpty() {
            tagStackView.isHidden = false
            tagStackView.setElements(tagDatas.map({ $0 }))
        } else {
            tagStackView.isHidden = true
            tagStackView.setElements([])
        }
    }

    enum Cons {
        static let height: CGFloat = 16.0
    }
}
