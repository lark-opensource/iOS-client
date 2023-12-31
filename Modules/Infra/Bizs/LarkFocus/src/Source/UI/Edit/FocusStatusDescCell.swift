//
//  FocusStatusDescCell.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2023/1/3.
//

import Foundation
import UIKit
import RustPB
import RxSwift
import UniverseDesignColor
import UniverseDesignFont
import EditTextView
import LarkRichTextCore
import LarkContainer
import LarkKeyboardView
import TangramService
import UniverseDesignIcon
import EENavigator
import LarkMention
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import LarkExtensions
import LarkBaseKeyboard

final class FocusStatusDescCell: UITableViewCell, UserResolverWrapper {
    static let logger = Logger.log(FocusStatusDescCell.self, category: "FocusStatusDescCell")

    @ScopedInjectedLazy var urlPreviewAPI: URLPreviewAPI?
    @ScopedInjectedLazy private var focusManager: FocusManager?

    weak var baseViewController: UIViewController?

    var onEditing: (() -> Void)?
    var completeTask: (([PickerOptionType]) -> Void)?
    var cancelTask: (() -> Void)?

    let disposeBag: DisposeBag = DisposeBag()

    var isEditViewEditing: Bool = false

    var currentTextCount: Int {
        guard let text = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return 0 }
        return getLength(forText: text)
    }

    /// 获取 编辑框文字
    ///
    /// 1. attr 转为 richText
    /// 2. 根据三端定的情况，中台链接以 anchor 的形式上传，Link 需要转成 Anchor
    /// 3. 上传的信息中，at element 不应包含用户信息，需要去掉用户名 / 备注名
    /// 4. 其他两端可能需要 innnterText 属性
    func getFocusStatusDescRichText() -> FocusStatusDescRichText? {
        guard var attributedText = self.textView.attributedText else { return nil }
        guard !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        attributedText = self.replaceLinkAttrToAnchorAttr(attributedText)
        attributedText = attributedText.lf.trimmedAttributedString(set: .whitespacesAndNewlines)
        var richText = RichTextTransformKit.transformStringToRichText(string: attributedText)
        richText = self.replaceAtContentToNil(richText)
        if let _richText = richText {
            Self.logger.info("[\(#function)], atId-Count: \(_richText.atIds.count), anchorId-Count: \(_richText.anchorIds.count)")
            richText?.innerText = attributedText.string
        } else {
            Self.logger.info("[\(#function)], richText is Nil")
        }
        return richText
    }

    /// 设置编辑框文字
    ///
    /// 1. 下发的 at element 为空，需要根据 userId 获取用户信息，实时展示当前用户看到的被艾特的人的备注名 / 用户名，拉取完毕再展示文字
    /// 2. 展示的文字，anchor property 转换为 link property，使用 link 的 样式，并使用 URLAPI 解析
    func setFocusStatusDesc(with statusDesc: FocusStatusDesc?) {
        guard let fromRichText = statusDesc?.richText else { return }
        let attributes = self.textView.defaultTypingAttributes
        Self.logger.info("[\(#function)], atId-Count: \(fromRichText.atIds.count), anchorId-Count: \(fromRichText.anchorIds.count)")
        self.replaceNilAtContentToUserName(fromRichText) { [weak self] richText in
            guard let self = self else { return }
            self.textView.attributedText = RichTextTransformKit.transformRichTextToStr(richText: richText, attributes: attributes, attachmentResult: [:])
            self.textDidChange(textView: self.textView)
            guard let attributedText = self.textView.attributedText else { return }
            self.replaceAnchorAttrToLinkAttr(attributedText)
        }
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }

    //支持url预览后的限制
    private var maxLength = Cons.maxTextCount

    private lazy var textInputProtocolSet = TextViewInputProtocolSet()

    private lazy var editWrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Cons.editViewCornerRadius
        view.layer.borderWidth = Cons.editViewBorderWidth
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        view.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
        return view
    }()
    
    private lazy var textView: FocusStatusTextView = {
        let textView = FocusStatusTextView(userResolver: userResolver)
        textView.delegate = self
        return textView
    }()

    /// 内容剩余可输入长度
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.font = Cons.editViewNumberLabelFont
        label.textColor = Cons.editViewNumberLabelTextColor
        return label
    }()

    /// 清空textView按钮
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UDIcon.getIconByKey(.closeOutlined).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        button.hitTestEdgeInsets = Cons.editViewClearBtnHitTestArea
        button.addTarget(self, action: #selector(didTapClearButton), for: .touchUpInside)
        button.tintColor = Cons.editViewClearBtnColor
        return button
    }()

    /// 底部状态说明介绍文字
    private(set) lazy var footerLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkFocus.Lark_Profile_StatusNote_Desc
        label.textColor = UIColor.ud.textPlaceholder
        label.font = Cons.editViewFooterLabelFont
        label.numberOfLines = 2
        return label
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(style: .default, reuseIdentifier: "FocusStatusDescCell")
        selectionStyle = .none
        setup()
        initInputHandler()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        contentView.addSubview(editWrapperView)
        editWrapperView.addSubview(textView)
        editWrapperView.addSubview(numberLabel)
        editWrapperView.addSubview(clearButton)
        contentView.addSubview(footerLabel)
    }

    private func setupConstraints() {
        editWrapperView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Cons.editViewTopMargin)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Cons.editViewTopHeight)
        }

        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Cons.textViewTopMargin)
            make.bottom.equalToSuperview().offset(Cons.textViewBottomMargin)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        clearButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(Cons.clearBtnBotttomMargin)
            make.width.height.equalTo(Cons.clearBtnSideLength)
            make.right.equalToSuperview().offset(Cons.clearBtnRightMargin)
        }

        numberLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(clearButton)
            make.right.equalTo(clearButton.snp.left).offset(Cons.numberLabelRightMargin)
            make.top.equalTo(clearButton.snp.top)
            make.bottom.equalTo(clearButton.snp.bottom)
        }

        footerLabel.snp.makeConstraints { make in
            make.leading.equalTo(textView).offset(Cons.footerLabelMargin)
            make.trailing.equalTo(textView).offset(-Cons.footerLabelMargin)
            make.top.equalTo(editWrapperView.snp.bottom).offset(Cons.footerLabelTopMargin)
            make.bottom.equalToSuperview().offset(Cons.footerLabelBottomMargin)
        }
    }

    private func setupAppearance() {
        self.backgroundColor = .clear
        self.textDidChange(textView: self.textView)
    }
}

