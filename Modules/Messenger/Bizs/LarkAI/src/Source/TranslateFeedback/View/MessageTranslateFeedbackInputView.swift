//
//  MessageTramslateFeedBackInputView.swift
//  LarkChat
//
//  Created by bytedance on 2020/8/26.
//

import Foundation
import UIKit
import LarkModel
import LarkCore
import RustPB
import SnapKit
import UniverseDesignInput
import UniverseDesignToast
import LarkRichTextCore
import LKCommonsLogging
import LarkFeatureGating
import LarkContainer
import LarkSearchCore
import LarkMessengerInterface
import EENavigator
import LarkEMM

protocol MessageTranslateFeedbackInputViewDelegate: AnyObject {
    /// 开始输入译文
    func translateContentBeginInput(contentView: UITextView)
    /// 结束输入译文
    func translateContentEndInput(contentView: UITextView)
}

private enum UI {
    static let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    static let screenHeight: CGFloat = UIScreen.main.bounds.size.height
    static let originContentViewMaxHeight: CGFloat = 105
    static let translateContentViewHeight: CGFloat = 108
    static let topMargin: CGFloat = 7
    static let titleHeight: CGFloat = 20
    static let commonFont: CGFloat = 16
    static let leftMargin: CGFloat = 16
    static let translateLabelTopMargin: CGFloat = 20
    static let suggestFont: CGFloat = 16
    static let optionalFont: CGFloat = 14
    static let SuggestHeight: CGFloat = 22
    /// 标题和内容之间的间距
    static let titleContentMargin: CGFloat = 8
}

final class MessageTranslateFeedbackInputView: UIView, UDMultilineTextFieldDelegate {
    fileprivate static let logger = Logger.log(MessageTranslateFeedbackInputView.self, category: "MessageTranslateFeedbackInputView")
    /// 由于 Swift 创建正则性能较差, 改为 static
    private static var _lineRegular: NSRegularExpression?
    private static var _spaceRegular: NSRegularExpression?

    private var lineRegular: NSRegularExpression? {
        if Self._lineRegular != nil { return Self._lineRegular }
        Self._lineRegular = try? NSRegularExpression(pattern: "\n+| +|\r+", options: [])
        return Self._lineRegular
    }
    private var spaceRegular: NSRegularExpression? {
        if Self._spaceRegular != nil { return Self._spaceRegular }
        Self._spaceRegular = try? NSRegularExpression(pattern: " +", options: [])
        return Self._spaceRegular
    }
    private let copyConfig: TranslateCopyConfig
    /// 要反馈的消息
    private let message: Message?
    private let selectText: String?
    private let translateText: String?
    private weak var delegate: MessageTranslateFeedbackInputViewDelegate?
    /// 消息原文高度
    public var originContentHeight: CGFloat = 0
    /// 视图整体高度
    private(set) var viewHeight: CGFloat = 0
    /// 原文内容
    private(set) lazy var originContentString: String = {
        return parseMessageContent(isTranslate: false, isSelectTextMode: isSelectTextMode)
    }()
    /// 译文内容
    private(set) lazy var translateContentString: String = {
        return parseMessageContent(isTranslate: true, isSelectTextMode: isSelectTextMode)
    }()

