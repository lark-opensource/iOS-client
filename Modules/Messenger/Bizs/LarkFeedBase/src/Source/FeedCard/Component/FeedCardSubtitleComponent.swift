//
//  FeedCardSubtitleComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import LarkZoomable

// MARK: - Factory
public class FeedCardSubtitleFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .subtitle
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardSubtitleComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardSubtitleComponentView()
    }
}

public enum FeedCardSubtitleData {
    public typealias Builder = () -> FeedCardSubtitleData.R

    case data(FeedCardSubtitleData.R)
    case buildDataOnRendering(Builder)

    public enum R {
        case text(String)
        case attributedText(NSAttributedString)

        public static func `default`() -> FeedCardSubtitleData.R {
            return .text("")
        }
    }
}

public protocol FeedCardSubtitleVM: FeedCardBaseComponentVM, FeedCardLineHeight {
    var subtitleData: FeedCardSubtitleData { get }
}

public extension FeedCardSubtitleVM {
    // 一旦在组装组件时，配置了Subtitle组件，那一定在cell里有高度，即使是没有内容，空白展示的
    var height: CGFloat {
        FeedCardSubtitleComponentView.Cons.subTitleHeight
    }
}

// MARK: - ViewModel
final class FeedCardSubtitleComponentVM: FeedCardSubtitleVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .subtitle
    }

    // VM 数据
    let subtitleData: FeedCardSubtitleData

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        let r = FeedCardSubtitleData.R.text(feedPreview.uiMeta.subtitle)
        self.subtitleData = .data(r)
    }
}

// MARK: - View
class FeedCardSubtitleComponentView: FeedCardBaseComponentView {
    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    var layoutInfo: LarkOpenFeed.FeedCardComponentLayoutInfo? {
        return nil
    }

    // 组件类别
    var type: FeedCardComponentType {
        return .subtitle
    }

    func creatView() -> UIView {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Cons.textColor
        label.font = Cons.subTitleFont
        return label
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? UILabel,
              let vm = vm as? FeedCardSubtitleVM else { return }

        let r: FeedCardSubtitleData.R
        switch vm.subtitleData {
        case .data(let data):
            r = data
        case .buildDataOnRendering(let builder):
            r = builder()
        }

        switch r {
        case .text(let text):
            view.attributedText = nil
            view.text = text
        case .attributedText(let attributedText):
            view.text = nil
            view.attributedText = attributedText
        }
    }

    enum Cons {
        private static var _zoom: Zoom?
        private static var _subTitleHeight: CGFloat = 0
        static var subTitleHeight: CGFloat {
            if Zoom.currentZoom != _zoom {
                _zoom = Zoom.currentZoom
                _subTitleHeight = subTitleFont.figmaHeight
            }
            return _subTitleHeight
        }

        private static var _fontZoom: Zoom?
        private static var _subTitleFont: UIFont?
        public static var subTitleFont: UIFont {
            if Zoom.currentZoom != _fontZoom {
                _fontZoom = Zoom.currentZoom
                _subTitleFont = UIFont.ud.body2
            }
            return _subTitleFont ?? UIFont.ud.body2
        }

        static var textColor: UIColor {
            return UIColor.ud.textPlaceholder
        }
    }
}

public enum FeedCardSubtitleComponentCons {
    public static var textColor: UIColor {
        return FeedCardSubtitleComponentView.Cons.textColor
    }
    public static var subTitleFont: UIFont {
        return FeedCardSubtitleComponentView.Cons.subTitleFont
    }
}
