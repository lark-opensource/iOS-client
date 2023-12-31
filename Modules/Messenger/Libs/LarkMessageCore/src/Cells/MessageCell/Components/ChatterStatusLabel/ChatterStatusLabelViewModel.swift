//
//  ChatterStatusLabelViewModel.swift
//  Action
//
//  Created by KT on 2019/5/12.
//

import Foundation
import RustPB
import LarkCore
import LarkUIKit
import LarkModel
import RichLabel
import EENavigator
import TangramService
import LarkMessageBase
import LarkMessengerInterface
import UniverseDesignColor
import UniverseDesignIcon
import ThreadSafeDataStructure
import UIKit

public protocol ChatterStatusLabelViewModelContext: ViewModelContext {
    var inlineService: MessageTextToInlineService? { get }
    func getChatThemeScene() -> ChatThemeScene
}

public final class ChatterStatusLabelViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ChatterStatusLabelViewModelContext>: MessageSubViewModel<M, D, C> {
    var icon: UIImage?
    var attriubuteText: NSAttributedString? {
        // 为了避免锁访问，showText前置拦截
        guard showText, let origin = _attriubuteText.value else { return nil }
        let attr = NSMutableAttributedString(attributedString: origin)
        attr.addAttributes([.foregroundColor: textColor,
                            MessageInlineViewModel.iconColorKey: linkColor],
                           range: NSRange(location: 0, length: attr.length))
        return attr
    }
    var _attriubuteText: SafeAtomic<NSAttributedString?> = nil + .readWriteLock
    var urlRangeMap: [NSRange: URL] = [:]
    var textLinkList: [NSRange: String] = [:]
    var showText: Bool = false
    let font = UIFont.ud.caption1
    var linkColor: UIColor {
        chatComponentTheme.chatterDescDocIconColor
    }
    var textColor: UIColor {
        chatComponentTheme.nameAndDescColor
    }
    var linkAttributesColor: UIColor {
        chatComponentTheme.chatterDescDocIconColor
    }
    var attributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        /// appcenter.bytedance.net 在 byWordWrapping下会识别为一个单词
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        return [
            .foregroundColor: textColor,
            .font: font,
            .paragraphStyle: paragraphStyle,
            MessageInlineViewModel.iconColorKey: linkColor,
            MessageInlineViewModel.tagTypeKey: TagType.link
        ]
    }

    private var isDisplay: Bool = false
    private var replacedSourceText: String?
    // 保存上一次替换链接的linkColor
    private var stashLinkColor: UIColor?

    public var chatter: Chatter? {
        return message.fromChatter
    }
    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    public var refreshBlock: (() -> Void)?

    public override func initialize() {
        // 不同于ChatterStatusLabel的实现，没有处理"Mine"里的情况
        guard let chatter = chatter else { return }
        let text = chatter.description_p.text
        _attriubuteText.value = NSAttributedString(string: text, attributes: attributes)
        showText = !text.isEmpty
    }

    public override func willDisplay() {
        super.willDisplay()
        isDisplay = true
        guard let sourceID = chatter?.id, let sourceText = chatter?.description_p.text, !sourceText.isEmpty else {
            // 为了避免频繁锁访问，_attriubuteText不在此处重置，在update(metaModel, metaModelDependency)时重置
//            _attriubuteText.value = nil
            urlRangeMap = [:]
            textLinkList = [:]
            return
        }
        // 已经替换过，则不再替换
        if replacedSourceText == sourceText, self.stashLinkColor == self.linkColor {
            return
        }
        let startTime = CACurrentMediaTime()
        context.inlineService?.replaceWithInlineTryBuffer(
            sourceID: sourceID,
            sourceText: sourceText,
            type: .personalSig,
            attributes: attributes,
            completion: { [weak self] result, _, replacedSourceText, sourceType in
                guard let self = self else { return }
                self.replacedSourceText = replacedSourceText
                self.stashLinkColor = self.linkColor
                if result.urlRangeMap.isEmpty, result.textUrlRangeMap.isEmpty { // 表示未被替换
                    return
                }
                self._attriubuteText.value = result.attriubuteText
                self.urlRangeMap = result.urlRangeMap
                self.textLinkList = result.textUrlRangeMap
                // 可见时才更新，否则只同步属性，下次滚动至可见时刷新
                if self.isDisplay {
                    self.binder.update(with: self)
                    self.update(component: self.binder.component, animation: .none)
                    self.refreshBlock?()
                    self.context.inlineService?.trackURLInlineRender(sourceID: sourceID,
                                                                    sourceText: sourceText,
                                                                    type: .personalSig,
                                                                    sourceType: sourceType,
                                                                    scene: "chat_status",
                                                                    startTime: startTime,
                                                                    endTime: CACurrentMediaTime())
                }
            }
        )
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        // 签名变更或Inline更新时需要重新替换Inline
        self.replacedSourceText = nil
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        guard let chatter = chatter else { return }
        let text = chatter.description_p.text
        _attriubuteText.value = NSAttributedString(string: text, attributes: attributes)
        showText = !text.isEmpty
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        isDisplay = false
    }
}

// MARK: - LKLabelDelegate
extension ChatterStatusLabelViewModel: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        context.navigator(type: .push, url: url, params: NavigatorParams(context: [
            "from": "self_signature",
            "scene": "messenger",
            "location": "messenger_profile"
        ]))
    }

    public func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        context.navigator(type: .open, body: OpenTelBody(number: phoneNumber), params: nil)
    }

    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return false
    }
}
