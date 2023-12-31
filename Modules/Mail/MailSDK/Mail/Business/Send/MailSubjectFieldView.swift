//
//  MailAddCoverView.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/4/26.
//

import UIKit
import SnapKit
import RxSwift
import UniverseDesignIcon
import UniverseDesignColor

class MailSubjectFieldView: UIView {
    static let minFieldHeight: CGFloat = 26
    static let maxFieldHeight: CGFloat = 112
    static let lineSpacing: CGFloat = 4
    static var maxTextHeight: CGFloat = {
        let lineHeight = UIFont.systemFont(ofSize: 16, weight: .medium).lineHeight + lineSpacing
        // 这里比较 tricky 地解决编辑态和非编辑态行数不同的问题
        return floor(maxFieldHeight / lineHeight) * lineHeight + 2
    }()
    
    let textView = CoverEditTextView(frame: .zero)
    private let placeholderLabel = UILabel(frame: .zero)

    private let disposeBag = DisposeBag()
    private let topSeparator = UIView(frame: .zero)
    private let bottomSeparator = UIView(frame: .zero)

    private lazy var priorityIcon: UIImageView = {
        let iconView = UIImageView()
        iconView.backgroundColor = .clear
        iconView.isHidden = true
        return iconView
    }()
    lazy var actionButton: UIButton = {
        let button = UIButton()
        let imageView = UIImageView()
        imageView.image = UDIcon.effectsOutlined.withRenderingMode(.alwaysTemplate).ud.withTintColor(UIColor.ud.iconN3)
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = false
        button.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }
        return button
    }()
    private let coverAction: () -> Void
    private var heightConstraint: Constraint?
    private var rightConstraint: Constraint?
    private var previousHeight: CGFloat = 0

    weak var delegate: UITextViewDelegate?
    private let coverEnable: Bool // 是否开启了封面功能
    private let priorityEnable: Bool // 是否开启了邮件重要程度功能

    init(frame: CGRect, coverEnable: Bool, priorityEnable: Bool, coverAction: @escaping () -> Void) {
        self.coverEnable = coverEnable
        self.priorityEnable = priorityEnable
        self.coverAction = coverAction
        super.init(frame: frame)
    #if swift(>=4.2)
        let notificationName = UITextView.textDidChangeNotification
    #else
        let notificationName = Notification.Name.UITextViewTextDidChange
    #endif
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: notificationName, object: nil)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func textDidChange() {
        if let text = self.text,
            text.contains("\n") {
            self.text = text.replacingOccurrences(of: "\n", with: " ")
        }
    }
    
    deinit {
      #if swift(>=4.2)
        let notificationName = UITextView.textDidChangeNotification
      #else
        let notificationName = Notification.Name.UITextViewTextDidChange
      #endif
        NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
    }

    override var accessibilityIdentifier: String? {
        get {
            return textView.accessibilityIdentifier
        }
        set {
            textView.accessibilityIdentifier = newValue
        }
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTextView()
    }

    var text: String? {
        get {
            return textView.attributedText?.string
        }
        set {
            let attrStr = NSAttributedString(string: newValue ?? "", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium), .foregroundColor: UIColor.ud.textTitle])
            textView.attributedText = attrStr
            layoutTextView()
        }
    }

    var placeHolder: String? {
        get {
            return placeholderLabel.text
        }
        set {
            placeholderLabel.text = newValue
        }
    }
    // 邮件优先级
    var mailPriority: MailPriorityType = .normal {
        didSet {
            switch mailPriority {
            case .normal, .unknownPriority:
                priorityIcon.isHidden = true
            case .high:
                priorityIcon.image = MailPriorityType.high.toIcon().ud.withTintColor(.ud.functionDangerContentDefault)
                priorityIcon.isHidden = false
            case .low:
                priorityIcon.image = MailPriorityType.low.toIcon().ud.withTintColor(.ud.iconN3)
                priorityIcon.isHidden = false
            @unknown default:
                mailAssertionFailure("Unknown MailPriorityType.")
            }
            layoutTextView()
        }
    }

    @objc
    private func onTextViewTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        delegate?.textViewDidBeginEditing?(textView)
        layoutTextView()
        textView.isEditable = true
        textView.becomeFirstResponder()
        textView.isScrollEnabled = true
        let touchPoint = gesture.location(in: textView)
        if let position = textView.closestPosition(to: touchPoint) {
            textView.selectedTextRange = textView.textRange(from: position, to: position)
        }
    }
}

extension MailSubjectFieldView: UITextViewDelegate, NSLayoutManagerDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewDidEndEditing?(textView)
        textView.isEditable = false
        textView.setContentOffset(.zero, animated: false)
        DispatchQueue.main.async {
            self.textView.isScrollEnabled = false
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        layoutTextView()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let ret = delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text){
            return ret
        }
        return true
    }

    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return Self.lineSpacing
    }
}

// MARK: - Setup Views
private extension MailSubjectFieldView {
    func setupViews() {
        backgroundColor = .ud.bgBody

        textView.isScrollEnabled = false
        textView.backgroundColor = .ud.bgBody
        textView.textColor = .ud.textTitle
        textView.font = .systemFont(ofSize: 16, weight: .medium)
        textView.delegate = self
        textView.autocorrectionType = .no
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
        textView.returnKeyType = .done
        textView.layoutManager.delegate = self
        textView.showsVerticalScrollIndicator = false
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.isEditable = false
        let textViewTap = UITapGestureRecognizer(target: self, action: #selector(onTextViewTap))
        textView.addGestureRecognizer(textViewTap)
        /// auto capital by sentences
        textView.autocapitalizationType = .sentences
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(16)
            rightConstraint = make.right.equalToSuperview().inset(coverEnable ? 48 : 16).constraint
            make.top.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
            heightConstraint = make.height.equalTo(Self.minFieldHeight).constraint
        }

        placeholderLabel.text = BundleI18n.MailSDK.Mail_Send_Subject
        placeholderLabel.textColor = .ud.textPlaceholder
        placeholderLabel.font = .systemFont(ofSize: 16, weight: .medium)
        textView.insertSubview(placeholderLabel, at: 0)
        placeholderLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-2)
            make.left.right.equalToSuperview()
        }

        if coverEnable {
            addSubview(actionButton)
            actionButton.snp.makeConstraints { make in
                make.width.height.equalTo(24)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-16)
            }
            actionButton.rx.throttleTap.subscribe {  [weak self] _ in
                self?.coverAction()
            }.disposed(by: disposeBag)
        }
        if priorityEnable {
            addSubview(priorityIcon)
            priorityIcon.snp.makeConstraints { make in
                make.right.equalTo(coverEnable ? -46 : -19)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 18, height: 18))
            }
        }

        topSeparator.backgroundColor = .ud.lineDividerDefault
        addSubview(topSeparator)
        topSeparator.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(0.4)
        }

        bottomSeparator.backgroundColor = .ud.lineDividerDefault
        addSubview(bottomSeparator)
        bottomSeparator.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(0.4)
        }
    }

    func layoutTextView() {
        placeholderLabel.isHidden = !textView.text.isEmpty
        if priorityEnable {
            var rightInset = coverEnable ? 48 : 16
            rightInset += priorityIcon.isHidden ? 0 : 24
            rightConstraint?.update(inset: rightInset)
        }
        let actualHeight = textView.sizeThatFits(textView.frame.size).height
        textView.isScrollEnabled = actualHeight >= Self.maxTextHeight
        heightConstraint?.update(offset: max(min(actualHeight, Self.maxTextHeight), Self.minFieldHeight))
    }
}
