//
//  FeedCardTitleComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/9.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import LarkZoomable
import SnapKit

// MARK: - Factory
public class FeedCardTitleFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .title
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardTitleComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardTitleComponentView()
    }
}

// MARK: - ViewModel
public protocol FeedCardTitleVM: FeedCardBaseComponentVM {
    var title: String { get }
}

final class FeedCardTitleComponentVM: FeedCardTitleVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .title
    }

    var height: CGFloat {
        FeedCardTitleComponentView.Cons.titleHeight
    }

    // VM 数据
    let title: String

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        self.title = feedPreview.uiMeta.name
    }
}

// MARK: - View
public class FeedCardTitleComponentView: FeedCardBaseComponentView {
    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    public var layoutInfo: LarkOpenFeed.FeedCardComponentLayoutInfo? {
        return nil
    }

    // 组件类别
    public var type: FeedCardComponentType {
        return .title
    }

    public func creatView() -> UIView {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = Cons.titleFont
        /**
         title_width >= 86, p:750
         tag_traing = 0, p:500
         title 抗压缩 p:250
         */
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(Cons.maxWidth).priority(.high)
        }
        return label
    }

    public func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? UILabel,
              let vm = vm as? FeedCardTitleVM else { return }
        view.text = vm.title
    }

    public enum Cons {
        // titleHeight 属性会在列表滑动时多次获取，若为计算变量，会生成大量 UIFont 实例，
        // 这里改用使用静态存储变量提升性能
        private static var _zoom: Zoom?
        private static var _titleHeight: CGFloat = 0
        static var maxWidth: CGFloat { 86.auto() }
        static var titleFont: UIFont { UIFont.ud.title4 }
        public static var titleHeight: CGFloat {
            if Zoom.currentZoom != _zoom {
                // Zoom 级别变化时，对静态存储变量重新赋值
                _zoom = Zoom.currentZoom
                _titleHeight = titleFont.figmaHeight
            }
            return _titleHeight
        }
    }
}
