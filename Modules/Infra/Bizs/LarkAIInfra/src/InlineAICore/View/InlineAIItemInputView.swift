//
//  InlineAIItemInputView.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/4/25.
//  


import UIKit
import SnapKit
import UniverseDesignInput
import UniverseDesignColor
import UniverseDesignIcon
import LarkFoundation
import LarkKeyboardKit
import RxSwift
import RxCocoa
import EditTextView
import LarkBaseKeyboard
import LarkModel
import TangramService


class InlineTextView: LarkEditTextView {
    
    var minHeight: CGFloat = 36
    
    var disposeBag = DisposeBag()

    var keyboardEventChangeCallback: ((KeyboardEvent) -> Void)?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        KeyboardKit.shared.keyboardEventChange.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            if event.type == .willShow, !self.isFirstResponder {
                return
            }
            self.keyboardEventChangeCallback?(event)
        }).disposed(by: disposeBag)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        let rect = super.caretRect(for: position)
        if self.text.isEmpty {
            return CGRect(origin: .init(x: rect.origin.x, y: rect.origin.y + 1), size: .init(width: rect.width, height: rect.height + 1))
        } else {
            return rect
        }
    }
}

final class InlineAIItemInputView: InlineAIItemBaseView, KeyboardAtRouteProtocol {
    
    var model: InlineAIPanelModel.Input?

    var urlPreviewAPI: URLPreviewAPI?
    
    var inlineUrlInputHandler: InlineAIURLInputHandler?
    
    /// 点击 @ 的用户回调，参数为userID
    var didClickMentionedUser: ((String) -> Void)?
    
    var textViewInputProtocolSet = TextViewInputProtocolSet() {
        didSet {
            textViewInputProtocolSet.register(textView: textView)
        }
    }
    // 用于解决初次打开焦点丢失问题
    private lazy var tempTextView: UITextView = {
        let tempView = UITextView()
        tempView.backgroundColor = UDColor.bgFiller
        tempView.returnKeyType = .send
        tempView.enablesReturnKeyAutomatically = true
        tempView.delegate = self
        tempView.textColor = .clear
        tempView.font = UIFont.systemFont(ofSize: 16)
        tempView.isHidden = true
        return tempView
    }()
    
    lazy var mentionParser = AIMentionParser()

    var parseEnable = false