    private(set) lazy var isSelectTextMode: Bool = {
        return message == nil
    }()
    public var originContentTextViewViewHeight: Constraint?

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         selectText: String? = nil,
         translateText: String? = nil,
         delegate: MessageTranslateFeedbackInputViewDelegate,
         message: Message? = nil,
         copyConfig: TranslateCopyConfig = TranslateCopyConfig()) {
        self.userResolver = userResolver
        self.selectText = selectText
        self.translateText = translateText
        self.delegate = delegate
        self.message = message
        self.copyConfig = copyConfig
        super.init(frame: CGRect.zero)
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        clipsToBounds = true
        calculateMessageContentHeight(width: UI.screenWidth)
        addSubview(originLabel)
        originLabel.snp.makeConstraints { (make) in
            make.left.equalTo(UI.leftMargin)
            make.top.equalToSuperview()
            make.height.equalTo(UI.titleHeight)
            make.width.lessThanOrEqualToSuperview()
        }

        addSubview(originContentTextView)
        originContentTextView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(UI.leftMargin)
            make.top.equalTo(originLabel.snp.bottom).offset(2)
            originContentTextViewViewHeight = make.height.equalTo(originContentHeight).constraint
        }

        addSubview(translateLabel)
        translateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(UI.leftMargin)
            make.top.equalTo(originContentTextView.snp.bottom).offset(UI.translateLabelTopMargin)
            make.height.equalTo(UI.SuggestHeight)
            make.width.lessThanOrEqualToSuperview()
        }
        addSubview(translateOptionalLabel)
        translateOptionalLabel.snp.makeConstraints { (make) in
            make.left.equalTo(translateLabel.snp.right)
            make.height.equalTo(UI.titleHeight)
            make.centerY.equalTo(translateLabel.snp.centerY)
            make.width.lessThanOrEqualToSuperview()
        }

        /// 使用相对布局的话，下方滚动将会失效
        addSubview(translateContentTextView)
        translateContentTextView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(UI.leftMargin)
            make.top.equalTo(translateLabel.snp.bottom).offset(UI.titleContentMargin)
            make.height.equalTo(UI.translateContentViewHeight)
        }
        /// 输入框滚动到最后位置
        let offset = translateContentTextView.input.contentSize.height - UI.translateContentViewHeight
        if offset > 0 {
            let bottomOffset = CGPoint(x: 0, y: offset)
            translateContentTextView.input.setContentOffset(bottomOffset, animated: true)
        }

    }
    /// 是否可翻译的消息卡片类型, LarkMessageCore.TranslateControl 也有相同逻辑,注意不要遗漏
    private func isTranslatableMessageCardType(_ message: Message) -> Bool {
        guard message.isTranslatableMessageCardType(), let content = message.content as? CardContent else { return false }
        guard AIFeatureGating.translateCard.isUserEnabled(userResolver: userResolver) else { return false }
        // 与message耦合
        return content.enableTrabslate || AIFeatureGating.translateCardForce.isUserEnabled(userResolver: userResolver)
    }

    // MARK: UITextViewDelegate
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView == translateContentTextView {
            delegate?.translateContentBeginInput(contentView: textView)
        }
        return true
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if textView == translateContentTextView {
            delegate?.translateContentEndInput(contentView: textView)
        }
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            translateContentTextView.endEditing(true)
            return false
        }
        return true
    }

    func calculateText(_ text: String) -> NSAttributedString? {
        return nil
    }
    /// 解析原文/译文内容
    func parseMessageContent(isTranslate: Bool, isSelectTextMode: Bool) -> String {
        var originContentRichText: RustPB.Basic_V1_RichText = RustPB.Basic_V1_RichText()
        var postTitle: String = ""
        // 如果是划词翻译，直接使用文本内容
        if isSelectTextMode == true, let resultText = (isTranslate ? translateText : selectText) {
            return resultText
        }
        guard let message = self.message else { return "" }
        if let content = (isTranslate ? message.translateContent : message.content) as? TextContent {
            // 与message存在耦合
            originContentRichText = content.richText
        } else if let content = (isTranslate ? message.translateContent : message.content) as? PostContent {
            /// 富文本标题
            postTitle = content.title
            if !postTitle.isEmpty {
                postTitle += "\n"
            }
            originContentRichText = content.richText
        } else if let content = (isTranslate ? message.translateContent : message.content) as? AudioContent {
            return content.voiceText
        }
        //与消息卡片摘要实现保持一致：CardModelSummerizeFactory.getSummerize()
        if isTranslatableMessageCardType(message) {
            if let cardContent = (isTranslate ? message.translateContent : message.content) as? CardContent {
                if let summary = cardContent.summary {
                    return summary
                }
                /// 如果存在标题，添加标题
                if cardContent.header.hasMainTitle {
                    postTitle += cardContent.header.mainTitle
                } else if cardContent.header.hasTitle {
                    postTitle += cardContent.header.title
                }
                if cardContent.header.hasSubtitle {
                    postTitle += (" " + cardContent.header.subtitle)
                }

                /// 去掉图片和媒体标签的描述
                let fixRichText = cardContent.richText.lc.convertText(tags: [.img, .media])
                /// 普通文本提取
                var messageCardSummerizeOpts = defaultRichTextSummerizeOpts
                messageCardSummerizeOpts[.button] = {option -> [String] in
                    return option.results
                }
                let stringArray = fixRichText.lc.walker(options: messageCardSummerizeOpts)
                var resultText = stringArray.joined(separator: " ")
                /// 去掉头尾的换行，中间的连续空格
                resultText = resultText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                resultText = lineRegular?.stringByReplacingMatches(
                    in: resultText, options: [],
                    range: NSRange(location: 0, length: resultText.utf16.count),
                    withTemplate: " ") ?? resultText
                resultText = spaceRegular?.stringByReplacingMatches(
                    in: resultText, options: [],
                    range: NSRange(location: 0, length: resultText.utf16.count),
                    withTemplate: " ") ?? resultText
                return postTitle + resultText
            }
        }

        let parseRichTextResult = LarkCoreUtils.parseRichText(richText: originContentRichText, checkIsMe: { (uid) -> Bool in
            return message.fromChatter?.id == uid
            /// 与message存在耦合
        }, customAttributes: [: ])
        return postTitle + parseRichTextResult.attriubuteText.string
    }

    /// 计算原文的文字高度
    func calculateMessageContentHeight(width: CGFloat) -> CGFloat {
        viewHeight = 0
        /// 原文内容的高度，原文最多显示三行，加上了最大高度为74的限制
        originContentHeight = min(originContentString.getUILabelHeight(textViewWidth: width - 32,
                                                                    attributes: [.font: UIFont.systemFont(ofSize: UI.commonFont)],
                                                      textView: originContentTextView), 74)
        /// 原文标题高度
        viewHeight += UI.titleHeight
        /// 原文高度
        viewHeight += originContentHeight
        /// 译文标题高度
        viewHeight += UI.titleHeight
        /// 译文输入框高度
        viewHeight += UI.translateContentViewHeight
        /// 间隔
        viewHeight += (UI.translateLabelTopMargin + UI.translateLabelTopMargin + 4)
        return viewHeight
    }

    // MARK: Lazyload
    /// 原文标题
    private lazy var originLabel: UILabel = {
        let originLabel: UILabel = UILabel()
        originLabel.font = UIFont.boldSystemFont(ofSize: UI.commonFont)
        originLabel.textColor = UIColor.ud.textTitle
        originLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackOriginalText

        return originLabel
    }()

    /// 原文内容
    private lazy var originContentTextView: UILabel = {
        let originContentTextView = UILabel()
        originContentTextView.font = UIFont.systemFont(ofSize: UI.commonFont)
        originContentTextView.text = self.originContentString
        originContentTextView.textColor = UIColor.ud.textCaption
        originContentTextView.backgroundColor = .clear
        originContentTextView.numberOfLines = 3
        originContentTextView.lineBreakMode = .byTruncatingTail
        return originContentTextView
    }()

    /// 译文标题(文字)
    private lazy var translateLabel: UILabel = {
        let translateLabel: UILabel = UILabel()
        translateLabel.font = UIFont.boldSystemFont(ofSize: UI.suggestFont)
        translateLabel.textColor = UIColor.ud.textTitle
        translateLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackRevise
        return translateLabel
    }()
    ///  译文标题（可选）
    private lazy var translateOptionalLabel: UILabel = {
        let translateOptionalLabel: UILabel = UILabel()
        translateOptionalLabel.font = UIFont.systemFont(ofSize: UI.optionalFont)
        translateOptionalLabel.textColor = UIColor.ud.textCaption
        translateOptionalLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackReivse_Optional
        return translateOptionalLabel
    }()

    /// 译文内容
    public lazy var translateContentTextView: UDMultilineTextField = {
        var textField = UDMultilineTextField(textViewType: TranslateFeedBackUDTextView.self)
        var config = UDMultilineTextFieldUIConfig()
        config.borderColor = .ud.textPlaceholder
        config.isShowBorder = true
        config.backgroundColor = .clear
        config.font = UIFont.systemFont(ofSize: UI.commonFont)
        config.textColor = .ud.textTitle

        textField.config = config
        textField.text = self.translateContentString
        textField.delegate = self
        textField.isEditable = true
        textField.input.returnKeyType = .done
        textField.layer.cornerRadius = 4.0
        textField.input.pointId = copyConfig.pointId
        if let textView = textField.input as? TranslateFeedBackUDTextView {
            textView.copyConfig = self.copyConfig
        }
        return textField
    }()

}

