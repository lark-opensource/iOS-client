//
//  MailCoverDisplayView.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/4/26.
//

import UIKit
import SnapKit
import RxSwift
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme

protocol MailCoverDisplayViewDelegate: AnyObject {
    func didTapRandomCover()
    func didTapEditCover(from view: UIView)
    func didTapReloadCover(_ cover: MailSubjectCover?)
    func focusNextInputView(currentView: UIView)
    func subjectViewChangeText()
    func registerTabKey(currentView: UIView)
    func unregisterTabKey(currentView: UIView)
    func isTitleHighlighted() -> Bool
}

extension MailCoverDisplayViewDelegate {
    func didTapRandomCover() {}
    func didTapEditCover(from view: UIView) {}
    func didTapReloadCover(_ cover: MailSubjectCover?) {}
}

class MailCoverDisplayView: UIView, MailTextViewCopyDelegate {
    enum LayoutTextType {
        case normal // 普通Text
        case customAttributeText // 富文本
        case attributeTextAndSubText // 上下分别富文本
    }

    private struct TextViewLayout {
        var heightConstraint: Constraint?
        var topInsetConstraint: Constraint?
        var bottomInsetConstraint: Constraint?
    }

    /// 封面初始化默认高度
    static let defaultCoverHeight = UIScreen.main.bounds.height * 0.16
    static let maxCoverHeight = UIScreen.main.bounds.height * 0.3 - verticalInset * 2
    static var maxTextHeight: CGFloat = {
        let lineHeight = textFont.lineHeight + lineSpacing
        return floor(maxCoverHeight / lineHeight) * lineHeight + 1
    }()
    private static let textFont = UIFont.systemFont(ofSize: 20, weight: .medium)
    private static let textLeftRightInset: CGFloat = 11
    private static let verticalInset: CGFloat = 36
    private static let lineSpacing: CGFloat = 6

    private let editButton = ExtendedTouchButton(frame: .zero)
    private let randomButton = ExtendedTouchButton(frame: .zero)
    private let imageView = UIImageView(frame: .zero)
    private let placeholderLabel = UILabel(frame: .zero)
    private let loadingTip = UILabel(frame: .zero)
    private let loadingIndicator = CoverLoadingIndicator(frame: CGRect(origin: .zero, size: CGSize(width: 16, height: 16)))
    private let priorityEnable: Bool
    private lazy var priorityIcon = UIImageView()
    private lazy var priorityTip = UILabel()
    private lazy var priorityView = UIView()

    private var didSetText = false
    private var delayClearImage = false
    private var textViewLayout = TextViewLayout()
    private var subTextViewLayout = TextViewLayout()
    ///
    private(set) var isTextFolding = false

    private var selectedCover: MailSubjectCover?

    private let disposeBag = DisposeBag()
    private let heightSubject = PublishSubject<CGFloat>()

    private var textViewAttributes: [NSAttributedString.Key: Any] = [
        .font: MailCoverDisplayView.textFont,
        .kern: -0.5,
        .foregroundColor: UIColor.white,
        .paragraphStyle: {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = MailCoverDisplayView.lineSpacing
            return paragraphStyle
        }()] {
            didSet {
                layoutTextView()
            }
        }

    private(set) var currentTextType = LayoutTextType.normal

    // MARK: - Public

    let textView = CoverEditTextView()

    /// 读信的翻译场景需要用到
    let subTextView = MailBaseTextView()

    var isEditable: Bool = true {
        didSet {
            textView.isEditable = isEditable
            editButton.isHidden = !isEditable
            randomButton.isHidden = !isEditable
            hideLoading(hidden: !isEditable)
            if !isEditable { // 读信场景
                loadingIndicator.snp.remakeConstraints { make in
                    make.height.width.equalTo(16)
                    make.left.equalToSuperview().inset(16)
                    make.centerY.equalTo(randomButton.snp.centerY)
                }
                loadingTip.snp.remakeConstraints { make in
                    make.left.equalTo(loadingIndicator.snp.right).offset(6)
                    make.height.equalTo(24)
                    make.bottom.equalToSuperview().inset(8)
                }
            }
        }
    }