    private lazy var textView: InlineTextView = {
        let ttView = InlineTextView()
        self.setSupportAtForTextView(ttView)
        ttView.defaultTypingAttributes = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: Metric.defaultTextColor
        ]
        ttView.isScrollEnabled = false
        ttView.maxHeight = Metric.textMaxHeight
        ttView.textDragInteraction?.isEnabled = false
        ttView.backgroundColor = UDColor.bgFiller
        ttView.placeholderTextColor = UDColor.iconN3
        ttView.font = UIFont.systemFont(ofSize: 16)
        ttView.placeholderTextView.font = UIFont.systemFont(ofSize: 16)
        ttView.enablesReturnKeyAutomatically = true
        ttView.delegate = self
        ttView.returnKeyType = .send
        ttView.interactionHandler = CustomTextViewInteractionHandler()
        ttView.placeholderTextView.contentInset = .init(top: 2, left: 0, bottom: 0, right: 0)
        ttView.contentInset = .init(top: -1, left: 0, bottom: 0, right: 0)
        return ttView
    }()

    private lazy var aiLottieIconView = AIAnimationView()
    
    ///button
    enum ButtonType: String {
        case at
        case stop
        case `default`
        case none
    }
    
    var supportAt: Bool = false {
        didSet {
            if supportAt {
                defaultButton = atButton
            }
        }
    }
    
    let rightButtonView = UIView()
    
    var buttonType: ButtonType = .none {
        didSet {
            if oldValue == buttonType { return }
            let buttonSize: CGSize = buttonType == .none ? .zero : Metric.buttonSize
            let offset: CGFloat = buttonType == .none ? -12 : .zero
            rightButtonView.snp.updateConstraints { make in
                make.size.equalTo(buttonSize)
            }
            textView.snp.updateConstraints { make in
                make.right.equalTo(rightButtonView.snp.left).offset(offset)
            }
            stopButton.isHidden = true
            atButton.isHidden = true
            switch buttonType {
            case .at:
                atButton.isHidden = false
            case .stop:
                stopButton.isHidden = false
            case .`default`:
                defaultButton?.isHidden = false
            case .none:
                break
            }
        }
    }
    var defaultButton: UIButton?
    let stopButton = UIButton()
    let atButton = UIButton()
    
    let disposeBag = DisposeBag()
    private let containerView = UIView()
    var preCacheHeight: CGFloat = Metric.textMinHeight
    
    struct Metric {
        static let defaultTextColor = UDColor.textTitle
        static let textMaxHeight: CGFloat = 78
        static let textMinHeight: CGFloat = 34
        static let textLeftMargin: CGFloat = 2
        static let textTopMargin: CGFloat = 8
        static let contanerTopMargin: CGFloat = 0
        static let textBottomMargin: CGFloat = 6
        static let buttonSize: CGSize = CGSize(width: 24, height: 44)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
        bindText()
    }
    
    func setupInit() {
        layer.cornerRadius = 8
        
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        containerView.backgroundColor = UDColor.bgFiller
        addSubview(containerView)

        containerView.addSubview(aiLottieIconView)
        containerView.addSubview(textView)
        
        containerView.addSubview(rightButtonView)
        stopButton.setImage(UDIcon.getIconByKey(.stopOutlined, iconColor: UDColor.iconN3, size: CGSize(width: 18, height: 18)), for: .normal)
        stopButton.addTarget(self, action: #selector(stopAction), for: .touchUpInside)
        atButton.setImage(UDIcon.getIconByKey(.atOutlined, iconColor: UDColor.iconN3, size: CGSize(width: 18, height: 18)), for: .normal)
        atButton.addTarget(self, action: #selector(atAction), for: .touchUpInside)
        rightButtonView.addSubview(stopButton)
        rightButtonView.addSubview(atButton)
        
        textView.keyboardEventChangeCallback = { [weak self] event in
            guard let self = self, self.didPresent else { return }
            self.eventRelay.accept(.keyboardEventChange(event: event))
            if event.type == .didShow,
               self.tempTextView.isFirstResponder {
                LarkInlineAILogger.info("[text] exchange firstResponder")
                self.textView.becomeFirstResponder()
                let range = InlineAiInputTransformer.findPreferredSelectedRange(for: self.textView.attributedText)
                self.textView.selectedRange = range
                self.tempTextView.isHidden = true
            }
        }
        self.addSubview(tempTextView)
    }
    
    func bindText() {
        textView.rx.text
                   .orEmpty
                   .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
                   .distinctUntilChanged()
                   .subscribe(onNext: { [weak self] _ in
                       guard let self = self, self.textView.isUserInteractionEnabled else { return }
                       self.textChange()
                   }).disposed(by: disposeBag)

        textView.rx.didBeginEditing
                   .subscribe(onNext: { [weak self] _ in
                       self?.eventRelay.accept(.textViewDidBeginEditing)
                   }).disposed(by: disposeBag)

        textView.rx.didEndEditing
                   .subscribe(onNext: { [weak self] _ in
                       self?.eventRelay.accept(.textViewDidEndEditing)
                   }).disposed(by: disposeBag)
    }
    
    func textChange(checkIsFirstResponder: Bool = true, emitHeightChange: Bool = true) {
        let markedTextIsNil = self.textView.markedTextRange == nil
        if (markedTextIsNil && self.textView.isFirstResponder) || !checkIsFirstResponder {
            self.eventRelay.accept(.textViewDidChange(text: self.textView.text))
        }
        updateTextHeight(emitHeightChange: emitHeightChange)
    }
    
    func updateTextHeight(emitHeightChange: Bool = true) {
        let height = self.caculateTextHeight()
        if self.preCacheHeight != height {
            self.preCacheHeight = height
            if emitHeightChange {
                self.eventRelay.accept(.textViewHeightChange)
            }
        }
    }

    func caculateTextHeight() -> CGFloat {
        let width = self.bounds.width
        let minHeight: CGFloat = 20
        guard width > minHeight else {
            return Metric.textMinHeight
        }
        if textView.frame.size.width < minHeight {
            self.layoutIfNeeded()
        }
        let textViewWidth = textView.frame.size.width
        guard textViewWidth > minHeight else {
            return Metric.textMinHeight
        }
        let textViewContentViewWidth = textViewWidth - (textView.contentInset.left + textView.contentInset.right)
        let sizeThatFits: CGSize
        let limitSize = CGSize(width: textViewContentViewWidth, height: Metric.textMaxHeight)

        var sizeFitTextView: UITextView = self.textView
        if self.textView.text.isEmpty, !self.textView.placeholderTextView.text.isEmpty {
            sizeFitTextView = self.textView.placeholderTextView
        }
        if #available(iOS 14.0, *) {
           if Utils.isiOSAppOnMac {
               sizeThatFits = sizeFitTextView.contentSize
           } else {
               sizeThatFits = sizeFitTextView.sizeThatFits(limitSize)
           }
        } else {
           sizeThatFits = sizeFitTextView.sizeThatFits(limitSize)
        }
        var textHeight = sizeThatFits.height
        let line = sizeFitTextView.numberOfLines()
        
        if line <= 1 {
            textHeight = Metric.textMinHeight
        } else {
            textHeight = max(min(textHeight, Metric.textMaxHeight), Metric.textMinHeight)
        }
        self.textView.isScrollEnabled = line >= 4
        self.textView.showsVerticalScrollIndicator = self.textView.isScrollEnabled
        textView.snp.updateConstraints { make in
            make.height.equalTo(textHeight).priority(.required)
        }
        LarkInlineAILogger.info("[text] textContent height: \(textHeight) line:\(line)")
        return textHeight
    }
    
    @objc
    func stopAction() {
        eventRelay.accept(.stopGenerating)
    }
    
    @objc
    func atAction() {
        if !textView.isFirstResponder {
            let range = InlineAiInputTransformer.findPreferredSelectedRange(for: textView.attributedText)
            textView.selectedRange = range
        }
        let insertRange = textView.selectedRange
        let atStr = NSAttributedString(string: "@", attributes: textView.defaultTypingAttributes)
        self.insertAttr(atStr, at: insertRange)
        textView.resignFirstResponder()
        self.textChange(checkIsFirstResponder: false)
        eventRelay.accept(.clickAt(selectedRange: insertRange))
    }
    
    func setupLayout() {
        containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(Metric.contanerTopMargin)
        }
        
        aiLottieIconView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 24))
            make.left.equalToSuperview().inset(10)
            make.top.equalToSuperview().inset(12)
        }
        
        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Metric.textTopMargin)
            make.bottom.equalToSuperview().inset(Metric.textBottomMargin)
            make.right.equalTo(rightButtonView.snp.left)
            make.left.equalTo(aiLottieIconView.snp.right).offset(Metric.textLeftMargin)
            make.height.equalTo(Metric.textMinHeight)
        }
        textView.setContentHuggingPriority(.required + 1, for: .vertical)
        textView.setContentCompressionResistancePriority(.required + 1, for: .vertical)
        
        rightButtonView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(Metric.buttonSize)
            make.top.equalTo(aiLottieIconView)
        }
        
        atButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 24, height: 24))
            make.right.equalToSuperview()
        }
        
        stopButton.snp.makeConstraints { make in
            make.edges.equalTo(atButton)
        }
        
        tempTextView.snp.makeConstraints { make in
            make.edges.equalTo(textView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getDisplayHeight() -> CGFloat {
      let height = Metric.contanerTopMargin + Metric.textTopMargin + preCacheHeight + Metric.textBottomMargin
      return height
    }
    
    func getText() -> String? {
      return textView.text
    }
    
    var workItem: DispatchWorkItem?

    func update(model: InlineAIPanelModel.Input, fullRoundedcorners: Bool ) {
        self.model = model
        update(fullRoundedcorners: fullRoundedcorners)
        if model.showStopBtn {
            buttonType = .stop
        } else {
            buttonType = .default
        }
        if model.status == 0 {
            aiLottieIconView.stop()
        } else {
            aiLottieIconView.play()
        }
        refreshTextViewUI(with: model)
        activateKeybaord(with: model)
        resizePlacehoder(with: model)
    }

    func updateContainerBackgroundColor(_ color: UIColor) {
        containerView.backgroundColor = color
    }
    
    func updateTextviewBackgroundColor(_ color: UIColor) {
        textView.backgroundColor = color
    }
    
    private func refreshTextViewUI(with model: InlineAIPanelModel.Input) {
        let placehoderSelected = model.placehoderSelected ?? false
        textView.enablesReturnKeyAutomatically = (model.recentPrompt == nil && !placehoderSelected)
        textView.isUserInteractionEnabled = !model.showStopBtn && model.status == 0
        tempTextView.isUserInteractionEnabled = textView.isUserInteractionEnabled
        let loading = model.status == 1
        if loading, !model.writingText.isEmpty {
            textView.placeholder = model.writingText
            textView.placeholderTextView.textColor = UDColor.textCaption
        } else {
            if let textAttr = parseLinkText(text: model.placeholder) {
                textView.placeholder = textAttr.string
            } else {
                textView.placeholder = model.placeholder
            }
            textView.placeholderTextView.textColor = UDColor.iconN3
        }

        if !placehoderSelected,
           let details = model.textContentList,
           self.textView.text.isEmpty {
            self.textView.attributedText = InlineAiInputTransformer.transformContentToString(quickAction: details, attributes: self.textView.defaultTypingAttributes)
        } else if !model.text.isEmpty, textView.text.isEmpty {
            if let textAttr = parseLinkText(text: model.text) {
                self.textView.attributedText = textAttr
                self.tempTextView.attributedText = textAttr
            } else {
                self.textView.text = model.text
                self.tempTextView.text = model.text
            }
            LarkInlineAILogger.info("[text] show text")
        } else if let attributedString = model.attributedString?.value,
                  !attributedString.string.isEmpty,
                  textView.text.isEmpty {
            self.textView.attributedText = attributedString
            self.tempTextView.attributedText = attributedString
            LarkInlineAILogger.info("[text] show attributedString")
        }
        
        if loading { // 兜底，loading中不显示实体文字
            self.textView.text = ""
            self.textView.attributedText = .init(string: "")
        }
    }
    
    func parseLinkText(text: String) -> NSAttributedString? {
        if parseEnable {
            return mentionParser.parseLinkText(text: text, typingAttributes: textView.defaultTypingAttributes)
        } else {
            return nil
        }
    }

    private func activateKeybaord(with model: InlineAIPanelModel.Input) {
        // 要等VC动画完成再激活，否则键盘动画会失效，以及设置UI会有奇怪的问题
        if model.showKeyboard == true, !self.textView.isFirstResponder, !model.showStopBtn {
            LarkInlineAILogger.info("[text] showKeyboard")
            workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.tempTextView.isHidden == false {
                    LarkInlineAILogger.info("[text] auto active temp textView")
                    self.tempTextView.becomeFirstResponder()
                } else {
                    LarkInlineAILogger.info("[text] auto active real textView")
                    let preferredSelectedRange = InlineAiInputTransformer.findPreferredSelectedRange(for: self.textView.attributedText)
                    self.textView.becomeFirstResponder()
                    self.textView.selectedRange = preferredSelectedRange
                }
                self.eventRelay.accept(.autoActiveKeyboard)
                self.workItem = nil
            }
            if didPresent {
                workItem?.perform()
                workItem?.cancel()
            }
        } else if model.showKeyboard == false {
            self.tempTextView.resignFirstResponder()
            self.textView.resignFirstResponder()
            workItem?.cancel()
            workItem = nil
        }
    }
    
    private func resizePlacehoder(with model: InlineAIPanelModel.Input) {
        if self.textView.text.isEmpty,
           !self.textView.placeholderTextView.text.isEmpty {
            self.updateTextHeight(emitHeightChange: false)
        }
    }

    func update(fullRoundedcorners: Bool ) {
        if fullRoundedcorners {
            layer.maskedCorners = .all
        } else {
            layer.maskedCorners = .bottom
        }
    }
    
    func resignInputFirstResponder() {
        if self.textView.isFirstResponder {
            self.textView.resignFirstResponder()
            LarkInlineAILogger.info("[text] resignFirstResponder")
        }
    }
    
    func clearTextView() {
        self.textView.text = ""
        self.tempTextView.text = ""
        LarkInlineAILogger.info("[text] clear text")
    }
    
    override func didPresentCompletion() {
        super.didPresentCompletion()
        if let item = workItem, !item.isCancelled {
            item.perform()
        }
    }
    
    override func didDismissCompletion() {
        super.didDismissCompletion()
        clearTextView()
//        self.tempTextView.isHidden = false
    }
}

