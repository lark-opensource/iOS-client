//
//  AnchorView.swift
//  ByteViewUI
//
//  Created by lutingting on 2022/12/14.
//

import Foundation
import UniverseDesignShadow

extension AnchorView {
    enum Layout {
        static var arrowWidth: CGFloat = 7
        static var arrowLength: CGFloat = 16
        static let horizontalEdgeOffset: CGFloat = 8.0
    }
}

public final class AnchorView: UIView {
    public let wrapperView: UIView

    public var sourceView: UIView?
    public var direction: AnchorDirection = .top
    public var distance: CGFloat = 4

    public var size: CGSize = .zero

    public private(set) lazy var contentView: UIView = UIView()

    private lazy var arrowView: TriangleView = {
        let view = TriangleView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var arrowBorderView: TriangleView = {
        let view = TriangleView()
        view.backgroundColor = UIColor.clear
        view.addSubview(arrowView)
        return view
    }()

    public var contentBGColor: UIColor? {
        didSet {
            wrapperView.backgroundColor = contentBGColor
            arrowView.color = contentBGColor
        }
    }

    public var borderColor: UIColor? {
        didSet {
            guard let color = borderColor else { return }
            contentView.layer.ud.setBorderColor(color)
            arrowBorderView.color = color
        }
    }

    public var borderWidth: CGFloat = 0 {
        didSet {
            contentView.layer.borderWidth = borderWidth
        }
    }

    public var cornerRadius: CGFloat = 0 {
        didSet {
            contentView.layer.cornerRadius = cornerRadius
            wrapperView.layer.cornerRadius = cornerRadius
            wrapperView.layer.masksToBounds = true
        }
    }

    public var shadowType: UniverseDesignShadow.UDShadowType? {
        didSet {
            guard let shadowType = shadowType else { return }
            contentView.layer.ud.setShadow(type: shadowType)
            arrowBorderView.layer.ud.setShadow(type: shadowType)
        }
    }

    public init(wrapperView: UIView) {
        self.wrapperView = wrapperView
        super.init(frame: .zero)
        initialize()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialize() {
        backgroundColor = UIColor.clear
        contentView.backgroundColor = .clear
        addSubview(contentView)
        contentView.addSubview(wrapperView)
        addSubview(arrowBorderView)

        wrapperView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public override func layoutSubviews() {
        updateLayout()
    }

    // disable-lint: long function
    public func updateLayout() {
        guard let referenceView = sourceView, referenceView.superview != nil, let superview = superview else { return }
        arrowBorderView.direction = direction
        arrowView.direction = direction

        switch arrowView.direction {
        case .top:
            let (leftIsEnough, rightIsEnough) = bothSidesEnough(referenceView, superview: superview)
            contentView.snp.remakeConstraints { (make) in
                if rightIsEnough && leftIsEnough {
                    make.centerX.equalTo(referenceView)
                } else if leftIsEnough {
                    make.right.equalToSuperview().inset(Layout.horizontalEdgeOffset)
                } else {
                    make.left.equalToSuperview().inset(Layout.horizontalEdgeOffset)
                }
                make.bottom.equalTo(arrowBorderView.snp.top).offset(borderWidth)
                make.size.equalTo(size)
            }

            arrowBorderView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowLength + borderWidth * 5)
                make.height.equalTo(Layout.arrowWidth + borderWidth)
                make.bottom.equalTo(referenceView.snp.top).offset(-distance)
                make.centerX.equalTo(referenceView)
            }

            arrowView.snp.remakeConstraints { make in
                make.width.equalTo(Layout.arrowLength)
                make.height.equalTo(Layout.arrowWidth)
                make.top.centerX.equalToSuperview()
            }
        case .bottom:
            let (leftIsEnough, rightIsEnough) = bothSidesEnough(referenceView, superview: superview)
            contentView.snp.remakeConstraints { (make) in
                if rightIsEnough && leftIsEnough {
                    make.centerX.equalTo(referenceView)
                } else if leftIsEnough {
                    make.right.equalToSuperview().inset(Layout.horizontalEdgeOffset)
                } else {
                    make.left.equalToSuperview().inset(Layout.horizontalEdgeOffset)
                }
                make.top.equalTo(arrowView.snp.bottom)
                make.size.equalTo(size).priority(.low)
            }

            arrowBorderView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowLength + borderWidth * 5)
                make.height.equalTo(Layout.arrowWidth + borderWidth)
                make.top.equalTo(referenceView.snp.bottom).offset(distance)
                make.centerX.equalTo(referenceView)
            }

            arrowView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowLength)
                make.height.equalTo(Layout.arrowWidth)
                make.bottom.centerX.equalToSuperview()
            }
        case .right:
            contentView.snp.remakeConstraints { (make) in
                make.left.equalTo(arrowView.snp.right)
                make.centerY.equalTo(referenceView)
                make.size.equalTo(size)
            }

            arrowBorderView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowWidth + borderWidth)
                make.height.equalTo(Layout.arrowLength + borderWidth * 5)
                make.centerY.equalTo(referenceView)
                make.left.equalTo(referenceView.snp.right).offset(distance)
            }

            arrowView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowWidth)
                make.height.equalTo(Layout.arrowLength)
                make.right.centerY.equalToSuperview()
            }
        case .left:
            contentView.snp.remakeConstraints { (make) in
                make.right.equalTo(arrowView.snp.left)
                make.centerY.equalTo(referenceView)
                make.size.equalTo(size)
            }

            arrowBorderView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowWidth + borderWidth)
                make.height.equalTo(Layout.arrowLength + borderWidth * 5)
                make.centerY.equalTo(referenceView)
                make.right.equalTo(referenceView.snp.left).offset(-distance)
            }

            arrowView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowWidth)
                make.height.equalTo(Layout.arrowLength)
                make.left.centerY.equalToSuperview()
            }
        case .centerBottom:
            contentView.snp.remakeConstraints { (make) in
                make.centerX.equalTo(referenceView)
                make.top.equalTo(arrowView.snp.bottom)
                make.size.equalTo(size)
            }

            arrowBorderView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowLength + borderWidth * 5)
                make.height.equalTo(Layout.arrowWidth + borderWidth)
                make.top.equalTo(referenceView.snp.centerY).offset(distance)
                make.centerX.equalTo(referenceView)
            }

            arrowView.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.arrowLength)
                make.height.equalTo(Layout.arrowWidth)
                make.bottom.centerX.equalToSuperview()
            }
        }

        arrowBorderView.setNeedsDisplay()
        arrowView.setNeedsDisplay()
        layoutIfNeeded()
    }
    // enable-lint: long function
    private func bothSidesEnough(_ referenceView: UIView, superview: UIView) -> (Bool, Bool) {
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
        let rightIsEnough = (superview.frame.width - frame.minX - frame.width / 2) > size.width / 2
        let leftIsEnough = frame.midX > size.width / 2
        return (leftIsEnough, rightIsEnough)
    }
}
