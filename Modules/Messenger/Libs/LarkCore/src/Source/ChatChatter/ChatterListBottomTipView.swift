//
//  ChatterListBottomTipView.swift
//  Action
//
//  Created by kongkaikai on 2019/2/19.
//

import Foundation
import UIKit
import SnapKit

public final class ChatterListBottomTipView: UIView {
    public var title: String? {
        didSet { tipLabel.text = title }
    }

    public var alphaCoverViewHeight: CGFloat = 68 {
        didSet { alphaCoverView.snp.updateConstraints { $0.height.equalTo(alphaCoverViewHeight) } }
    }

    private var tipLabel: UILabel
    private var alphaCoverView: UIView
    private var alphaLayer: CAGradientLayer

    public override init(frame: CGRect) {
        tipLabel = UILabel()
        alphaCoverView = UIView()
        alphaLayer = CAGradientLayer()

        super.init(frame: frame)

        tipLabel.font = UIFont.systemFont(ofSize: 12)
        tipLabel.textColor = UIColor.ud.textPlaceholder
        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 0
        addSubview(tipLabel)
        tipLabel.snp.makeConstraints({ (maker) in
            maker.center.equalToSuperview()
            maker.left.greaterThanOrEqualToSuperview().offset(16)
            maker.right.lessThanOrEqualToSuperview().offset(-16)
        })

        alphaCoverView.layer.insertSublayer(alphaLayer, at: 0)
        addSubview(alphaCoverView)
        alphaCoverView.snp.makeConstraints({ (maker) in
            maker.bottom.equalTo(self.snp.top)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(alphaCoverViewHeight)
        })
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        alphaLayer.frame = alphaCoverView.bounds
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        alphaLayer.colors = [UIColor.ud.bgBody.withAlphaComponent(0.8), UIColor.ud.bgBody]
    }

    public static func defaultFrame(_ maxWidth: CGFloat) -> CGRect {
        return CGRect(origin: .zero, size: CGSize(width: maxWidth, height: 76))
    }
}
