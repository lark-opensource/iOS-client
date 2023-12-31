//
//  AvatarAttributedTextEditView.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/11/13.
//

import UIKit
import UniverseDesignTag
import UniverseDesignIcon
import RxSwift
import EditTextView
import LarkContainer
import LarkEmotionKeyboard
import UniverseDesignPopover
import UniverseDesignShadow
import LarkEmotion
import LarkBaseKeyboard
import LarkExtensions

final class AvatarAttributedTextEditView: UIView, UITextViewDelegate, UITextPasteDelegate {
    private var disposeBag = DisposeBag()
    var textUpdate: ((NSAttributedString?) -> Void)?
    var emotionVC: SelectEmotionViewController?
    var shouldChangeText = true
    var selectedText: NSAttributedString {
        return self.textView.attributedText
    }
    lazy var textView: LarkEditTextView = {
        let textView = LarkEditTextView()
        textView.placeholder = BundleI18n.LarkChatSetting.Lark_Core_Mobile_CustomizedGroupAvatar_Placeholder
        textView.placeholderTextView.font = UIFont.systemFont(ofSize: 16)
        textView.placeholderTextView.textColor = UIColor.ud.textPlaceholder
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        textView.defaultTypingAttributes = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textTitle,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 2
                return paragraphStyle
            }()
        ]
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 6
        textView.maxHeight = 70
        textView.textContainer.maximumNumberOfLines = 2
        textView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        textView.delegate = self
        textView.pasteDelegate = self
        return textView
    }()

    lazy var textWrapperView = UIView()
    lazy var iconEditButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        let icon = UDIcon.getIconByKey(.emojiOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
        button.setImage(icon, for: .normal)
        button.addTarget(self, action: #selector(didTapIcon(_:)), for: .touchUpInside)
        return button
    }()

    let userResolver: UserResolver
    weak var fromVC: UIViewController?
    init(userResolver: UserResolver,
         fromVC: UIViewController,
         textUpdate: ((NSAttributedString?) -> Void)?) {
        self.userResolver = userResolver
        self.fromVC = fromVC
        self.textUpdate = textUpdate
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        self.backgroundColor = .clear
        self.addSubview(textWrapperView)
        textWrapperView.addSubview(textView)
        textWrapperView.addSubview(iconEditButton)

        textWrapperView.snp.makeConstraints { make in
            make.leading.trailing.top.bottom.equalToSuperview()
            make.height.equalTo(70)
        }
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconEditButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-6)
            make.trailing.equalToSuperview().offset(-8)
            make.top.leading.greaterThanOrEqualToSuperview()
        }
        addTextViewObserver()
    }

    func addTextViewObserver() {
        textView.rx.text.asDriver()
            .drive(onNext: { [weak self] (_) in
                guard let self = self else { return }
                /// 沿用原有的线上逻辑
                if let language = self.textView.textInputMode?.primaryLanguage, language == "zh-Hans" {
                    // 获取高亮部分
                    let selectedRange = self.textView.markedTextRange ?? UITextRange()
                    if self.textView.position(from: selectedRange.start, offset: 0) == nil {
                        self.textUpdate?(self.textView.attributedText)
                    }
                } else {
                    self.textUpdate?(self.textView.attributedText)
                }
            })
            .disposed(by: self.disposeBag)
    }

    @objc
    private func didTapIcon(_ sender: UIButton) {
        self.endEditing(true)

        let config: ReactionPanelConfig = ReactionPanelConfig(clickReactionBlock: { [weak self] reactionKey, _, _, _ in
            guard let self = self else { return }
            guard let icon = EmotionResouce.shared.imageBy(key: reactionKey) else {
                return
            }
            var size = icon.size
            let attachment = NSTextAttachment()
            attachment.image = icon
            var attributes: [NSAttributedString.Key: Any] = [:]
            let font = UIFont.systemFont(ofSize: 16)
            let height = font.pointSize * 1.3
            let width = icon.size.width * height / icon.size.height
            let descent = (height - font.ascender - font.descender) / 2
            size = CGSize(width: width, height: height)
            attachment.bounds = CGRect(origin: CGPoint(x: 0, y: -descent), size: size)

            let attachmentString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            let randomKeyEmoji = EmotionTransformer.attributeStrValueForKey(reactionKey)
            attributes[EmotionTransformer.EmojiAttributedKey] = randomKeyEmoji
            attachmentString.addAttributes(attributes, range: NSRange(location: 0, length: 1))
            // 插入到光标的位置
            let selectedRange = self.textView.selectedRange
            let attributedText = NSMutableAttributedString(attributedString: self.textView.attributedText)
            attributedText.insert(attachmentString, at: selectedRange.location)
            // 更新输入框展示内容
            self.textView.attributedText = attributedText
            self.updateTextView()
            self.emotionVC?.dismiss(animated: true)
        }, scene: .groupAvatar, filter: { group in
            group.type == .default
        })

        emotionVC = SelectEmotionViewController(sourceView: sender, reactionConfig: config)
        // 展示弹出窗口
        self.userResolver.navigator.present(emotionVC ?? UIViewController(),
                                            from: fromVC ?? UIViewController(),
                                            prepare: {
                                                if #available(iOS 15.0, *) {
                                                    $0.sheetPresentationController?.prefersGrabberVisible = true
                                                }
                                            })
    }

    /// textView delegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.textView.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
    }
    /// textView delegate
    func textViewDidEndEditing(_ textView: UITextView) {
        self.textView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
    }

    public func setAttributedText(_ attributedText: NSAttributedString) {
        self.textView.attributedText = attributedText.adjustAttributedStringFormat(fontSize: 16,
                                                                                   attr: [.foregroundColor: UIColor.ud.textTitle],
                                                                                   needBold: false,
                                                                                   emotionScale: 1.3)
    }

    func textViewDidChange(_ textView: UITextView) {
        updateTextView()
    }

    // 限制输入框14个字符
    func updateTextView() {
        let selectedRange = textView.selectedRange
        let cursorLocationEnd = (selectedRange.location + selectedRange.length == textView.text.utf16.count)
        if textView.markedTextRange == nil,
           let text = textView.attributedText,
           let filterText = filterText(text) {
            DispatchQueue.main.async { [weak self] in
                let selectRange = self?.textView.selectedRange
                self?.textView.attributedText = filterText
                // 如果发生了截断，光标挪到最后位置
                if (cursorLocationEnd && text.string.utf16.count != filterText.string.utf16.count) ||
                    (selectRange != nil && NSMaxRange(selectedRange) > filterText.length) {
                    self?.textView.selectedRange = NSRange(location: filterText.string.utf16.count, length: 0)
                } else if let selectRange = selectRange {
                    self?.textView.selectedRange = selectedRange
                }
            }
        }
    }

    func filterText(_ attributedText: NSAttributedString) -> NSAttributedString? {
        let newText = NSMutableAttributedString(string: "")
        // 允许首、尾有换行符
        let components = attributedText.splitAttributedStringByNewline()
        if components.count < 2 {
            newText.append(attributedText)
            // 取前14个字符
            return newText.subStrToCount(AvatarAttributedTextAnalyzer.maxCountOfCharacter)
        }
        newText.append(components[0])
        newText.append(NSAttributedString(string: "\n"))
        newText.append(components[1])
        // 取前两行数据&不超过14个字符的数据
        let result = newText.avatarCountInfo(cutCount: AvatarAttributedTextAnalyzer.maxCountOfCharacter)
        guard let cutRange = result.cutRange else { return nil }

        let prefixRange = NSRange(..<cutRange.upperBound, in: attributedText.string)
        let prefixSubstring = newText.attributedSubstring(from: prefixRange)
        return prefixSubstring
    }

    // 复制粘贴删除一下首位的换行符&空白
    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
        for textRange: UITextRange
    ) -> NSAttributedString {
        let muAttr = NSMutableAttributedString()
        itemStrings.forEach { attr in
            muAttr.append(attr)
        }
        return (muAttr as NSAttributedString).lf.trimmedAttributedString(set: CharacterSet.whitespacesAndNewlines)
    }
}