extension InlineAIItemInputView: UITextViewDelegate {

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard let model = self.model, textView.text.isEmpty else {
            return true
        }
        if model.placehoderSelected == true {
            if var textContentList = model.textContentList {
                textContentList.paramDetails.indices.forEach({
                    if let content = textContentList.paramDetails[$0].content,
                       !content.isEmpty,
                       let attr = parseLinkText(text: content) {
                       textContentList.paramDetails[$0].updateRichContent(.init(attr))
                    }
                })
                self.textView.attributedText = InlineAiInputTransformer.transformContentToString(quickAction: textContentList, attributes: self.textView.defaultTypingAttributes)
                
            } else {
                if let textAttr = parseLinkText(text: model.placeholder) {
                    self.textView.attributedText = textAttr
                } else {
                    self.textView.text = model.placeholder
                }
            }
            DispatchQueue.main.async {
                self.textView.selectAll(nil)
            }
        }
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            LarkInlineAILogger.info("[text] keyboard did send count:\(textView.text.count)")
            var attrText: NSAttributedString = textView.attributedText
            let trimmText = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 最近指令发送
            if trimmText.isEmpty,
               textView.enablesReturnKeyAutomatically == false {
                if let recentPrompt = self.model?.recentPrompt {
                    LarkInlineAILogger.info("[text] send recent prompt")
                    self.textView.resignFirstResponder()
                    self.eventRelay.accept(.sendRecentPrompt(prompt: recentPrompt))
                    return false
                } else if let model = self.model, model.placehoderSelected == true {
                    if let textContentList = model.textContentList {
                        attrText = InlineAiInputTransformer.transformContentToString(quickAction: textContentList, attributes: self.textView.defaultTypingAttributes)
                    } else {
                        attrText = NSAttributedString(string: model.placeholder)
                    }
                }
            }
            let displayAttrText = attrText