// MARK: 输入框相关
extension FocusStatusDescCell {
    private func initInputHandler() {
        let urlInputHandler = getURLInputHandler()
        let mentionInputHandler = getMentionInputHandler()
        let atInputHandler = AtUserInputHandler()
        let textInputProtocolSet = TextViewInputProtocolSet([urlInputHandler, mentionInputHandler, atInputHandler])
        self.textInputProtocolSet = textInputProtocolSet
        self.textInputProtocolSet.register(textView: textView)
    }

    private func getURLInputHandler() -> FocusURLInputHandler {
        let urlInputHandler = FocusURLInputHandler(urlPreviewAPI: urlPreviewAPI)
        urlInputHandler.previewCompleteBlock = { [weak self] textView in
            guard let self = self else { return }
            self.textDidChange(textView: textView)
        }
        return urlInputHandler
    }

    private func getMentionInputHandler() -> AtPickerInputHandler {
        let mentionInputHandler = AtPickerInputHandler { [weak self] (textView, range, _) in
            guard let self = self else { return }
            guard let baseVC = self.baseViewController else { return }
            self.resignFirstResponder()
            let defaultTypingAttributes = self.textView.defaultTypingAttributes

            let mentionVC = FocusMentionViewController(userResolver: self.userResolver)
            let mention = FocusMentionPanel(mentionVC: mentionVC)

            mention.delegate = self
            self.cancelTask = { [weak self] in
                guard let self = self else { return }
                mention.mentionVC.onDismiss()
                self.textView.becomeFirstResponder()
            }

            self.completeTask = { [weak self] items in
                guard let self = self else { return }
                let inputKeyboardAtItems = items.compactMap { item -> InputKeyboardAtItem? in
                    switch item.type {
                    case .chatter:
                        self.transformItemToChatter(item, range: range, defaultTypingAttributes: defaultTypingAttributes)
                        return nil
                    case .document:
                        guard case .doc(let info) = item.meta else { return nil }
                        return .doc(info.url, item.name?.string ?? "", info.docType)
                    case .wiki:
                        guard case .wiki(let info) = item.meta else { return nil }
                        return .wiki(info.url, item.name?.string ?? "", info.docType)
                    default:
                        return nil
                    }
                }
                guard !inputKeyboardAtItems.isEmpty else { return }
                self.insertAtInTextView(inputKeyboardAtItems, range: range, defaultTypingAttributes: defaultTypingAttributes)
                self.textDidChange(textView: self.textView)
            }
            mention.show(from: baseVC)
        }
        return mentionInputHandler
    }