    // 邮件优先级
    var mailPriority: MailPriorityType = .normal {
        didSet {
            switch mailPriority {
            case .normal, .unknownPriority:
                priorityView.isHidden = true
            case .high:
                priorityIcon.image = MailPriorityType.high.toIcon().ud.withTintColor(.ud.functionDangerContentDefault)
                priorityTip.text = MailPriorityType.high.toStatusText()
                priorityView.isHidden = false
            case .low:
                priorityIcon.image = MailPriorityType.low.toIcon().ud.withTintColor(.ud.primaryOnPrimaryFill)
                priorityTip.text = MailPriorityType.low.toStatusText()
                priorityView.isHidden = false
            @unknown default:
                mailAssertionFailure("Unknown MailPriorityType.")
            }
            layoutStatusView()
        }
    }

    /// On text view height changed
    lazy var heightChangedDriver = heightSubject.asDriver(onErrorJustReturn: .zero)

    weak var delegate: MailCoverDisplayViewDelegate?
    weak var copyDelegate: MailTextViewCopyDelegate?

    init(frame: CGRect, priorityEnable: Bool) {
        self.priorityEnable = priorityEnable
        super.init(frame: frame)
        self.setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTextView()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.selectedRange = NSRange(location: self.textView.text.utf16.count, length: 0)
        return textView.becomeFirstResponder()
    }

    func updateContent(_ text: String) {
        currentTextType = .normal
        didSetText = true
        textView.text = text
        layoutTextView()
    }

    /// 用于支持翻译和title同时存在
    /// - Parameter attribute: attribute description
    func updateContent(_ attribute: NSAttributedString) {
        currentTextType = .customAttributeText
        didSetText = true
        textView.attributedText = attribute
        layoutTextView()
    }

    /// 用于支持翻译和titile同时存在
    func updateContent(title: NSAttributedString, subTitle: NSAttributedString) {
        currentTextType = .attributeTextAndSubText
        didSetText = true
        textView.attributedText = title
        subTextView.attributedText = subTitle
        layoutTextView()
    }

    func updateCover(_ cover: UIImage?) {
        imageView.image = cover
    }
    
    func updateTextColor(_ textColor: UIColor) {
        // UX：MailReadTitleView addKeywordHighlight中对大搜文本进行高亮并将命中文字始终定义为N900(#1F2329), 因此这里不再更新文本颜色
        if let isHighlighted = delegate?.isTitleHighlighted(), isHighlighted {
            return
        }
        
        textView.textColor = textColor
        textView.tintColor = textColor
        textViewAttributes[.foregroundColor] = textColor
        placeholderLabel.textColor = textColor.withAlphaComponent(0.5)
    }

    func startLoading() {
        hideLoading(hidden: false)
        loadingTip.text = BundleI18n.MailSDK.Mail_Cover_MobileLoading
        loadingTip.textColor = .ud.textPlaceholder
        loadingTip.isUserInteractionEnabled = false
        loadingIndicator.tintColor = .ud.iconN3
        loadingIndicator.startAnimation()
        layoutStatusView()
    }

    func stopLoading() {
        hideLoading(hidden: true)
        loadingTip.text = ""
        loadingIndicator.stopAnimation()
        loadingTip.isUserInteractionEnabled = false
        layoutStatusView()
    }

    func loadFailed() {
        hideLoading(hidden: false)
        loadingTip.text = BundleI18n.MailSDK.Mail_Cover_MobileLoadAgain
        loadingTip.textColor = .ud.primaryContentDefault
        loadingTip.isUserInteractionEnabled = true
        loadingIndicator.tintColor = .ud.primaryContentDefault
        loadingIndicator.showRetryState()
        layoutStatusView()
    }

    func bind(viewModel: MailCoverDisplayViewModel) {
        bindViewModel(viewModel)
    }

    static func calcPreferredSize(width: CGFloat, text: NSAttributedString, subText: NSAttributedString?) -> CGSize {
        return culcLayoutWithContent(width: width, text: text, subText: subText)
    }

