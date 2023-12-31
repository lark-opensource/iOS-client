//
//  ReactionDetailHeaderView.swift
//  Calendar
//
//  Created by pluto on 2023/5/24.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignIcon

final class ReactionDetailHeaderView: UIView {
    static let defaultHeight: CGFloat = 42
    typealias OnTap = (_ headerView: ReactionDetailHeaderView) -> Void
    private var contentView: UIView = UIView()
    private var titleLabel: UILabel = UILabel()
    private var closeButton: UIButton = UIButton()

    /// tap close button
    var onTapClose: OnTap?

    /// tap header view
    var onTap: OnTap?

    override var frame: CGRect {
        didSet {
            makeCornerRadius()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)

        contentView.backgroundColor = UIColor.ud.bgBody
        titleLabel.text = I18n.Calendar_Detail_ResponseDetails_PageTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        closeButton.setImage(UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        contentView.snp.makeConstraints { (maker) in
            maker.left.bottom.right.equalToSuperview()
            maker.height.equalTo(ReactionDetailHeaderView.defaultHeight)
        }

        titleLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(self.safeAreaLayoutGuide.snp.left).inset(16)
            maker.top.equalToSuperview().inset(16)
        }

        closeButton.snp.makeConstraints { (maker) in
            maker.right.equalTo(self.safeAreaLayoutGuide.snp.right).inset(12)
            maker.top.equalToSuperview().inset(12)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTap))
        tap.numberOfTapsRequired = 1
        addGestureRecognizer(tap)

        contentView.accessibilityIdentifier = "reaction.detail.header.contentView"
        titleLabel.accessibilityIdentifier = "reaction.detail.header.titleLabel"
        closeButton.accessibilityIdentifier = "reaction.detail.header.close"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 绘制圆角
    private func makeCornerRadius() {
        contentView.layer.mask = nil
        let maskPath = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 10, height: 10)
        )
        let maskLayer = CAShapeLayer()
        maskLayer.frame = contentView.bounds
        maskLayer.path = maskPath.cgPath
        contentView.layer.mask = maskLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        makeCornerRadius()
    }

    @objc
    private func close(_ button: UIButton) {
        onTapClose?(self)
    }

    @objc
    private func headerTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        onTap?(self)
    }
}
