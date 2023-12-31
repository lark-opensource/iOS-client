//
//  CommentShadowBaseCell.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/2/3.
//

import SKFoundation
import SnapKit
import UniverseDesignColor
import SpaceInterface

protocol CommentHighLightDelegate: NSObjectProtocol {
    func didHighLightTap(comment: Comment, cell: UITableViewCell)
}


class CommentShadowBaseCell: UITableViewCell {
    //private var hadAddGesture: Bool = false
    var curCommment: Comment?
    
    lazy var highLightTap: UITapGestureRecognizer = {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didHightLightTap))
        singleTap.delegate = self
        return singleTap
    }()

    weak var highLightDelegate: CommentHighLightDelegate? {
        didSet {
            if highLightDelegate != nil, contentView.gestureRecognizers?.contains(highLightTap) == false {
                contentView.addGestureRecognizer(highLightTap)
            }
        }
    }
    var highLighted: Bool = false
    let bgShadowLeftRightGap: CGFloat = 12.0
    private let bgLineWith: CGFloat = 1.0
    let bgViewCornerRadius: CGFloat = 4.0
    private let bgViewShadowRadius: CGFloat = 8.0
    private var position: Position?
    private var bgShowShadow: Bool?

    private lazy var bgBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    private lazy var bgShadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    private lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    lazy var bgShadowView: CommentBgShadowView = {
        let view = CommentBgShadowView(frame: .zero)
        view.delegate = self
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.addSublayer(bgShadowLayer)
        view.layer.addSublayer(bgBorderLayer)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        self.update()
    }

    func update() {
        if let position = position,
           let shadow = bgShowShadow {
            addRoundCornerToBgView(position: position, shadow: shadow)
        }
    }

    enum Position {
        case top
        case middle
        case bottom
    }
    
    func addRoundCornerToBgView(position: Position, shadow: Bool) {
        self.position = position
        self.bgShowShadow = shadow
        let bgRect = bgShadowView.bounds
        guard bgRect.size.height > 0 else {
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let cornerRaduis: CGFloat = bgViewCornerRadius
        let maskRaduisOffset: CGFloat = bgViewShadowRadius * 2
        let shadowPath: CGMutablePath = CGMutablePath()
        let bgBorderPath: CGMutablePath?

        let shadowMaskPath: CGMutablePath = CGMutablePath()
        var maskRect: CGRect = bgRect.insetBy(dx: -maskRaduisOffset, dy: -maskRaduisOffset)

        if position == .top {
            maskRect.size.height -= maskRaduisOffset
            shadowMaskPath.addRect(maskRect)
            shadowPath.move(to: CGPoint(x: bgRect.minX, y: bgRect.maxY))
            shadowPath.addArc(tangent1End: CGPoint(x: bgRect.minX, y: bgRect.minY), tangent2End: CGPoint(x: bgRect.midX, y: bgRect.minY), radius: cornerRaduis)
            shadowPath.addArc(tangent1End: CGPoint(x: bgRect.maxX, y: bgRect.minY), tangent2End: CGPoint(x: bgRect.maxX, y: bgRect.midY), radius: cornerRaduis)
            shadowPath.addLine(to: CGPoint(x: bgRect.maxX, y: bgRect.maxY))
            bgBorderPath = shadowPath
        } else if position == .bottom {
            maskRect.origin.y += maskRaduisOffset
            maskRect.size.height -= maskRaduisOffset
            shadowMaskPath.addRect(maskRect)
            shadowPath.move(to: CGPoint(x: bgRect.minX, y: bgRect.minY))
            shadowPath.addArc(tangent1End: CGPoint(x: bgRect.minX, y: bgRect.maxY), tangent2End: CGPoint(x: bgRect.midX, y: bgRect.maxY), radius: cornerRaduis)
            shadowPath.addArc(tangent1End: CGPoint(x: bgRect.maxX, y: bgRect.maxY), tangent2End: CGPoint(x: bgRect.maxX, y: bgRect.midY), radius: cornerRaduis)
            shadowPath.addLine(to: CGPoint(x: bgRect.maxX, y: bgRect.minY))
            bgBorderPath = shadowPath
        } else {
            maskRect.origin.y += maskRaduisOffset
            maskRect.size.height -= 2 * maskRaduisOffset
            shadowMaskPath.addRect(maskRect)
            shadowPath.addRect(bgRect)

            bgBorderPath = CGMutablePath()
            bgBorderPath?.move(to: CGPoint(x: bgRect.minX, y: bgRect.minY))
            bgBorderPath?.addLine(to: CGPoint(x: bgRect.minX, y: bgRect.maxY))
            bgBorderPath?.move(to: CGPoint(x: bgRect.maxX, y: bgRect.minY))
            bgBorderPath?.addLine(to: CGPoint(x: bgRect.maxX, y: bgRect.maxY))
        }

        bgBorderLayer.lineWidth = bgLineWith
        bgBorderLayer.path = bgBorderPath
        bgBorderLayer.strokeColor = UIColor.ud.N300.cgColor
        bgBorderLayer.fillColor = UIColor.clear.cgColor

        if shadow {
            bgShadowLayer.path = shadowPath
            bgShadowLayer.shadowPath = shadowPath
            bgShadowLayer.shadowRadius = bgViewShadowRadius
            bgShadowLayer.shadowOpacity = 1.0
            bgShadowLayer.shadowOffset = CGSize(width: 0, height: 0)
            bgShadowLayer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)
            bgShadowLayer.ud.setFillColor(UIColor.ud.bgFloat)
            maskLayer.path = shadowMaskPath
            bgShadowLayer.mask = maskLayer
        } else {
            maskLayer.path = shadowMaskPath
            bgShadowLayer.mask = maskLayer
            bgShadowLayer.shadowPath = nil
            bgShadowLayer.shadowOpacity = 0.0
            bgShadowLayer.shadowRadius = 0
            bgShadowLayer.fillColor = UIColor.clear.cgColor
        }

        CATransaction.commit()
    }

    @objc
    func didHightLightTap(sender: UIGestureRecognizer) {
        if let curCommment = curCommment {
            highLightDelegate?.didHighLightTap(comment: curCommment, cell: self)
        }
    }
    
    func _setupBgView() -> UIView {
        let bg = UIView(frame: .zero)
        bg.backgroundColor = UIColor.ud.bgFloat
        bg.layer.shadowRadius = 8
        bg.layer.cornerRadius = 8
        bg.layer.masksToBounds = true
        bg.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        bg.layer.shadowOpacity = 1.0
        bg.layer.shadowOffset = CGSize(width: 0, height: 0)

        let bgColorView = UIView(frame: .zero)
        bgColorView.backgroundColor = UIColor.ud.bgFloat
        bgColorView.layer.cornerRadius = 8
        bgColorView.layer.masksToBounds = true
        bgColorView.layer.borderWidth = 0.5
        bgColorView.layer.ud.setBorderColor(UIColor.ud.N300)
        bgColorView.tag = 999
        bg.addSubview(bgColorView)
        bgColorView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return bg
    }
}

extension CommentShadowBaseCell: CommentBgShadowViewDelegate {
    func didBgShadowViewChangeHeight() {
        self.update()
    }
}

protocol CommentBgShadowViewDelegate: NSObjectProtocol {
    func didBgShadowViewChangeHeight()
}

class CommentBgShadowView: UIView {
    var lastHeight: CGFloat = 0
    weak var delegate: CommentBgShadowViewDelegate?
    override func layoutSubviews() {
        super.layoutSubviews()
        let currentHeight = self.frame.size.height
        if lastHeight != currentHeight {
            delegate?.didBgShadowViewChangeHeight()
        }
    }
}
