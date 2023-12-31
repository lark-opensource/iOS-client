//
//  TranslationInfoPreviewView.swift
//  LarkChat
//
//  Created by liluobin on 2022/3/22.
//

import UIKit
import Foundation
import LarkUIKit
import RichLabel
import SwiftUI
import RustPB
import UniverseDesignIcon
import LKRichView

// 使用/关闭 按键
private var contentLineHeight: CGFloat = 22
private final class OperationView: UIView {
    fileprivate enum Status {
        case apply
        case close
        case recall
    }
    fileprivate var status: OperationView.Status = .close {
        didSet {
            switch status {
            case .apply:
                applyView.isHidden = false
                closeButton.isHidden = true
                recallButton.isHidden = true
            case .close:
                applyView.isHidden = true
                closeButton.isHidden = false
                recallButton.isHidden = true
            case .recall:
                applyView.isHidden = true
                closeButton.isHidden = true
                recallButton.isHidden = false
            }
        }
    }

    fileprivate var applyCallBack: (() -> Void)?
    fileprivate var closeCallBack: (() -> Void)?
    fileprivate var recallCallBack: (() -> Void)?

    private lazy var applyView: UIView = {
        let view = UIView()
        let label = UILabel()
        label.textColor = UIColor.ud.textLinkHover
        label.text = BundleI18n.LarkMessageCore.Lark_IM_TranslationAsYouType_UseTranslation_Button
        label.font = UIFont.systemFont(ofSize: 14)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        let imageView = UIImageView()
        imageView.image = Resources.detail_arrow
        view.addSubview(label)
        view.addSubview(imageView)
        label.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(12)
        }
        imageView.snp.makeConstraints { make in
            make.left.equalTo(label.snp.right)
            make.right.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.centerY.equalToSuperview()
        }
        view.isHidden = true
        view.lu.addTapGestureRecognizer(action: #selector(onApply), target: self)
        return view
    }()

    private lazy var recallButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(BundleI18n.LarkMessageCore.Lark_IM_TranslationAsYouType_DoNotUseTranslation_Button, for: .normal)
        button.setTitleColor(UIColor.ud.textLinkHover, for: .normal)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(onRecall), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UDIcon.getIconByKey(.closeSmallOutlined, size: CGSize(width: 24, height: 24)), for: .normal)
        button.tintColor = .ud.iconN3
        button.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        return button
    }()
    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        addSubview(applyView)
        applyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.height.width.equalTo(24)
            make.right.equalToSuperview().offset(-2)
            make.left.greaterThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }
        addSubview(recallButton)
        recallButton.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
        }
    }

    @objc
    private func onApply() {
        applyCallBack?()
    }

    @objc
    private func onClose() {
        closeCallBack?()
    }

    @objc
    private func onRecall() {
        recallCallBack?()
    }
}

private final class PreviewContentView: UIScrollView {
    let contentLabel = UILabel()
    lazy var loadingView: ChatLoadingItemView = {
        return ChatLoadingItemView()
    }()

    override var contentSize: CGSize {
        didSet {
            if !contentSize.equalTo(oldValue), self.frame.width > 0 {
                let offset = contentSize.width - self.frame.width
                self.setContentOffset(CGPoint(x: max(offset, 0), y: 0), animated: false)
            }
            self.contentBeyondWidthBlock?(contentSize.width > frame.width)
        }
    }

    var contentBeyondWidthBlock: ((Bool) -> Void)?

    init() {
        super.init(frame: .zero)
        setupUI()
        showsHorizontalScrollIndicator = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentLabel.backgroundColor = UIColor.clear
        contentLabel.textColor = UIColor.ud.textCaption
        loadingView.textColor = UIColor.ud.textCaption
        self.addSubview(contentLabel)
        self.addSubview(loadingView)
        contentLabel.snp.makeConstraints { make in
            make.top.bottom.height.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalTo(loadingView.snp.left)
        }
        loadingView.snp.makeConstraints { make in
            make.top.bottom.height.equalToSuperview()
            make.right.equalToSuperview()
        }
    }
}

private final class PreviewView: UIView {
    let contentView = PreviewContentView()

    lazy var coverView: UIView = {
        let view = UIImageView()
        view.image = Resources.rectangle_corver
        view.isHidden = true
        return view
    }()

    deinit {
        self.loadingView.stop()
    }
    var contentLabel: UILabel {
        return contentView.contentLabel
    }

    var loadingView: ChatLoadingItemView {
        return contentView.loadingView
    }

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        self.addSubview(contentView)
        self.addSubview(coverView)
        self.clipsToBounds = true

        contentView.contentBeyondWidthBlock = { [weak self] beyondWidth in
            self?.coverView.isHidden = !beyondWidth
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        coverView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(8)
            make.height.equalTo(22)
            make.left.equalToSuperview()
        }
    }
}

