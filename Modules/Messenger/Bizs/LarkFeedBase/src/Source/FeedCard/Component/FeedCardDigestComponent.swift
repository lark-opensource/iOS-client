//
//  FeedCardDigestComponent.swift
//  LarkFeedBase
//
//  Created by xiaruzhen on 2023/5/6.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkModel
import RustPB
import UniverseDesignColor
import LarkZoomable

public class FeedCardDigestFactory: FeedCardBaseComponentFactory {
    public var type: FeedCardComponentType {
        return .digest
    }

    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardDigestComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardDigestComponentView()
    }
}

public enum FeedCardDigestVMType {
    case text(String)
    case attributedText(NSAttributedString)
}

public protocol FeedCardDigestVM: FeedCardBaseComponentVM, FeedCardLineHeight {
    var digestContent: FeedCardDigestVMType { get }
    var supportHideByEvent: Bool { get }
}

public extension FeedCardDigestVM {
    // 一旦在组装组件时，配置了digest组件，那一定在cell里有高度，即使是没有内容，空白展示的
    var height: CGFloat {
        FeedCardDigestComponentView.Cons.digestHeight
    }

    var supportHideByEvent: Bool {
        return false
    }
}

final class FeedCardDigestComponentVM: FeedCardDigestVM {
    // VM 数据
    let digestContent: FeedCardDigestVMType
    // 表明组件类别
    var type: FeedCardComponentType {
        return .digest
    }

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        self.digestContent = Self.getDigest(unreadCount: feedPreview.basicMeta.unreadCount,
                                            isRemind: feedPreview.basicMeta.isRemind,
                                            digest: feedPreview.uiMeta.digestText)
    }

    // 默认纯文本摘要信息实现,不支持草稿展示;若要展示草稿,需要特化实现
    private static func getDigest(unreadCount: Int, isRemind: Bool, digest: String) -> FeedCardDigestVMType {
        var digestText = ""
        if FeedBadgeBaseConfig.badgeStyle == .strongRemind,
            unreadCount > 0, !isRemind {
            digestText = unreadCount == 1 ?
                BundleI18n.LarkFeedBase.Lark_Legacy_UnReadCount("\(unreadCount)") :
                BundleI18n.LarkFeedBase.Lark_Legacy_UnReadCounts("\(unreadCount)")
        }

        digestText.append(digest)

        // fix crash on iOS11
        // Jira：https://jira.bytedance.com/browse/SUITE-64239
        // fix version：3.13.0
        if #unavailable(iOS 12.0) {
            digestText = digestText.replacingOccurrences(of: "?️", with: "?")
        }

        return .text(digestText)
    }
}

public class FeedCardDigestComponentView: FeedCardBaseComponentView {
    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    public var layoutInfo: LarkOpenFeed.FeedCardComponentLayoutInfo? {
        return nil
    }

    // 表明组件类别
    public var type: FeedCardComponentType {
        return .digest
    }

    private var digestLabel: UILabel?
    private var vm: FeedCardDigestVM?

    // cell init 的时候去调用
    public func creatView() -> UIView {
        let label = UILabel()
        label.textColor = Cons.textColor
        label.font = Cons.digestFont
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        digestLabel = label
        return label
    }

    // cell for row 的时候去调用
    public func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let label = view as? UILabel,
              let vm = vm as? FeedCardDigestVM else { return }
        self.vm = vm
        switch vm.digestContent {
        case .text(let text):
            label.attributedText = nil
            label.text = text
        case .attributedText(let attributedText):
            label.text = nil
            // TODO: open feed 摘要待优化
            let attributedText = NSMutableAttributedString(attributedString: attributedText)
            attributedText.addAttributes([.font: Cons.digestFont], range: NSRange(location: 0, length: attributedText.length))
            label.attributedText = attributedText
        }
    }

    public func subscribedEventTypes() -> [FeedCardEventType] {
        return [.rendered]
    }

    public func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any) {
        // TODO: open feed
        if case .rendered = type,
           case .rendered(let componentType, let componentValue) = value {
            // 渲染事件
            if let supportHide = vm?.supportHideByEvent as? Bool, supportHide {
                // 判断是否支持事件触发隐藏操作
               if componentType == .reaction, let context = componentValue as? [String: Any],
                  let hasMore = context[FeedCardReactionComponentView.reactionHasMoreKey] as? Bool {
                   // 处理 reaction 组件的互斥逻辑
                   // TODO: open feed 确认下必须使用isHidden吗
                   digestLabel?.isHidden = hasMore
               } else {
                   digestLabel?.isHidden = false
               }
            } else {
                digestLabel?.isHidden = false
            }
        }
    }

    public enum Cons {
        public static var textColor: UIColor { UIColor.ud.N500 }
        private static var _zoom: Zoom?
        private static var _digestHeight: CGFloat = 0
        public static var digestHeight: CGFloat {
            if Zoom.currentZoom != _zoom {
                _zoom = Zoom.currentZoom
                _digestHeight = digestFont.figmaHeight
            }
            return _digestHeight
        }

        private static var _digestZoom: Zoom?
        private static var _digestFont: UIFont?
        public static var digestFont: UIFont {
            if Zoom.currentZoom != _digestZoom {
                _digestZoom = Zoom.currentZoom
                _digestFont = UIFont.ud.body2
            }
            return _digestFont ?? UIFont.ud.body2
        }
    }
}