    private func insertAtInTextView(_ items: [InputKeyboardAtItem], range: NSRange, defaultTypingAttributes: [NSAttributedString.Key: Any]) {
        // 删除已经插入的at
        self.textView.selectedRange = NSRange(location: range.location + 1, length: range.length)
        self.textView.deleteBackward()
        // 插入at标签
        items.forEach { (item) in
            switch item {
            case .chatter(let item):
                self.textView.insertAtTag(userName: item.name, actualName: item.actualName, userId: item.id, isOuter: item.isOuter)
            case .doc(let url, let title, let type), .wiki(let url, let title, let type):
                if let url = URL(string: url) {
                    self.textView.insertUrl(title: title, url: url, type: type)
                } else {
                    self.textView.insertUrl(urlString: url)
                }
            }
        }
        self.textView.defaultTypingAttributes = defaultTypingAttributes
    }

    func transformItemToChatter(_ item: PickerOptionType, range: NSRange ,defaultTypingAttributes: [NSAttributedString.Key: Any]) {
        guard let id = item.avatarID else { return }
        guard (id.isEmpty == false) && (item.name != nil) else { return }
        focusManager?.dataService.getChatter(id) { chatter in
            guard let chatter = chatter else { return }
            let disPlayName = chatter.alias.isEmpty ? chatter.nameWithAnotherName : chatter.alias
            let chatterItem = InputKeyboardAtChatter(id: id, name: disPlayName, actualName: disPlayName, isOuter: false)
            self.insertAtInTextView([.chatter(chatterItem)], range: range, defaultTypingAttributes: defaultTypingAttributes)
            self.textDidChange(textView: self.textView)
        }
    }

    @objc
    private func didTapClearButton() {
        textView.text = nil
        textDidChange(textView: self.textView)
        self.endEditing(true)
    }

    // 按照特定字符计数规则，获取字符串长度
    private func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
            return res + min(char.utf8.count, 2)
        }
    }

    /// 更新计数文字颜色，格式 12 / 400，目前超出字数限制时，为全红
    private func updateTextCount(_ textCount: Int) {
        let exceedColor = UIColor.ud.functionDangerContentDefault
        let fullText = "\(textCount)/\(maxLength)"
        let fullAttr = NSMutableAttributedString(string: fullText)
        if (textCount > maxLength) {
            //更新displayText字体颜色
            fullAttr.addAttributes([.foregroundColor: exceedColor], range: (fullText as NSString).range(of: String(textCount)))
        }
        numberLabel.attributedText = fullAttr
        self.changeBorderEditingColor(textCount)
    }

    func changeBorderEditingColor(_ textLength: Int) {
        if textLength > maxLength {
            editWrapperView.ud.setLayerBorderColor(UIColor.ud.functionDangerContentDefault)
        } else {
            if isEditViewEditing {
                editWrapperView.ud.setLayerBorderColor(UIColor.ud.primaryContentDefault)
            } else {
                editWrapperView.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
            }
        }
    }
}