private class PreviewMultiLineView: UIView {
    private let scrollView = UIScrollView()
    private lazy var contentLabel: PreviewMultiLineContentView = {
        return PreviewMultiLineContentView { [weak self] height in
            self?.scrollView.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            self?.scrollView.layoutIfNeeded()
            self?.scrollView.contentSize.height = height
            self?.scrollToBottom()
        }
    }()
    lazy var loadingView: ChatLoadingItemView = {
        return contentLabel.loadingView
    }()

    deinit {
        loadingView.stop()
    }

    init() {
        super.init(frame: .zero)
        setupUI()
        scrollView.showsHorizontalScrollIndicator = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentSize.height = contentLabel.bounds.height
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setContent(_ text: String, color: UIColor?) {
        contentLabel.setContent(text, color: color)
        scrollToBottom()
    }

    private func scrollToBottom() {
        let offset = scrollView.contentSize.height - scrollView.bounds.height
        scrollView.setContentOffset(.init(x: 0, y: max(offset, 0)), animated: false)
    }

    private func setupUI() {
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(contentLineHeight)
        }
        contentLabel.backgroundColor = UIColor.clear
        contentLabel.textColor = UIColor.ud.textCaption
        contentLabel.numberOfLines = 0
        contentLabel.setContentHuggingPriority(.required, for: .vertical)
        scrollView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalToSuperview()
        }
    }
}

private class PreviewMultiLineContentView: UILabel {
    public override var bounds: CGRect {
        didSet {
            if bounds.height == oldValue.height {
                return
            }
            onHeightChanged(bounds.height)
        }
    }
    let onHeightChanged: ((CGFloat) -> Void)

    lazy var loadingView: ChatLoadingItemView = {
        let loadingView = ChatLoadingItemView()
        loadingView.font = .systemFont(ofSize: 16, weight: .regular)
        loadingView.textColor = UIColor.ud.textCaption
        return ChatLoadingItemView()
    }()

    init(onHeightChanged: @escaping ((CGFloat) -> Void)) {
        self.onHeightChanged = onHeightChanged
        super.init(frame: .zero)
        self.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(contentLineHeight)
            make.width.equalTo(loadingView.getSuggestWidth())
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private lazy var attributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = contentLineHeight
        paragraphStyle.maximumLineHeight = contentLineHeight
        return [
            .font: self.font,
            .paragraphStyle: paragraphStyle
        ]
    }()
    fileprivate func setContent(_ text: String, color: UIColor?) {
        var attributes = self.attributes
        if let color = color {
            attributes[.foregroundColor] = color
        }
        let attrText = NSMutableAttributedString(string: text, attributes: attributes)
        self.attributedText = attrText
    }
}

public protocol TranslationInfoPreviewViewDelegate: AnyObject {
    func didClickLanguageItem(currentLanguage: String)
    func didClickApplyTranslationItem()
    func didClickCloseTranslationItem()
    func didClickRecallTranslationItem()
    func didClickPreview()
}

public final class TranslationInfoPreviewView: UIView {
    public override var bounds: CGRect {
        didSet {
            if self.style == .none {
                return
            }
            contentHeight = bounds.height
        }
    }

    private enum Style {
        case none
        case onlyTitle
        case onlyContent
        case double
    }

    public enum EditType {
        case none
        case title(String)
        case content(String)
    }

    fileprivate var contentHeight: CGFloat = 30 {
        didSet {
            if contentHeight != oldValue {
                self.updateHeightBlock?(contentHeight, oldValue)
            }
        }
    }
    public var isTitleLoading: Bool = false {
        didSet {
            if canShowLoading,
               isTitleLoading {
                self.titlePreviewView.loadingView.startLoading()
            } else {
                self.titlePreviewView.loadingView.stopLoading()
            }
            updateUI()
        }
    }
    public var isContentLoading: Bool = false {
        didSet {
            if canShowLoading,
               isContentLoading {
                self.contentPreviewView.loadingView.startLoading()
            } else {
                self.contentPreviewView.loadingView.stopLoading()
            }
            updateUI()
        }
    }

    public var recallEnable: Bool = false {
        didSet {
            updateUI()
        }
    }

    public var editType: TranslationInfoPreviewView.EditType = .none {
        didSet {
            updateEditType()
        }
    }

    private var style: TranslationInfoPreviewView.Style = .onlyContent {
        didSet {
            if style != oldValue {
                handleStyleUpdate()
                if style != .none {
                    contentHeight = self.bounds.height
                }
            }
        }
    }