    @objc
    private func onEditTap() {
        delegate?.didTapEditCover(from: editButton)
    }

    @objc
    private func onRandomTap() {
        delegate?.didTapRandomCover()
    }

    @objc
    private func onReloadTap() {
        delegate?.didTapReloadCover(selectedCover)
    }

    @objc
    private func onTextViewTap(_ gesture: UITapGestureRecognizer) {
        guard isEditable, gesture.state == .ended else { return }
        layoutTextView()
        textView.isEditable = true
        textView.becomeFirstResponder()
        textView.isScrollEnabled = true
        let touchPoint = gesture.location(in: textView)
        if let position = textView.closestPosition(to: touchPoint) {
            textView.selectedTextRange = textView.textRange(from: position, to: position)
        }
    }

    func textViewDidCopy() {
        copyDelegate?.textViewDidCopy()
    }
}

// MARK: - UITextViewDelegate

extension MailCoverDisplayView: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.isEditable = false
        textView.setContentOffset(.zero, animated: false)
        DispatchQueue.main.async {
            self.textView.isScrollEnabled = false
        }
        delegate?.unregisterTabKey(currentView: self)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.registerTabKey(currentView: self)
    }

    func textViewDidChange(_ textView: UITextView) {
        didSetText = true
        layoutTextView()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let char = text.first, char.isNewline {
            delegate?.focusNextInputView(currentView: self)
            return false
        } else {
            delegate?.subjectViewChangeText()
            return true
        }
    }
}

// MARK: - Private
private extension MailCoverDisplayView {
    func bindViewModel(_ viewModel: MailCoverDisplayViewModel) {
        viewModel.coverStateDriver.drive(onNext: { [weak self] state in
            guard let self = self else { return }

            MailLogger.info("[Cover] Cover display view state update to: \(state)")

            switch state {
            case .none:
                self.selectedCover = nil
                self.stopLoading()
                self.updateCover(nil)
                self.updateTextColor(.ud.textTitle)
            case .loading(let cover):
                self.selectedCover = cover
                self.delayClearImage = true
                // 太快清掉上一个封面会导致闪烁一下，延迟清除
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) { [weak self] in
                    guard let self = self, self.delayClearImage else { return }
                    self.updateTextColor(.ud.textTitle)
                    self.delayClearImage = false
                    self.updateCover(nil)
                    self.startLoading()
                }
            case .loadFailed:
                self.loadFailed()
                self.updateCover(nil)
                self.updateTextColor(.ud.textTitle)
                InteractiveErrorRecorder.recordError(event: .mail_cover_load_error)
            case .thumbnail(let image):
                self.updateCover(image)
                self.delayClearImage = false
                if let textColor = self.selectedCover?.subjectColor {
                    self.updateTextColor(textColor)
                }
            case .cover(let image):
                self.stopLoading()
                self.updateCover(image)
                self.delayClearImage = false
                if let textColor = self.selectedCover?.subjectColor {
                    self.updateTextColor(textColor)
                }
            }
        }).disposed(by: disposeBag)
    }
}