final class SelectEmotionViewController: UIViewController, UIGestureRecognizerDelegate {
    private var popoverTransition = UDPopoverTransition(sourceView: nil)
    private let reactionPanel: ReactionPanel
    private lazy var dimmingView = UIView()
    private lazy var containerView = UIView()
    private lazy var headerView = UIView()
    private lazy var topBar: UIView = {
        let view = UIView()
        view.snp.makeConstraints { make in
            make.height.equalTo(4)
            make.width.equalTo(40)
        }
        view.layer.cornerRadius = 2
        view.backgroundColor = .ud.lineBorderCard
        return view
    }()
    private var paneloffsetY: CGFloat = UIScreen.main.bounds.height
    let contentHeight = UIDevice.current.userInterfaceIdiom == .pad ? 618 : UIScreen.main.bounds.height * 0.7
    init(sourceView: UIView, reactionConfig: ReactionPanelConfig) {
        self.reactionPanel = ReactionPanel(config: reactionConfig)
        popoverTransition = UDPopoverTransition(
            sourceView: sourceView,
            permittedArrowDirections: .up
        )
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = popoverTransition
        self.preferredContentSize = CGSize(width: 375, height: 618)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(dimmingView)
        // 创建一个视图控制器来展示返回的视图
        view.addSubview(containerView)
        containerView.addSubview(headerView)
        containerView.addSubview(reactionPanel)
        dimmingView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(headerView.snp.top)
        }
        containerView.snp.makeConstraints { make in
            make.height.equalTo(contentHeight)
            make.bottom.leading.trailing.equalToSuperview()
        }
        headerView.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(reactionPanel.snp.top)
        }
        reactionPanel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView(_:))))
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.layer.cornerRadius = 10
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        if UIDevice.current.userInterfaceIdiom == .phone {
            // 添加把手提示可拖动 preferGabberVisible
            headerView.addSubview(topBar)
            topBar.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.centerX.equalToSuperview()
            }
            // header部分添加可拖动手势
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleHeaderPanGesture(_:)))
            headerView.addGestureRecognizer(panGesture)
        } else {
            // 设置ipad上箭头的颜色
            self.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
        }
    }

    @objc
    private func didTapBackgroundView(_ gesture: UITapGestureRecognizer) {
        dismiss(animated: true)
    }

    @objc
    private func handleHeaderPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            paneloffsetY = reactionPanel.collection.contentOffset.y
        case .changed:
            let changeY = gestureRecognizer.translation(in: containerView).y - paneloffsetY
            if changeY > 0, reactionPanel.collection.contentOffset.y == 0 {
                changePanelHeight(changeY: changeY, state: gestureRecognizer.state)
            }
        case .ended:
            let changeY = gestureRecognizer.translation(in: containerView).y - paneloffsetY
            changePanelHeight(changeY: changeY, state: gestureRecognizer.state)
            // 重制为默认值
            paneloffsetY = UIScreen.main.bounds.height
        default:
            break
        }
    }

    func changePanelHeight(changeY: CGFloat, state: UIGestureRecognizer.State) {
        switch state {
        case .changed:
            self.view.transform = CGAffineTransform(translationX: 0, y: changeY)
        case .ended:
            if changeY / (self.view.bounds.height / 2) > 0.2 {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                    // 动画的具体操作
                    self?.view.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
                }) { [weak self] _ in
                    self?.dismiss(animated: false)
                }
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) { [weak self] in
                    self?.view.transform = CGAffineTransform(translationX: 0, y: 0)
                }
            }
        default:
            break
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
