//
//  AnchorToastView.swift
//  ByteViewUI
//
//  Created by lutingting on 2022/8/30.
//

import Foundation
import ByteViewCommon


public typealias AnchorDirection = TriangleView.Direction
extension AnchorToastView {
    enum Layout {
        static var arrowWidth: CGFloat = 6
        static var arrowLength: CGFloat = 16
        static let horizontalEdgeOffset: CGFloat = 8.0
        static let contentMaxWidth: CGFloat = 300
        static let contentLeftPadding: CGFloat = 12
        static let contentTopPadding: CGFloat = 8
    }
}

public final class AnchorToastView: UIView {
    public private(set) lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgTips
        view.layer.cornerRadius = 8
        return view
    }()

    public private(set) var content: String?

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var arrowView: TriangleView = {
        let view = TriangleView()
        view.color = UIColor.ud.bgTips
        view.backgroundColor = UIColor.clear
        return view
    }()

    private weak var referenceView: UIView?
    public var sureAction: (() -> Void)?
    public var pressToastAction: (() -> Void)?
    private var distance: CGFloat = 4
    private var extremeWidth: CGFloat = 0
    /// top/bottom 方向展示时，如果高度超出父视图，自动反向展示，如果反向也展示不下，则按照预期方向展示
    public var autoReverseVertical: Bool = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func sure() {
        sureAction?()
    }

    public func anchorToastPress() {
        pressToastAction?()
    }

    private func initialize() {
        backgroundColor = UIColor.clear

        addSubview(contentView)
        contentView.addSubview(label)
        addSubview(arrowView)

        label.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Layout.contentLeftPadding)
            make.top.bottom.equalToSuperview().inset(Layout.contentTopPadding)
        }
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitTestView = super.hitTest(point, with: event)
        if pressToastAction != nil, hitTestView == self.contentView {
            anchorToastPress()
        } else if hitTestView != nil {
            sure()
        }
        return nil
    }

    public func setStyle(_ content: String,
                         actionTitle: String? = nil,
                         on direction: AnchorDirection,
                         of referenceView: UIView, distance: CGFloat? = nil,
                         defaultEnoughInset: CGFloat? = nil ) {
        self.content = content
        let attributedString = NSMutableAttributedString(attributedString: NSAttributedString(string: content, config: .tinyAssist))
        if let actionTitle = actionTitle {
            let actionAttr = NSAttributedString(string: actionTitle, config: .tinyAssist, textColor: UIColor.ud.primaryContentLoading)
            attributedString.append(actionAttr)
        }
        label.attributedText = attributedString
        self.referenceView = referenceView
        let fullContent = attributedString.string
        self.extremeWidth = fullContent.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: 18), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], context: nil).width + Layout.contentLeftPadding * 2
        arrowView.direction = direction
        updateLayout(referenceView: referenceView, distance: distance, defaultEnoughInset: defaultEnoughInset)
    }

    // disable-lint: long function
    public func updateLayout(referenceView: UIView?, distance: CGFloat? = nil, arrowDirection: AnchorDirection? = nil, defaultEnoughInset: CGFloat? = nil ) {
        guard let referenceView = referenceView, referenceView.superview != nil, let superview = superview else { return }
        isHidden = false
        let width: CGFloat = self.extremeWidth
        var arrowDistance: CGFloat = 0

        if let distance = distance {
            arrowDistance = distance
        } else {
            arrowDistance = self.distance
        }
        self.distance = arrowDistance

        if let arrowDirection = arrowDirection {
            arrowView.direction = arrowDirection
        }

        let isVertical = arrowView.direction == .top || arrowView.direction == .bottom
        let contentMaxWidth = Layout.contentMaxWidth - Layout.contentLeftPadding * 2
        if autoReverseVertical && width >= contentMaxWidth && isVertical {
            let labelHeight = label.attributedText?.string.vc.boundingHeight(width: contentMaxWidth, config: .tinyAssist) ?? 0.0
            // 计算后的 label 高度 + 箭头高度 + 箭头间距 + label 上下间距
            let toastHeight = labelHeight
                + Layout.arrowWidth
                + arrowDistance
                + Layout.contentTopPadding * 2
            let referenceFrame = referenceView.convert(referenceView.frame, to: superview)
            if arrowView.direction == .top,
               referenceFrame.minY - toastHeight <= superview.frame.minY,
               referenceFrame.maxY + toastHeight <= superview.frame.maxY
            {
                arrowView.direction = .bottom
            } else if arrowView.direction == .bottom,
                      referenceFrame.maxY + toastHeight >= superview.frame.maxY,
                      referenceFrame.minY - toastHeight >= superview.frame.minY
            {
                arrowView.direction = .top
            }
        }

        switch arrowView.direction {
        case .top:
            var frame = referenceView.frame
            var rSuperview = referenceView.superview
            while rSuperview != superview {
                if let rFrame = rSuperview?.frame {
                    frame = CGRect(origin: CGPoint(x: rFrame.minX + frame.minX, y: rFrame.minY + frame.minY), size: frame.size)
                    rSuperview = rSuperview?.superview
                } else {
                    break
                }
            }
            let contentWidth = width > Layout.contentMaxWidth ? Layout.contentMaxWidth : width
            let rightIsEnough = (superview.frame.width - frame.minX - frame.width / 2) > contentWidth / 2
            let leftIsEnough = frame.midX > contentWidth / 2

            var horInset = Layout.horizontalEdgeOffset
            if let defaultEnoughInset = defaultEnoughInset {
                horInset = defaultEnoughInset
            }

            contentView.snp.remakeConstraints { (make) in
                if rightIsEnough && leftIsEnough {
                    make.centerX.equalTo(referenceView)
                } else if leftIsEnough {
                    make.right.equalToSuperview().inset(horInset)
                } else {
                    make.left.equalToSuperview().inset(horInset)
                }
                make.bottom.equalTo(arrowView.snp.top)
                make.width.equalTo(width).priority(.low)
                make.width.lessThanOrEqualTo(Layout.contentMaxWidth)
            }

            arrowView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowLength)
                make.height.equalTo(Layout.arrowWidth)
                make.bottom.equalTo(referenceView.snp.top).offset(-arrowDistance)
                make.centerX.equalTo(referenceView)
            }
        case .bottom:
            var frame = referenceView.frame
            var rSuperview = referenceView.superview
            while rSuperview != superview {
                if let rFrame = rSuperview?.frame {
                    frame = CGRect(origin: CGPoint(x: rFrame.minX + frame.minX, y: rFrame.minY + frame.minY), size: frame.size)
                    rSuperview = rSuperview?.superview
                } else {
                    break
                }
            }
            let contentWidth = width > Layout.contentMaxWidth ? Layout.contentMaxWidth : width
            let rightIsEnough = (superview.frame.width - frame.minX - frame.width / 2) > contentWidth / 2
            let leftIsEnough = frame.midX > contentWidth / 2

            var horInset = Layout.horizontalEdgeOffset
            if let defaultEnoughInset = defaultEnoughInset {
                horInset = defaultEnoughInset
            }

            contentView.snp.remakeConstraints { (make) in
                if rightIsEnough && leftIsEnough {
                    make.centerX.equalTo(referenceView)
                } else if leftIsEnough {
                    make.right.equalToSuperview().inset(horInset)
                } else {
                    make.left.equalToSuperview().inset(horInset)
                }
                make.top.equalTo(arrowView.snp.bottom)
                make.width.equalTo(width + 2).priority(.low)
                make.width.lessThanOrEqualTo(Layout.contentMaxWidth)
            }

            arrowView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowLength)
                make.height.equalTo(Layout.arrowWidth)
                make.top.equalTo(referenceView.snp.bottom).offset(arrowDistance)
                make.centerX.equalTo(referenceView)
            }
        case .right:
            contentView.snp.remakeConstraints { (make) in
                make.left.equalTo(arrowView.snp.right)
                make.centerY.equalTo(referenceView)
                make.width.lessThanOrEqualTo(width)
            }

            arrowView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowWidth)
                make.height.equalTo(Layout.arrowLength)
                make.centerY.equalTo(referenceView)
                make.left.equalTo(referenceView.snp.right).offset(arrowDistance)
            }
        case .left:
            contentView.snp.remakeConstraints { (make) in
                make.right.equalTo(arrowView.snp.left)
                make.centerY.equalTo(referenceView)
                make.width.lessThanOrEqualTo(width)
            }

            arrowView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowWidth)
                make.height.equalTo(Layout.arrowLength)
                make.centerY.equalTo(referenceView)
                make.right.equalTo(referenceView.snp.left).offset(-arrowDistance)
            }
        case .centerBottom:
            contentView.snp.remakeConstraints { (make) in
                make.centerX.equalTo(referenceView)
                make.top.equalTo(arrowView.snp.bottom)
                make.width.lessThanOrEqualTo(width)
            }

            arrowView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowLength)
                make.height.equalTo(Layout.arrowWidth)
                make.top.equalTo(referenceView.snp.centerY).offset(arrowDistance)
                make.centerX.equalTo(referenceView)
            }
        }
        arrowView.setNeedsDisplay()
        layoutIfNeeded()
    }
    // enable-lint: long function
}