// MARK: Delegate
extension FocusStatusDescCell: UITextViewDelegate, UIScrollViewDelegate, MentionPanelDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.isEditViewEditing = true
        editWrapperView.ud.setLayerBorderColor(UIColor.ud.primaryContentDefault)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.isEditViewEditing = false
        editWrapperView.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.resignFirstResponder()
            return false
        }
        return self.textInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if #available(iOS 13.0, *) { return false }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        self.onEditing?()
        self.textInputProtocolSet.textViewDidChange(textView)
        self.textDidChange(textView: textView)
    }

    func textDidChange(textView: UITextView) {
        let textCount = self.getLength(forText: textView.text)
        self.updateTextCount(textCount)
    }

    func panel(didDismissWithGlobalCheckBox selected: Bool) { }

    func panel(didFilter items: [LarkMention.PickerOptionType]) -> [LarkMention.PickerOptionType] {
        return []
    }

    func panel(didMultiSelect item: LarkMention.PickerOptionType, at row: Int, isSelected: Bool) { }

    func panel(didFinishWith items: [PickerOptionType]) {
        self.completeTask?(items)
    }
}

// MARK: 富文本相关
extension FocusStatusDescCell {
    /// 替换 NSAttributedString 中的 Link 样式为 Anchor 样式
    func replaceLinkAttrToAnchorAttr(_ from: NSAttributedString) -> NSAttributedString {
        var toAttr = NSMutableAttributedString(attributedString: from)
        toAttr = self.clearURLIcon(toAttr, with: ImageTransformer.RemoteIconAttachmentAttributedKey)
        toAttr = self.clearURLIcon(toAttr, with: ImageTransformer.LocalIconAttachmentAttributedKey)
        toAttr = self.transformLinkToAnchor(toAttr)
        return toAttr
    }