private extension MailCoverDisplayView {
    func setupViews() {
        textView.copyDelegate = self
        subTextView.copyDelegate = self
        backgroundColor = .ud.lineBorderCard

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        //DM：给图片罩个蒙层
        let imgMaskView = UIView()
        imgMaskView.backgroundColor = UIColor.ud.fillImgMask
        imageView.addSubview(imgMaskView)
        imgMaskView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        textView.text = BundleI18n.MailSDK.Mail_Send_Subject
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        textView.returnKeyType = .done
        textView.showsVerticalScrollIndicator = false
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.delegate = self
        textView.font = MailCoverDisplayView.textFont
        textView.isEditable = false
        updateTextColor(.ud.textTitle)
        let textViewTap = UITapGestureRecognizer(target: self, action: #selector(onTextViewTap))
        textView.addGestureRecognizer(textViewTap)
        addSubview(textView)
        let lineHeight = textView.sizeThatFits(textView.frame.size).height
        textView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(MailCoverDisplayView.textLeftRightInset)
            textViewLayout.topInsetConstraint = make.top.equalToSuperview().constraint
            textViewLayout.bottomInsetConstraint = make.bottom.equalToSuperview().constraint
            textViewLayout.heightConstraint = make.height.equalTo(lineHeight).constraint
        }

        subTextView.isHidden = true
        subTextView.backgroundColor = .clear
        subTextView.textAlignment = .center
        subTextView.textContainer.lineBreakMode = .byTruncatingTail
        subTextView.font = MailCoverDisplayView.textFont
        subTextView.isEditable = false
        subTextView.isScrollEnabled = false
        addSubview(subTextView)
        subTextView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(MailCoverDisplayView.textLeftRightInset)
            subTextViewLayout.topInsetConstraint = make.top.equalToSuperview().constraint
            subTextViewLayout.bottomInsetConstraint = make.bottom.equalToSuperview().constraint
            subTextViewLayout.heightConstraint = make.height.equalTo(lineHeight).constraint
        }

        placeholderLabel.text = BundleI18n.MailSDK.Mail_Cover_MobileEnterSubject
        placeholderLabel.font = .systemFont(ofSize: 20, weight: .medium)
        insertSubview(placeholderLabel, belowSubview: textView)
        placeholderLabel.snp.makeConstraints { make in
            make.top.centerX.equalTo(textView)
        }

        editButton.setTitle(BundleI18n.MailSDK.Mail_Cover_MobileEditCover, for: .normal)
        editButton.setTitleColor(.ud.primaryOnPrimaryFill, for: .normal)
        editButton.backgroundColor = .ud.staticBlack.withAlphaComponent(0.4)
        editButton.layer.cornerRadius = 6
        editButton.titleLabel?.font = .systemFont(ofSize: 12)
        editButton.contentEdgeInsets = UIEdgeInsets(horizontal: 8, vertical: 0)
        editButton.extendedInsets = UIEdgeInsets(top: 0, left: -4, bottom: -12, right: -4)
        editButton.addTarget(self, action: #selector(onEditTap), for: .touchUpInside)
        editButton.layer.borderWidth = 0.5
        editButton.layer.borderColor = UIColor.white.cgColor
        addSubview(editButton)
        editButton.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.bottom.equalToSuperview().inset(8)
            make.right.equalToSuperview().inset(16)
        }

        randomButton.imageView?.tintColor = .white
        randomButton.imageView?.contentMode = .scaleAspectFit
        randomButton.setImage(UDIcon.replaceOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        randomButton.backgroundColor = .ud.staticBlack.withAlphaComponent(0.4)
        randomButton.layer.cornerRadius = 6
        randomButton.contentEdgeInsets = UIEdgeInsets(horizontal: 6, vertical: 5)
        randomButton.extendedInsets = UIEdgeInsets(top: 0, left: -4, bottom: -12, right: -4)
        randomButton.addTarget(self, action: #selector(onRandomTap), for: .touchUpInside)
        randomButton.layer.borderWidth = 0.5
        randomButton.layer.borderColor = UIColor.white.cgColor
        addSubview(randomButton)
        randomButton.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.centerY.equalTo(editButton.snp.centerY)
            make.right.equalTo(editButton.snp.left).inset(-8)
        }

        loadingTip.isUserInteractionEnabled = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(onReloadTap))
        loadingTip.addGestureRecognizer(tap)
        loadingTip.text = BundleI18n.MailSDK.Mail_Cover_MobileLoading
        loadingTip.textColor = .ud.textPlaceholder
        loadingTip.font = .systemFont(ofSize: 14)
        addSubview(loadingTip)
        loadingTip.snp.makeConstraints { make in
            make.right.equalTo(randomButton.snp.left).offset(-8)
            make.centerY.equalTo(randomButton.snp.centerY)
        }