            //去掉快捷指令的placeHolder
            attrText = QuickActionAttributeUtils.clipEmptyPlaceholders(from: attrText)
            attrText = RichTextTransformKit.preproccessSendAttributedStr(attrText)
            let richTextData: RichTextContent.DataType
            let parseResult = QuickActionAttributeUtils.parseQuickActionAndAttributes(from: displayAttrText)
            if let content = parseResult {
                var quickAction = InlineAIPanelModel.QuickAction(displayName: content.id, displayContent: textView.attributedText.string, paramDetails: [])
                for (key, value) in content.params {
                    var paramDetail = InlineAIPanelModel.ParamDetail(name: "", key: key, content: value.string)
                    let components = InlineAiInputTransformer.parseParamContents(attrStr: value)
                    paramDetail.updateComponents(components)
                    quickAction.paramDetails.append(paramDetail)
                }
                richTextData = .quickAction(quickAction)
            } else {
                let components = InlineAiInputTransformer.parseParamContents(attrStr: displayAttrText)
                richTextData = .freeInput(components: components)
            }
            self.textView.resignFirstResponder()
            eventRelay.accept(.keyboardDidSend(RichTextContent(data: richTextData, attributedString: displayAttrText)))
            self.textView.text = ""
            if let model = self.model {
                self.resizePlacehoder(with: model)
            }
            self.textChange(checkIsFirstResponder: false)
            return false
        } else {
            if text == "@" {
                self.textChange(checkIsFirstResponder: false)
            }
            return self.textViewInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        inlineUrlInputHandler?.textViewDidChangeSelection(textView)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.textViewInputProtocolSet.textViewDidChange(textView)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return self.textView(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction, onAtClick: didClickMentionedUser)
    }
}

