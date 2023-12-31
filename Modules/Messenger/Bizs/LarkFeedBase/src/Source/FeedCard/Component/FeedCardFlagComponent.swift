//
//  FeedCardFlagComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import UniverseDesignIcon

// MARK: - Factory
public class FeedCardFlagFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .flag
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardFlagComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardFlagComponentView()
    }
}

// MARK: - ViewModel
final class FeedCardFlagComponentVM: FeedCardBaseComponentVM, FeedCardStatusVisible {
    // 组件类别
    var type: FeedCardComponentType {
        return .flag
    }
    var isVisible: Bool {
        return isShowFlag
    }

    // VM 数据
    let isShowFlag: Bool

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        self.isShowFlag = feedPreview.basicMeta.isFlaged
    }
}

// MARK: - View
class FeedCardFlagComponentView: FeedCardBaseComponentView {
    var layoutInfo: FeedCardComponentLayoutInfo? {
        return FeedCardComponentLayoutInfo(padding: nil, width: flagSize, height: flagSize)
    }

    // 组件类别
    var type: FeedCardComponentType {
        return .flag
    }

    private let flagSize = FeedCardFlagComponentCons.flagSize
    func creatView() -> UIView {
        // 标记的小红旗
        let image = UDIcon.getIconByKey(.flagFilled,
                                        iconColor: UIColor.ud.R500,
                                        size: CGSize(width: flagSize, height: flagSize))
        let flagImageView = UIImageView(image: image)
        flagImageView.setContentHuggingPriority(.required, for: .horizontal)
        flagImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return flagImageView
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {}
}

public enum FeedCardFlagComponentCons {
    public static var flagSize: CGFloat {
        let size: CGFloat = 12
        return .auto(size)
    }
}