    private var targetLanguage: String
    fileprivate var updateHeightBlock: ((_ newHeight: CGFloat, _ oldHeight: CGFloat) -> Void)?
    let contentPlaceholder = BundleI18n.LarkMessageCore.Lark_IM_TranslationAsYouType_TranslateInto_Placeholder
    let maxLines: Int

    private lazy var languageButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(targetLanguage, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.contentEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 8)
        button.addTarget(self, action: #selector(languageTap), for: .touchUpInside)
        button.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
        button.clipsToBounds = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private lazy var operationView: OperationView = {
        let view = OperationView()
        view.applyCallBack = { [weak self] in
            self?.delegate?.didClickApplyTranslationItem()
        }
        view.closeCallBack = { [weak self] in
            self?.delegate?.didClickCloseTranslationItem()
        }
        view.recallCallBack = { [weak self] in
            self?.delegate?.didClickRecallTranslationItem()
        }
        return view
    }()

    private lazy var titlePreviewView: PreviewView = {
        let preview = PreviewView()
        preview.backgroundColor = UIColor.clear
        preview.contentLabel.font = .systemFont(ofSize: 16, weight: .medium)
        preview.loadingView.font = .systemFont(ofSize: 16, weight: .medium)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPreview))
        preview.addGestureRecognizer(tap)
        return preview
    }()

    private lazy var contentPreviewView: PreviewMultiLineView = {
        let preview = PreviewMultiLineView()
        preview.backgroundColor = UIColor.clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPreview))
        preview.addGestureRecognizer(tap)
        return preview
    }()

    public weak var delegate: TranslationInfoPreviewViewDelegate?
    /// 是否可以展示loading
    private var canShowLoading = true
    public init(targetLanguage: String, maxLines: Int) {
        self.targetLanguage = targetLanguage
        self.maxLines = maxLines
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        self.backgroundColor = UIColor.clear
        self.addSubview(languageButton)
        self.addSubview(operationView)
        self.addSubview(titlePreviewView)
        self.addSubview(contentPreviewView)
        languageButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(34)
        }
        titlePreviewView.snp.makeConstraints { make in
            make.left.equalTo(languageButton.snp.right).offset(10)
            make.centerY.equalTo(languageButton)
            make.height.equalTo(28)
            make.right.equalTo(operationView.snp.left).offset(-10)
        }
        contentPreviewView.snp.makeConstraints { make in
            make.left.equalTo(languageButton.snp.right).offset(10)
            make.top.equalTo(titlePreviewView)
            make.bottom.equalToSuperview().offset(-2)
            make.height.lessThanOrEqualTo(contentLineHeight * CGFloat(maxLines))
            make.height.greaterThanOrEqualTo(contentLineHeight)
            make.right.equalTo(operationView.snp.left).offset(-10)
        }
        operationView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalTo(languageButton)
        }
        handleStyleUpdate()
    }

    fileprivate func handleStyleUpdate() {
        switch self.style {
        case .none:
            contentHeight = 0
        case .onlyContent:
            self.titlePreviewView.isHidden = true
            self.contentPreviewView.isHidden = false
            languageButton.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(28)
                make.width.greaterThanOrEqualTo(34)
            }
            self.contentPreviewView.snp.remakeConstraints { make in
                make.left.equalTo(languageButton.snp.right).offset(10)
                make.top.equalTo(self.languageButton).offset(3)
                make.bottom.equalToSuperview().offset(-3)
                make.height.lessThanOrEqualTo(contentLineHeight * CGFloat(maxLines))
                make.height.greaterThanOrEqualTo(contentLineHeight)
                make.right.equalTo(operationView.snp.left).offset(-10)
            }
        case .onlyTitle:
            self.titlePreviewView.isHidden = false
            self.contentPreviewView.isHidden = true
            languageButton.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview().offset(-2)
                make.height.equalTo(28)
                make.width.greaterThanOrEqualTo(34)
            }
        case .double:
            self.titlePreviewView.isHidden = false
            self.contentPreviewView.isHidden = false
            languageButton.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(28)
                make.width.greaterThanOrEqualTo(34)
            }
            self.contentPreviewView.snp.remakeConstraints { make in
                make.left.equalTo(languageButton.snp.right).offset(10)
                make.top.equalTo(titlePreviewView.snp.bottom)
                make.bottom.equalToSuperview()
                make.height.lessThanOrEqualTo(contentLineHeight * CGFloat(maxLines))
                make.height.greaterThanOrEqualTo(contentLineHeight)
                make.right.equalTo(operationView.snp.left).offset(-10)
            }
        }
    }

    private var title: String = ""
    private var content: String = ""
    fileprivate func updateEditType() {
        switch self.editType {
        case .none:
            title = ""
            content = ""
        case .title(let title):
            self.title = title
        case .content(let content):
            self.content = content
        }
        updateUI()
    }

    private func updateUI() {
        self.titlePreviewView.contentLabel.text = title
        if title.isEmpty,
           content.isEmpty {
            if canShowLoading && (isTitleLoading || isContentLoading) {
                self.operationView.status = .apply
                self.contentPreviewView.setContent("", color: nil)
            } else {
                self.operationView.status = recallEnable ? .recall : .close
                self.contentPreviewView.setContent(contentPlaceholder, color: .ud.textPlaceholder)
            }
        } else {
            self.operationView.status = .apply
            self.contentPreviewView.setContent(content, color: .ud.textCaption)
        }
        if style != .none {
            updateStyle()
        }
    }

    private func updateStyle() {
        if title.isEmpty && !(canShowLoading && isTitleLoading) {
            style = .onlyContent
        } else if content.isEmpty && !(canShowLoading && isContentLoading) {
            style = .onlyTitle
        } else {
            style = .double
        }
    }

    public func clearData() {
        self.isTitleLoading = false
        self.isContentLoading = false
        self.editType = .none
    }

    public func updateLanguage(_ language: String) {
        self.targetLanguage = language
        self.languageButton.setTitle(language, for: .normal)
    }

    public func updatePreviewData(title: String, content: String) {
        self.editType = .title(title)
        self.editType = .content(content)
    }

    public func disableLoadingTemporary(_ interval: TimeInterval = 0.5) {
        self.isTitleLoading = false
        self.isContentLoading = false
        if interval > 0 {
            self.canShowLoading = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            self?.canShowLoading = true
        }
    }

    public func setDisplayable(_ value: Bool) {
        if value {
            updateStyle()
        } else {
            self.style = .none
        }
    }

    /// 语言切换按钮点击
    @objc
    func languageTap() {
        self.delegate?.didClickLanguageItem(currentLanguage: targetLanguage)
    }

    @objc
    func didTapPreview() {
        self.delegate?.didClickPreview()
    }
}

