//
//  AnchorInputHandler.swift
//  Todo
//
//  Created by 张威 on 2021/1/6.
//

import TodoInterface
import EditTextView
import RxSwift
import LarkContainer
import RustPB
import LKCommonsLogging
import TangramService
import LarkEMM
import LarkSensitivityControl
import LarkBaseKeyboard
import LarkModel

/// 处理富文本编辑器（EditTextView）的 url 粘贴行为

final class AnchorInputHandler: TextViewInputProtocol, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    // 捕获 entity，主线程调用
    var entityCapturer: ((_ url: String, _ entity: Rust.RichText.AnchorHangEntity) -> Void)?
    // 根据 entity 获取 icon，主线程调用
    var iconGetter: ((_ entity: Rust.RichText.AnchorHangEntity, _ attrs: [AttrText.Key: Any]) -> MutAttrText)?

    @ScopedInjectedLazy private var anchorService: AnchorService?

    private let disposeBag = DisposeBag()

    private static var logger = Logger.log(AnchorInputHandler.self, category: "Todo.AnchorInputHandler")

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let handler = SubInteractionHandler()
        handler.pasteHandler = { [weak self] textView in
            guard let self = self else { return false }
            return self.handlePaste(textView)
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }

    private func handlePaste(_ textView: BaseEditTextView) -> Bool {
        let config = PasteboardConfig(token: Token("LARK-PSDA-task-anchor-input-handler"))
        guard let string = SCPasteboard.general(config).string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !string.isEmpty else {
            return false
        }
        if URLInputManager.checkURLType(string) == .entityNum,
           let entityNum = URLInputManager.entityNumber(string) {
            handleNum(string, with: entityNum, for: textView)
            return true
        }
        handleURL(string, for: textView)
        return false
    }

    private func handleNum(_ urlStr: String, with entityNum: String, for textView: BaseEditTextView) {
        var anchor = Rust.RichText.Element.AnchorProperty()
        anchor.href = urlStr
        anchor.isCustom = true
        anchor.content = entityNum
        let typingAttrs = textView.typingAttributes
        let anchorAttrText = AnchorTransformer.makeAttrText(
            with: anchor,
            extra: nil,
            iconGetter: nil,
            attrs: typingAttrs
        )
      insertOrReplace(anchorAttrText, subStr: urlStr, in: textView)
    }

    private func handleURL(_ urlStr: String, for textView: BaseEditTextView) {
        guard URL(string: urlStr) != nil else { return }

        if FeatureGating(resolver: userResolver).boolValue(for: .urlPreview) {
            anchorService?.generateHangEntity(forUrl: urlStr)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(
                    onSuccess: {[weak self] entity in
                        self?.replaceUrlStr(urlStr, in: textView, with: entity)
                    },
                    onError: { err in
                        Self.logger.error("get hang entity failed. url: \(urlStr), err: \(err)")
                    }
                )
                .disposed(by: disposeBag)
        }
    }

    private func replaceUrlStr(
        _ urlStr: UrlStr,
        in textView: BaseEditTextView,
        with entity: Rust.RichText.AnchorHangEntity
    ) {
        entityCapturer?(urlStr, entity)
        let typingAttrs = textView.typingAttributes
        var anchor = Rust.RichText.Element.AnchorProperty()
        let extra: AnchorTransformer.Extra = .hangEntity(entity)
        let inlineEntity = InlinePreviewEntity.transform(from: entity)
        anchor.href = urlStr
        anchor.iosHref = urlStr
        anchor.androidHref = urlStr
        anchor.content = urlStr
        anchor.content = inlineEntity.title ?? urlStr
        anchor.textContent = inlineEntity.title ?? urlStr
        let anchorAttrText = AnchorTransformer.makeAttrText(
            with: anchor,
            extra: extra,
            iconGetter: { [weak self] extra in
                guard let iconGetter = self?.iconGetter else { return .init() }
                switch extra {
                case .hangEntity(let hang):
                    return iconGetter(hang, typingAttrs)
                default:
                    return .init()
                }
            },
            attrs: typingAttrs
        )
        insertOrReplace(anchorAttrText, subStr: urlStr, in: textView)
    }

    private func insertOrReplace(_ attrText: MutAttrText, subStr: String, in textView: BaseEditTextView) {
        // 插入一个空格
        attrText.append(NSAttributedString(string: " ", attributes: textView.typingAttributes))
        let textViewAttr = MutAttrText(attributedString: textView.attributedText ?? .init())
        let replaceRange = (textViewAttr.string as NSString).range(of: subStr)

        let cursorLocation: Int
        if replaceRange.location != NSNotFound {
            textViewAttr.replaceCharacters(in: replaceRange, with: attrText)
            cursorLocation = replaceRange.location
        } else {
            cursorLocation = textView.selectedRange.location
            textViewAttr.insert(attrText, at: cursorLocation)
        }
        textView.attributedText = textViewAttr
        textView.selectedRange = NSRange(location: cursorLocation + attrText.length, length: 0)
    }
}