final class TranslateFeedBackUDTextView: UDBaseTextView {

    var copyConfig: TranslateCopyConfig = TranslateCopyConfig()

    override func copy(_ sender: Any?) {
        if checkCanCopy() {
            super.copy(sender)
        }
    }

    override func cut(_ sender: Any?) {
        if checkCanCopy() {
            super.cut(sender)
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard copyConfig.hideSystemMenu else {
            return super.canPerformAction(action, withSender: sender)
        }
        //获取安全白名单
        let canRemainActions = SCPasteboard.general(SCPasteboard.defaultConfig()).canRemainActionsDescrption(ignorePreCheck: copyConfig.hideSystemMenu)
        if canRemainActions?.contains(action.description) == true {
            return super.canPerformAction(action, withSender: sender)
        } else {
            return false
        }
    }

    private func checkCanCopy() -> Bool {
        guard copyConfig != nil, copyConfig.canCopy || copyConfig.pointId != nil else {
            if let text = copyConfig.denyCopyText,
                let window = self.window,
                let view = WindowTopMostFrom(window: window).fromViewController?.view {
                UDToast.showFailure(with: text, on: view)
            }
            return false
        }
        return true
    }

}

extension String {
    /// 计算textView的内容高度
    public func getUILabelHeight(textViewWidth: CGFloat,
                                  attributes: [NSAttributedString.Key: Any],
                                  textView: UILabel) -> CGFloat {
        guard let normalText = textView.text as? NSString else {
            return 0
        }
        let size = CGSize(width: textViewWidth, height: CGFloat(MAXFLOAT))
        let stringSize = normalText.boundingRect(with: size,
                                                 options: .usesLineFragmentOrigin,
                                                 attributes: attributes,
                                                 context: nil).size

        return CGFloat(ceilf(Float(stringSize.height)))
    }
}