    /// 转化 NSAttributedString 中的 anchor 标签为 link 标签，并尝试 url 解析
    func replaceAnchorAttrToLinkAttr(_ from: NSAttributedString) {
        let toAttr = NSMutableAttributedString(attributedString: from)
        let urls = self.generateURLRanges(toAttr)
        urls.reversed().forEach { url in
            guard let URL = URL(string: url) else { return }
            self.urlPreviewAPI?.generateUrlPreviewEntity(url: url)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] inlineEntity, _ in
                    guard let self = self else { return }
                    guard let entity = inlineEntity, !(entity.title ?? "").isEmpty else { return }
                    let typingAttributes = self.textView.defaultTypingAttributes
                    let replaceStr = FocusURLInputHandler.transformToURLAttr(entity: entity, originURL: URL, attributes: typingAttributes)
                    let range = (toAttr.string as NSString).range(of: url)
                    if range.location != NSNotFound {
                        toAttr.replaceCharacters(in: range, with: replaceStr)
                        self.textView.attributedText = toAttr
                        self.textDidChange(textView: self.textView)
                    } else {
                        Self.logger.info("urlPreviewAPI range.location is not Found")
                    }
                })
                .disposed(by: self.disposeBag)
        }
    }

    /// 上传 `richText` 时，替换 `richText.at.Content` 为空，保留 at 样式
    func replaceAtContentToNil(_ from: FocusStatusDescRichText?) -> FocusStatusDescRichText? {
        guard var richText = from, !richText.atIds.isEmpty else { return from }
        var convertElements = richText.elements
        for atId in richText.atIds {
            guard var atElement = convertElements[atId], atElement.tag == .at else { return richText }
            atElement.property.at.content = ""
            convertElements[atId] = atElement
        }
        richText.elements = convertElements
        return richText
    }

    /// 下发 `richText` 时，通过 `richText` 中的 `userid` 将 at 的人名替换为对应用户应该看到的人名
    ///
    /// - parameter from: 下发的 richText
    /// - parameter completion: 解析完用户名后的给 editTextView 进行的赋值操作等
    func replaceNilAtContentToUserName(_ from: FocusStatusDescRichText, completion: @escaping (FocusStatusDescRichText) -> Void) {

        guard !from.atIds.isEmpty else {
            completion(from)
            return
        }

        var userIds: [String] = []
        var atId2UserIdMap: Dictionary<String, String> = [:]

        /// 通过 `atIds` 取得对应的 `userId`
        for atId in from.atIds {
            guard let element = from.elements[atId], element.tag == .at else {
                completion(from)
                return
            }
            let userId = element.property.at.userID
            atId2UserIdMap[atId] = userId
            userIds.append(userId)
        }
        /// 通过 `userId` 取得对应的 `chatter`，来获取备注名或其他名称
        focusManager?.dataService.getChatters(userIds, from, atId2UserIdMap: atId2UserIdMap, completion: completion)
    }

    func generateURLRanges(_ from: NSMutableAttributedString) -> [String] {
        var urls: [String] = []
        from.enumerateAttribute(AnchorTransformer.AnchorAttributedKey, in: NSRange(location: 0, length: from.length)) { (anchorInfo, range, _) in
            guard anchorInfo != nil else { return }
            urls.append(from.mutableString.substring(with: range))
        }
        return urls
    }

    func clearURLIcon(_ from: NSAttributedString, with key: NSAttributedString.Key) -> NSMutableAttributedString {
        let toAttr = NSMutableAttributedString(attributedString: from)
        var ranges: [NSRange] = []
        toAttr.enumerateAttribute(key, in: NSRange(location: 0, length: toAttr.length)) {(imageInfo, range, _) in
            guard imageInfo != nil  else { return }
            ranges.append(range)
        }
        ranges.reversed().forEach { range in
            toAttr.replaceCharacters(in: range, with: "")
        }
        return toAttr
    }

    /// 转换 attributedString 的 link 样式为 anchor 样式，填充进 richText 中的 anchor 标签
    func transformLinkToAnchor(_ from: NSAttributedString) -> NSMutableAttributedString {
        let toAttr = NSMutableAttributedString(attributedString: from)
        var rangeURLTurple: [(range: NSRange, url: String)] = []
        toAttr.enumerateAttribute(LinkTransformer.LinkAttributedKey, in: NSRange(location: 0, length: toAttr.length)) { (linkInfo, range, _) in
            guard let linkInfo: LinkTransformInfo = linkInfo as? LinkTransformInfo else { return }
            rangeURLTurple.append((range, linkInfo.url.absoluteString))
        }
        rangeURLTurple.reversed().forEach { turple in
            toAttr.removeAttribute(LinkTransformer.LinkAttributedKey, range: turple.range)
            toAttr.removeAttribute(LinkTransformer.TagAttributedKey, range: turple.range)
            toAttr.removeAttribute(.attachment, range: turple.range)
            let anchorInfo = AnchorTransformInfo(isCustom: false, scene: .copyPasteText, contentLength: turple.range.length)
            toAttr.addAttribute(AnchorTransformer.AnchorAttributedKey, value: anchorInfo, range: turple.range)
            toAttr.replaceCharacters(in: turple.range, with: turple.url)
        }
        return toAttr
    }
}

extension FocusStatusDescCell {
    enum Cons {
        static var maxTextCount: Int                { 400 }
        static var editViewTopMargin: CGFloat       { 8 }
        static var editViewTopHeight: CGFloat       { 160 }
        static var textViewTopMargin: CGFloat       { 12 }
        static var textViewBottomMargin: CGFloat    { -28 }
        static var clearBtnBotttomMargin: CGFloat   { -12 }
        static var clearBtnSideLength: CGFloat      { 14 }
        static var clearBtnRightMargin: CGFloat     { -12 }
        static var numberLabelRightMargin: CGFloat  { -10 }
        static var footerLabelTopMargin: CGFloat    { 6 }
        static var footerLabelBottomMargin: CGFloat { -14 }
        static var footerLabelMargin: CGFloat       { 12 }
        static var editViewCornerRadius: CGFloat    { 6 }
        static var editViewBorderWidth: CGFloat     { 1 }
        static var editViewNumberLabelFont: UIFont          { UIFont.systemFont(ofSize: 12) }
        static var editViewFooterLabelFont: UIFont          { UIFont.systemFont(ofSize: 14) }
        static var editViewNumberLabelTextColor: UIColor    { UIColor.ud.textPlaceholder }
        static var editViewClearBtnColor: UIColor           { UIColor.ud.iconN3 }
        static var editViewClearBtnHitTestArea: UIEdgeInsets { UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5) }
    }
}