        loadingIndicator.tintColor = .ud.iconN3
        addSubview(loadingIndicator)
        loadingIndicator.retryAction = { [weak self] in
            self?.onReloadTap()
        }
        loadingIndicator.snp.makeConstraints { make in
            make.height.width.equalTo(16)
            make.right.equalTo(loadingTip.snp.left).offset(-4)
            make.centerY.equalTo(loadingTip.snp.centerY)
        }

        if priorityEnable {
            priorityView.backgroundColor = .ud.staticBlack.withAlphaComponent(0.3)
            priorityView.layer.cornerRadius = 12
            addSubview(priorityView)
            priorityView.snp.makeConstraints { make in
                make.height.equalTo(24)
                make.centerY.equalTo(editButton.snp.centerY)
                make.left.equalTo(16)
                make.right.lessThanOrEqualTo(loadingIndicator.snp.left).offset(-8)
                make.width.greaterThanOrEqualTo(30)
            }

            priorityView.addSubview(priorityIcon)
            priorityIcon.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 12, height: 12))
                make.left.equalTo(6)
                make.centerY.equalToSuperview()
            }
            priorityTip.textColor = .ud.primaryOnPrimaryFill
            priorityTip.font = .systemFont(ofSize: 12)
            priorityView.addSubview(priorityTip)
            priorityTip.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(priorityIcon.snp.right).offset(2)
                make.right.equalTo(-10).priority(.low)
            }
        }
    }

    func layoutTextView() {
        if currentTextType == .normal {
            textView.textStorage.setAttributes(textViewAttributes, range: NSMakeRange(0, textView.text.count))
        }

        placeholderLabel.isHidden = !textView.text.isEmpty && textView.attributedText != nil
        var actualHeight: CGFloat = 0
        /// 有subTextView时要按比例计算
        if currentTextType == .attributeTextAndSubText {
            subTextView.isHidden = false

            actualHeight = textView.sizeThatFits(textView.frame.size).height
            let actualSubHeight = subTextView.sizeThatFits(subTextView.frame.size).height
            let actualTotalHeight = actualHeight + actualSubHeight
            let maxHeight = Self.maxTextHeight
            let lineHeight = textView.font?.lineHeight ?? 20
            var textHeight = 0.0
            var subTextHeight = 0.0
            if actualTotalHeight > Self.maxTextHeight {
                subTextHeight = maxHeight * actualSubHeight / actualTotalHeight
                subTextHeight = Self.calcPerfectTextViewHeight(defaultHeight: subTextHeight,
                                                               lineHeight: lineHeight) + Self.lineSpacing
                textHeight = Self.calcPerfectTextViewHeight(defaultHeight: maxHeight - subTextHeight,
                                                            lineHeight: lineHeight)
            } else {
                textHeight = actualHeight
                subTextHeight = actualSubHeight
            }

            isTextFolding = actualTotalHeight > Self.maxTextHeight

            let totalHeight = textHeight + subTextHeight
            let inset = floor(max(((Self.defaultCoverHeight - totalHeight) / 2), Self.verticalInset))

            textView.textContainerInset = .zero
            subTextView.textContainerInset = UIEdgeInsets(top: Self.lineSpacing, left: 0, bottom: 0, right:0)

            textViewLayout.heightConstraint?.update(offset: textHeight)
            textViewLayout.topInsetConstraint?.update(inset: inset)
            textViewLayout.bottomInsetConstraint?.isActive = false

            subTextViewLayout.heightConstraint?.update(offset: subTextHeight)
            subTextViewLayout.topInsetConstraint?.isActive = false
            subTextViewLayout.bottomInsetConstraint?.update(inset: inset)
        } else {
            subTextView.isHidden = true
            // 无内容时 TextView 光标是居中的，需要向左偏移到 placeholder 开始的地方
            let cursorInset = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: placeholderLabel.frame.width)
            let normalInset = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
            textView.textContainerInset = placeholderLabel.isHidden ? normalInset : cursorInset

            actualHeight = textView.sizeThatFits(textView.frame.size).height
            isTextFolding = actualHeight > Self.maxTextHeight
            let inset = floor(max(((Self.defaultCoverHeight - actualHeight) / 2), Self.verticalInset))
            textViewLayout.heightConstraint?.update(offset: min(actualHeight, Self.maxTextHeight))
            textViewLayout.topInsetConstraint?.update(inset: inset)
            textViewLayout.bottomInsetConstraint?.update(inset: inset - 1) // 确保够位置
            textViewLayout.bottomInsetConstraint?.isActive = true
        }

        var oldAlignment = textView.textAlignment
        // 仅一行内容时需居中显示
        if actualHeight > (textView.font?.lineHeight ?? 20) * 1.5 {
            textView.textAlignment = .natural
            subTextView.textAlignment = .natural
        } else {
            textView.textAlignment = .center
            subTextView.textAlignment = .center
        }

        if textView.textAlignment != oldAlignment {
            updateAlignmentAttribute()
        }

        // TextView 会设置默认字符保证初始高度正确
        if !didSetText {
            textView.text = ""
        }
        heightSubject.onNext(frame.height)
    }

    func layoutStatusView() {
        guard priorityEnable && priorityView.isHidden == false else { return }
        // 所有 inset & button width：16 + 8 + 24 + 8 + 20 + 8 + 16 = 100
        let priorityViewWidth = self.frame.width - editButton.sizeThatFits(editButton.frame.size).width - loadingTip.sizeThatFits(loadingTip.frame.size).width - 100
        // 不够显示优先级文字时只显示图标
        // 排除一下初始化的情况
        if self.frame.width > 0 && priorityViewWidth <= 30 {
            priorityView.snp.makeConstraints { make in
                make.width.equalTo(24)
            }
            priorityTip.isHidden = true
        } else if priorityTip.isHidden == true { // 过滤一层，如果没变化就不用 remake
            priorityView.snp.remakeConstraints { make in
                make.height.equalTo(24)
                make.centerY.equalTo(editButton.snp.centerY)
                make.left.equalTo(16)
                make.right.lessThanOrEqualTo(loadingIndicator.snp.left).offset(-8)
                make.width.greaterThanOrEqualTo(30)
            }
            priorityTip.isHidden = false
        }
    }

    func updateAlignmentAttribute() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textView.textAlignment
        paragraphStyle.lineSpacing = MailCoverDisplayView.lineSpacing
        textViewAttributes[.paragraphStyle] = paragraphStyle
    }

    func hideLoading(hidden: Bool) {
        loadingTip.isHidden = hidden
        loadingIndicator.isHidden = hidden
    }

    static func culcLayoutWithContent(width: CGFloat,
                                      text: NSAttributedString,
                                      subText: NSAttributedString?) -> CGSize {
        var text = text
        if let subText = subText { // 有翻译的情况
            let temp = NSMutableAttributedString(attributedString: text)
            temp.append(NSAttributedString(string: "\n"))
            temp.append(subText)
            text = temp
        }

        let textWidth = width - MailCoverDisplayView.textLeftRightInset * 2 - 2 * 5.0 // 5.0是textView的lineframepadding
        let actualHeight = ceil(text.boundingRect(with: CGSize(width: textWidth,
                                                          height: MailCoverDisplayView.maxTextHeight),
                                             options: .usesLineFragmentOrigin,
                                             context: nil).height) + 1 // 因为textview有inset，实际会多1
        let textHeight = min(actualHeight, Self.maxTextHeight)
        let inset = floor(max(((defaultCoverHeight - textHeight) / 2), verticalInset))
        let bottomInset = max(inset, verticalInset)
        return CGSize(width: width, height: textHeight + inset + bottomInset)
    }

    private static func calcPerfectTextViewHeight(defaultHeight: CGFloat,
                                                  lineHeight defatultLineHeight: CGFloat) -> CGFloat {
        var height = defaultHeight
        let lineHeight = ceil(defatultLineHeight)
        // 多行
        if defaultHeight > lineHeight * 1.5 {
            height = height - lineHeight //减去第一行
            let other = floor(height / (lineHeight + lineSpacing)) * (lineHeight + lineSpacing)
            height = lineHeight + other
        } else {
            // 单行
            height = lineHeight
        }
        return ceil(height)
    }
}
