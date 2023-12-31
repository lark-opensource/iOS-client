//
//  DailyDetailContentView.swift
//  ByteView
//
//  Created by fakegourmet on 2020/12/2.
//

import Foundation
import SnapKit

class DailyDetailContentView: UIView {

    enum AdditionViewDirection {
        case left
        case right
        case up
        case bottom
    }

    let maxTitleWidth: CGFloat = 92.0
    var fitTitleWidth: CGFloat = 0.0
    var horizontalOffset: CGFloat = 4.0
    var shouldTruncate: Bool {
        fitTitleWidth > maxTitleWidth
    }

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.preferredMaxLayoutWidth = maxTitleWidth
        return titleLabel
    }()

    private lazy var additionalView: UIView = UIView()
    private var viewSize: CGSize = .zero
    private var additionalDirection: AdditionViewDirection = .right
    private var hasAdditionalView: Bool = false
    private lazy var gestureContainerView: UIView = UIView()
    private var tapCompletion: (() -> Void)?

    var contentView: UIView?
    var contentCopyTextView: CopyableTextView?

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(frame: .zero)
        initialize()
    }

    init(contentView: CopyableTextView, additionalView: UIView, viewSize: CGSize, additionalDirection: AdditionViewDirection = .right, tapCompletion: (() -> Void)? = nil) {
        self.contentCopyTextView = contentView
        super.init(frame: .zero)
        self.additionalView = additionalView
        self.additionalDirection = additionalDirection
        self.viewSize = viewSize
        self.hasAdditionalView = true
        self.tapCompletion = tapCompletion
        initialize()
    }

    init(contentView: UIView, additionalView: UIView, viewSize: CGSize, additionalDirection: AdditionViewDirection = .right, tapCompletion: (() -> Void)? = nil) {
        self.contentView = contentView
        super.init(frame: .zero)
        self.additionalView = additionalView
        self.additionalDirection = additionalDirection
        self.viewSize = viewSize
        self.hasAdditionalView = true
        self.tapCompletion = tapCompletion
        initialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialize() {
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .horizontal)

        addSubview(titleLabel)
        if let contentView = contentView {
            addSubview(contentView)
        }
        if let contentCopyTextView = contentCopyTextView {
            addSubview(contentCopyTextView)
        }
        if hasAdditionalView {
            addSubview(additionalView)
            if tapCompletion != nil {
                addSubview(gestureContainerView)
                let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
                gestureContainerView.addGestureRecognizer(gesture)
            }
        }
    }

    func setContent(title: String) -> CGFloat {
        titleLabel.attributedText = NSAttributedString(string: title, config: .r_14_22)
        let fitSize = titleLabel.sizeThatFits(CGSize(width: maxTitleWidth, height: .greatestFiniteMagnitude))
        fitTitleWidth = fitSize.width
        return fitTitleWidth
    }

    @objc func didTap() {
        tapCompletion?()
    }

    func setupConstraints(contentLayoutGuide: UILayoutGuide, verticalSeparator: UILayoutGuide, titleWidth: CGFloat? = nil) {
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentLayoutGuide)
            make.top.equalToSuperview()
            make.right.equalTo(verticalSeparator.snp.left)
            make.width.lessThanOrEqualTo(maxTitleWidth)
            make.bottom.lessThanOrEqualToSuperview()
            if let titleWidth = titleWidth {
                make.width.equalTo(titleWidth).priority(.required)
            }
        }
        if hasAdditionalView {
            setupConstraintsWithAdditionalView(contentLayoutGuide: contentLayoutGuide, verticalSeparator: verticalSeparator)
        } else {
            var currentContentView: UIView
            if let contentView = self.contentView, contentView.superview != nil {
                currentContentView = contentView
            } else if let contentCopyTextView = self.contentCopyTextView, contentCopyTextView.superview != nil {
                currentContentView = contentCopyTextView
            } else {
                return
            }
            currentContentView.removeFromSuperview()
            addSubview(currentContentView)
            currentContentView.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel)
                make.left.equalTo(verticalSeparator.snp.right)
                make.right.equalTo(contentLayoutGuide)
                make.height.greaterThanOrEqualTo(22)
                make.bottom.lessThanOrEqualToSuperview()
            }
        }
    }

    private func setupConstraintsWithAdditionalView(contentLayoutGuide: UILayoutGuide, verticalSeparator: UILayoutGuide) {
        if tapCompletion != nil {
            gestureContainerView.snp.remakeConstraints { make in
                make.left.equalTo(verticalSeparator.snp.right)
                make.right.equalTo(contentLayoutGuide.snp.right)
                make.bottom.top.equalToSuperview()
            }
        }
        switch additionalDirection {
        case .right:
                if additionalView.isHidden {
                    additionalView.snp.remakeConstraints { make in
                        make.top.equalToSuperview()
                        make.left.equalTo(contentLayoutGuide.snp.right)
                    }
                    var currentContentView: UIView
                    if let contentView = self.contentView, contentView.superview != nil {
                        currentContentView = contentView
                    } else if let contentCopyTextView = self.contentCopyTextView, contentCopyTextView.superview != nil {
                        currentContentView = contentCopyTextView
                    } else {
                        return
                    }
                    currentContentView.snp.remakeConstraints { make in
                        make.top.equalTo(titleLabel)
                        make.left.equalTo(verticalSeparator.snp.right)
                        make.right.equalTo(contentLayoutGuide)
                        make.height.greaterThanOrEqualTo(22)
                        make.bottom.lessThanOrEqualToSuperview()
                    }
                } else {
                    if let contentView = self.contentView, contentView.superview != nil {
                        additionalView.snp.remakeConstraints { make in
                            make.centerY.equalToSuperview()
                            make.right.lessThanOrEqualTo(contentLayoutGuide.snp.right)
                        }
                        contentView.snp.remakeConstraints { make in
                            make.left.equalTo(verticalSeparator.snp.right)
                            make.top.equalTo(titleLabel)
                            make.bottom.lessThanOrEqualToSuperview()
                            make.height.greaterThanOrEqualTo(22)
                            make.right.equalTo(additionalView.snp.left).offset(-4)
                        }
                    } else if let contentCopyTextView = self.contentCopyTextView, contentCopyTextView.superview != nil {
                        let contentWidth = contentLayoutGuide.layoutFrame.maxX - verticalSeparator.layoutFrame.maxX
                        let additionalViewWidth = additionalView.intrinsicContentSize.width
                        let intrinsicWidth = contentCopyTextView.customIntrinsicContentSize?.width ?? contentCopyTextView.intrinsicContentSize.width
                        // 一行放得下或者只能显示一行
                        // textView分屏后者旋转屏幕时可能不刷新，所以先remove后add
                        contentCopyTextView.removeFromSuperview()
                        addSubview(contentCopyTextView)
                        if contentCopyTextView.shouldLimit || intrinsicWidth + additionalViewWidth + horizontalOffset <= contentWidth {
                            additionalView.snp.remakeConstraints { make in
                                make.centerY.equalTo(contentCopyTextView.snp.centerY)
                                make.height.equalTo(viewSize.height)
                                make.right.lessThanOrEqualTo(contentLayoutGuide.snp.right)
                            }
                            contentCopyTextView.snp.remakeConstraints { make in
                                make.left.equalTo(verticalSeparator.snp.right)
                                make.top.equalTo(titleLabel)
                                make.bottom.lessThanOrEqualToSuperview()
                                make.height.greaterThanOrEqualTo(22)
                                make.right.equalTo(additionalView.snp.left).offset(-horizontalOffset)
                            }
                        } else {
                            contentCopyTextView.snp.makeConstraints { make in
                                make.top.equalTo(titleLabel)
                                make.left.equalTo(verticalSeparator.snp.right)
                                make.right.equalTo(contentLayoutGuide)
                            }
                            additionalView.snp.remakeConstraints { make in
                                make.top.equalTo(contentCopyTextView.snp.bottom).offset(4)
                                make.left.equalTo(contentCopyTextView)
                                make.bottom.equalToSuperview()
                            }
                        }
                    }
                }
            return
        case .left:
            var currentContentView: UIView
            if let contentView = self.contentView, contentView.superview != nil {
                currentContentView = contentView
            } else if let contentCopyTextView = self.contentCopyTextView, contentCopyTextView.superview != nil {
                currentContentView = contentCopyTextView
            } else {
                return
            }
            additionalView.snp.remakeConstraints { make in
                make.left.equalTo(verticalSeparator.snp.right)
                make.centerY.equalTo(currentContentView)
                make.size.equalTo(viewSize)
            }
            currentContentView.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel)
                make.left.equalTo(additionalView.snp.right).offset(4)
                make.right.equalTo(contentLayoutGuide)
                make.height.greaterThanOrEqualTo(22)
                make.bottom.lessThanOrEqualToSuperview()
            }
        case .up:
            var currentContentView: UIView
            if let contentView = self.contentView, contentView.superview != nil {
                currentContentView = contentView
            } else if let contentCopyTextView = self.contentCopyTextView, contentCopyTextView.superview != nil {
                currentContentView = contentCopyTextView
            } else {
                return
            }
            additionalView.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel)
                make.left.equalTo(verticalSeparator.snp.right)
                make.right.lessThanOrEqualTo(contentLayoutGuide)
            }
            currentContentView.snp.remakeConstraints { make in
                make.top.equalTo(currentContentView.snp.bottom).offset(6)
                make.left.equalTo(verticalSeparator.snp.right)
                make.right.lessThanOrEqualTo(contentLayoutGuide)
                make.bottom.equalToSuperview()
            }
        case .bottom:
            var currentContentView: UIView
            if let contentView = self.contentView, contentView.superview != nil {
                currentContentView = contentView
            } else if let contentCopyTextView = self.contentCopyTextView, contentCopyTextView.superview != nil {
                currentContentView = contentCopyTextView
            } else {
                return
            }
            currentContentView.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel)
                make.left.equalTo(verticalSeparator.snp.right)
                make.right.lessThanOrEqualTo(contentLayoutGuide)
            }
            additionalView.snp.remakeConstraints { make in
                make.top.equalTo(currentContentView.snp.bottom).offset(6)
                make.left.equalTo(verticalSeparator.snp.right)
                make.right.lessThanOrEqualTo(contentLayoutGuide)
                make.bottom.equalToSuperview()
            }
        }
    }

    func updateConstraintsWithButton(contentLayoutGuide: UILayoutGuide, verticalSeparator: UILayoutGuide, shouldHiddenButton: Bool = true) {
        guard hasAdditionalView else { return }
        setupConstraintsWithAdditionalView(contentLayoutGuide: contentLayoutGuide, verticalSeparator: verticalSeparator)
    }
}

class DailyDetailButton: UIButton {
    enum DailyDetailButtonType {
        case image(CGSize)
        case text(CGFloat, UIEdgeInsets)
    }
    let customType: DailyDetailButtonType
    init(customType: DailyDetailButtonType) {
        self.customType = customType
        super.init(frame: .zero)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        switch customType {
        case .image(let size):
            return size
        case .text(let height, let insets):
            return CGSize(width: insets.left + insets.right + (titleLabel?.intrinsicContentSize.width ?? 0), height: height)
        }
    }
}