extension InlineAIItemInputView {
    
    func configureInputHandler() {
        var inputs: [TextViewInputProtocol] = []
        let quickActionHandler = InlineAIQuickActionHandler()
        if supportAt {
            let urlInputHandler = InlineAIURLInputHandler(urlPreviewAPI: self.urlPreviewAPI)
            urlInputHandler.deleteAtTagBlock = { [weak self, weak quickActionHandler] (_, _, _) in
                guard let self else { return }
                quickActionHandler?.isDeleting = true
                self.textViewDidChange(self.textView)
            }
            self.inlineUrlInputHandler = urlInputHandler
            let atPickerInputHandler = AtPickerInputHandler { [weak self] (textView, range, _) in
                guard let self else { return }
                self.textView.resignFirstResponder()
                self.eventRelay.accept(.clickAt(selectedRange: range))
            }
            inputs.append(urlInputHandler)
            inputs.append(atPickerInputHandler)
            let atUserInputHandler = AtUserInputHandler()
            inputs.append(atUserInputHandler)
        }
        quickActionHandler.placeHolderChangedBlock = { [weak self] in
            self?.textChange()
        }
        inputs.append(quickActionHandler)
        self.textViewInputProtocolSet = TextViewInputProtocolSet(inputs)
    }
    
    /// 这里的range是插入的'@'字符所在的location
    func insertPickerItems(items: [PickerItem]?, with range: NSRange) {
        self.textView.becomeFirstResponder()
        let insertBlock = { [weak self] in
            //把光标落在插入的'@'字符之后，所以+1
            let preferredRange = NSRange(location: range.location + 1, length: 0)
            guard let self = self,
                  self.textView.textStorage.fullRange.contains(range),
                  self.textView.textStorage.fullRange.contains(preferredRange) else {
                LarkInlineAILogger.error("[InlineAI] insert picker item error: out of range")
                return
            }
            self.textView.becomeFirstResponder()
            self.textView.selectedRange = preferredRange
            guard let items = items else { return }
            
            var tempRange = preferredRange
            for item in items {
                var linkAttr = NSAttributedString()
                switch item.meta {
                case let .doc(docInfo):
                    if let title = docInfo.title,
                       let meta = docInfo.meta,
                       let url = URL(string: meta.url) {
                        let content: LinkTransformer.DocInsertContent = (title, meta.type, url, "")
                        linkAttr = LinkTransformer.transformToDocAttr(content, attributes: self.textView.defaultTypingAttributes)
                    } else {
                        LarkInlineAILogger.error("[InlineAI] preview url error: can't get docInfo")
                    }
                case let .wiki(wikiInfo):
                    if let title = wikiInfo.title,
                       let meta = wikiInfo.meta,
                       let url = URL(string: meta.url) {
                        let content: LinkTransformer.DocInsertContent = (title, meta.type, url, "")
                        linkAttr = LinkTransformer.transformToDocAttr(content, attributes: self.textView.defaultTypingAttributes)
                    } else {
                        LarkInlineAILogger.error("[InlineAI] preview url error: can't get wikiInfo")
                    }
                case let .chatter(chatterMeta): // PickerChatterMeta
                    let info = AtChatterInfo(id: chatterMeta.id,
                                             name: chatterMeta.name ?? "",
                                             isOuter: chatterMeta.isOuter ?? false,
                                             actualName: chatterMeta.localizedRealName ?? "")
                    linkAttr = AtTransformer.transformContentToString(info, style: [:], attributes: self.textView.defaultTypingAttributes)
                default:
                    break
                }
                let newAttr = NSMutableAttributedString(attributedString: linkAttr)
                newAttr.append(NSAttributedString(string: " "))
                linkAttr = newAttr // 追加一个空格避免粘连(例如`用户名`会比较明显)
                self.insertAttr(linkAttr, at: tempRange)
                tempRange.location += linkAttr.length
            }
            
            //删除之前添加的'@'字符
            self.textView.textStorage.deleteCharacters(in: NSRange(location: range.location, length: 1))
            let selectedRange = self.textView.selectedRange
            self.textView.selectedRange = NSRange(location: selectedRange.location - 1, length: selectedRange.length)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: insertBlock)
    }
    
    ///插入picker里选择的item标题并移动光标位置到标题后
    func insertAttr(_ attr: NSAttributedString, at range: NSRange) {
        let interactionHandler = self.textView.interactionHandler as? CustomTextViewInteractionHandler
        let mutableAttr = NSMutableAttributedString(attributedString: self.textView.attributedText ?? NSAttributedString())
        guard mutableAttr.fullRange.contains(range) else { return }
        if interactionHandler?.shouldChange?(range, attr) ?? true {
            mutableAttr.replaceCharacters(in: range, with: attr)
            self.textView.attributedText = mutableAttr
            self.textView.selectedRange = NSRange(location: range.location + attr.length, length: 0)
            interactionHandler?.didChange?()
        }
    }
}