public final class TranslationInfoPreviewContainerView: UIView {
    private var displayLink: CADisplayLink?
    private var animateEnable: Bool
    public var updateHeightBlock: ((CGFloat) -> Void)?
    private var contentHeight: CGFloat = 39 {
        didSet {
            if contentHeight != oldValue {
                if contentHeight == 0 {
                    self.isHidden = true
                } else if oldValue == 0 {
                    self.isHidden = false
                }
                self.updateHeightBlock?(contentHeight)
            }
        }
    }
    private var animateTargetHeight: CGFloat = 39 {
        didSet {
            guard animateTargetHeight != oldValue else {
                return
            }
            self.startAnimate()
        }
    }
    public let translationInfoPreviewView: TranslationInfoPreviewView
    private let topInset: CGFloat = 9 //translationInfoPreviewView的上边距
    public init(targetLanguage: String, displayable: Bool, maxLines: Int, updateHeightBlock: ((CGFloat) -> Void)?) {
        self.translationInfoPreviewView = TranslationInfoPreviewView(targetLanguage: targetLanguage, maxLines: maxLines)
        //刚进会话首次布局时，不播放动画
        self.animateEnable = false
        self.updateHeightBlock = updateHeightBlock
        super.init(frame: .zero)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.animateEnable = true
        }
        self.addSubview(translationInfoPreviewView)
        self.clipsToBounds = true
        translationInfoPreviewView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(topInset)
        }
        translationInfoPreviewView.updateHeightBlock = { [weak self] newHeight, _ in
            guard let self = self else { return }
            let targetHeight = newHeight == 0 ? 0 : newHeight + self.topInset
            if !self.animateEnable {
                //不播放动画，则直接设置好contentHeight
                self.contentHeight = targetHeight
            }

            self.animateTargetHeight = targetHeight
        }
        self.translationInfoPreviewView.setDisplayable(displayable)
    }

    private var isAnimating = false
    private let animateSpeed: CGFloat = 4 //每一帧变化4CGFloat
    private func startAnimate() {
        if isAnimating {
            return
        }
        self.displayLink?.invalidate()
        self.displayLink = CADisplayLink(target: self, selector: #selector(self.animation(_:)))
        self.displayLink?.add(to: .current, forMode: .common)
        self.isAnimating = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func animation(_ sender: CADisplayLink) {
        let differenceValue = self.animateTargetHeight - self.contentHeight
        if abs(differenceValue) < animateSpeed {
            //差异的绝对值小于animateSpeed，说明是动画最后一帧了
            self.contentHeight = self.animateTargetHeight
            self.isAnimating = false
            sender.invalidate()
            return
        }

        let isAnimateToShow: Bool = self.animateTargetHeight > self.contentHeight
        let delta: CGFloat = isAnimateToShow ? animateSpeed : -animateSpeed
        contentHeight += delta
    }
}
