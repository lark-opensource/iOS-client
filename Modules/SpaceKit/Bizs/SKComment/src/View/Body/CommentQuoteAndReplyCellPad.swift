//
//  CommentQuoteAndReplyCellPad.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/2/3.
// swiftlint:disable line_length

import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignIcon

class CommentQuoteAndReplyCellPad: CommentQuoteAndReplyCell {

    private var hightLightBarHeight: CGFloat = 4.0
    private var showHightLight: Bool = false

    lazy var highlightBarMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()
    lazy var highlightBarCornerLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.mask = highlightBarMaskLayer
        return layer
    }()
    // 顶部高亮黄条
    lazy var highlightBar: CommentHighlightBar = {
        let view = CommentHighlightBar(frame: .zero)
        view.layer.addSublayer(highlightBarCornerLayer)
        view.isHidden = true
        view.delegate = self
        return view
    }()

    lazy var moreBtn: UIButton = {
        let btn = DocsButton(frame: .zero)
        btn.widthInset = -8
        btn.heightInset = -8
        btn.addTarget(self, action: #selector(moreTap), for: .touchUpInside)
        let image = UDIcon.getIconByKey(.moreOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN2, size: .init(width: 16, height: 16))
        btn.setImage(image, for: .normal)
        btn.docs.addHighlight(with: UIEdgeInsets(top: -2, left: -4, bottom: -2, right: -4), radius: 4)
        return btn
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        updateHighBar()
    }

    func updateHighBar() {
        if showHightLight {
            addHightLight(show: showHightLight)
        }
    }

    func addHightLight(show: Bool) {
        let isNewInput = curCommment?.isNewInput ?? false
        resolveBtn.isHidden = isNewInput || (!canResolve)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        showHightLight = show
        highlightBar.isHidden = !show
        let highlightBarRect = highlightBar.bounds
        if show {
            if highlightBarRect.width > 0 {
                let bezierPath: UIBezierPath = UIBezierPath(roundedRect: highlightBarRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: bgViewCornerRadius, height: bgViewCornerRadius))
                highlightBarCornerLayer.path = bezierPath.cgPath
                highlightBarCornerLayer.fillColor = UIColor.ud.colorfulYellow.cgColor

                var maskRect = highlightBarRect
                maskRect.size.height = hightLightBarHeight
                highlightBarMaskLayer.path = UIBezierPath(rect: maskRect).cgPath
            }
        }
        CATransaction.commit()
    }

    override func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(bgShadowView)
        contentView.addSubview(highlightBar)
        contentView.addSubview(line)
        contentView.addSubview(quote)
        contentView.addSubview(resolveBtn)
        contentView.addSubview(moreBtn)

        bgShadowView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(bgShadowLeftRightGap)
            make.right.equalToSuperview().offset(-bgShadowLeftRightGap)
        }
        highlightBar.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(bgShadowView)
            make.height.equalTo(2 * bgViewCornerRadius)
        }
        line.snp.makeConstraints { (make) in
            make.width.equalTo(2)
            make.height.equalTo(14)
            make.left.equalTo(bgShadowView).offset(12)
            make.top.equalTo(bgShadowView).offset(13)
            make.bottom.equalTo(bgShadowView).offset(-13)
        }

        quote.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.right.equalTo(moreBtn.snp.left).offset(-16)
            make.left.equalTo(line.snp.right).offset(5)
            make.centerY.equalTo(line.snp.centerY)
        }

        resolveBtn.snp.makeConstraints { (make) in
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.right.equalTo(bgShadowView).offset(-12)
            make.centerY.equalTo(line.snp.centerY)
        }

        moreBtn.snp.makeConstraints { (make) in
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.right.equalTo(resolveBtn.snp.left)
            make.centerY.equalTo(resolveBtn)
        }
    }

    override func updateResolveStyle(_ style: Style = .onlyResolve) {
        switch style {
        case .onlyResolve:
            moreBtn.isHidden = true
            resolveBtn.isHidden = !canResolve
            moreBtn.snp.updateConstraints { make in
                make.width.equalTo(0)
                make.right.equalTo(resolveBtn.snp.left)
            }
        case .onlyMore:
            moreBtn.isHidden = false
            resolveBtn.isHidden = true
            moreBtn.snp.updateConstraints { make in
                make.width.equalTo(30)
                make.right.equalTo(resolveBtn.snp.left).offset(26)
            }
        case .coexist:
            moreBtn.isHidden = false
            resolveBtn.isHidden = !canResolve
            moreBtn.snp.updateConstraints { make in
                make.width.equalTo(30)
                make.right.equalTo(resolveBtn.snp.left)
            }
        }
        let isNewInput = curCommment?.isNewInput ?? false
        if isNewInput {
            resolveBtn.isHidden = true
            moreBtn.isHidden = true
        }
    }
    @objc
    func moreTap() {
        self.delegate?.didClickMoreBtn(from: moreBtn, comment: curCommment)
    }

}

extension CommentQuoteAndReplyCellPad: CommentHighlightBarDelegate {
    func didHighlightBarChangeHeight() {
        self.updateHighBar()
    }
}

protocol CommentHighlightBarDelegate: NSObjectProtocol {
    func didHighlightBarChangeHeight()
}

class CommentHighlightBar: UIView {
    var lastHeight: CGFloat = 0
    weak var delegate: CommentHighlightBarDelegate?
    override func layoutSubviews() {
        super.layoutSubviews()
        let currentHeight = self.frame.size.height
        if lastHeight != currentHeight {
            delegate?.didHighlightBarChangeHeight()
        }
    }
}
