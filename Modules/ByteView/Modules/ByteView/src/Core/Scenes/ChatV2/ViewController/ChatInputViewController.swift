//
//  ChatInputViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/4/24.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import ByteViewTracker
import UniverseDesignIcon

protocol ChatInputViewControllerDelegate: AnyObject {
    func chatInputViewDidPressReturnKey(text: String)
    func chatInputViewTextDidChange(to text: String)
}

final class ChatInputViewController: BaseViewController, UITextViewDelegate {
    private var shouldUpdateFrame = false
    private var maxLine = Display.phone ? 4 : 2
    private var maxHeight: CGFloat { Layout.lineHeight * CGFloat(maxLine) }
    weak var delegate: ChatInputViewControllerDelegate?
    private var isInsideObserver = false
    private var contentSizeObservation: NSKeyValueObservation?
    var allowInput: Bool = true

    private enum Layout {
        static let fontSize: CGFloat = 16
        static let lineHeight: CGFloat = 22
        static let textViewPadding: CGFloat = 8
        static let textVerticalInset: CGFloat = 11
        static let inputViewMinHeight: CGFloat = 44
    }

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    private var textBorderView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10
        return view
    }()

    private(set) lazy var textView: UITextView = {
        let view = UITextView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.textColor = UIColor.ud.textTitle

        view.isEditable = true
        view.isSelectable = true
        view.isScrollEnabled = false
        view.layoutManager.allowsNonContiguousLayout = false
        view.alwaysBounceHorizontal = false
        view.enablesReturnKeyAutomatically = true
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)

        view.dataDetectorTypes = UIDataDetectorTypes.all
        view.keyboardAppearance = .default
        view.keyboardType = .default
        view.returnKeyType = .send
        view.textAlignment = .left

        view.textContainerInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        view.delegate = self

        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = Layout.lineHeight
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.lineBreakMode = .byWordWrapping
        let font = UIFont.systemFont(ofSize: Layout.fontSize, weight: .regular)
        let offset = (lineHeight - font.lineHeight) / 4.0
        view.typingAttributes = [.paragraphStyle: style, .baselineOffset: offset, .font: font, .foregroundColor: UIColor.ud.textTitle]
        return view
    }()

    private(set) lazy var placeHolderLabel: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.ud.textPlaceholder
        return view
    }()

    deinit {
        contentSizeObservation?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    // MARK: - Public

    func clearText() {
        setText("")
    }

    func setText(_ text: String) {
        guard text != textView.text else { return }
        textView.text = text
        textView.invalidateIntrinsicContentSize()
        textViewDidChange(textView)
    }

    func endEditing() {
        textView.resignFirstResponder()
    }

    func setPlaceholder(_ placeholder: String, color: UIColor? = nil) {
        if let color = color {
            placeHolderLabel.attributedText = NSAttributedString(string: placeholder, config: .body)
            placeHolderLabel.textColor = color
        } else {
            placeHolderLabel.attributedText = NSAttributedString(string: placeholder, config: .body)
            placeHolderLabel.textColor = UIColor.ud.textPlaceholder
        }
    }

    func updateMaxLine(_ maxLine: Int) {
        self.maxLine = maxLine
        // 键盘没显示时，此页面也会存在于 FloatingInteractionVC 里，此时直接调整约束会使得自动调整高度功能失效，
        // 因此这里暂时先记录有更新，直到键盘将要弹起时才实际更新约束，并触发 contentSize 变化
        shouldUpdateFrame = true
    }

    // 疑似 iOS 系统问题，锁定重力感应，冷启动 app，入会点击旋转屏幕按钮，然后唤起横屏 toolbar，在聊天输入框中长按出来的 menu 反向不对
    // 下面方法可以强行让系统纠正 menuController 的方向。加在 performWithoutAnimation block 中是为了防止影响其他动画
    func fixMenuOrientation() {
        UIView.performWithoutAnimation {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    // MARK: - Private

    private func setupSubviews() {
        view.backgroundColor = .clear

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.addSubview(textBorderView)
        textBorderView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.textViewPadding)
        }

        textBorderView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Layout.textVerticalInset)
            make.height.greaterThanOrEqualTo(Layout.lineHeight)
            make.height.lessThanOrEqualTo(maxHeight)
        }

        textView.addSubview(placeHolderLabel)
        placeHolderLabel.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(12)
            maker.center.equalToSuperview()
        }

        contentSizeObservation = textView.observe(\.contentSize, options: [.new, .old]) { [weak self] (_, change) in
            self?.handleTextViewContentSizeChange(change)
        }
    }

    // MARK: - Actions

    private func handleTextViewContentSizeChange(_ change: NSKeyValueObservedChange<CGSize>) {
        guard !isInsideObserver else { return }
        isInsideObserver = true
        defer { isInsideObserver = false }
        guard let newSize = change.newValue else { return }
        textView.isScrollEnabled = newSize.height >= maxHeight
        textView.setNeedsUpdateConstraints()
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard allowInput else { return false}
        if shouldUpdateFrame {
            shouldUpdateFrame = false
            textView.snp.updateConstraints { make in
                make.height.lessThanOrEqualTo(maxHeight)
            }
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        placeHolderLabel.isHidden = textView.text.isEmpty == false
        delegate?.chatInputViewTextDidChange(to: textView.text)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            delegate?.chatInputViewDidPressReturnKey(text: textView.text)
            return false
        }
        return true
    }
}
