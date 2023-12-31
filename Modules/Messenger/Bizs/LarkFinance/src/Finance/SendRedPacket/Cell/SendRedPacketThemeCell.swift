//
//  SendRedPacketThemeCell.swift
//  Action
//
//  Created by JackZhao on 2021/11/15.
//

import Foundation
import LarkUIKit
import SnapKit
import RxCocoa
import RxSwift
import RichLabel
import UIKit
import ByteWebImage
import UniverseDesignIcon
import UniverseDesignColor

// 红包主题cell
final class SendRedPacketThemeCell: SendRedPacketBaseCell {
    // cell点击事件
    var tapHandler: (() -> Void)?

    fileprivate let contaner: UIView = UIView()

    // 主题背景
    private let theme: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    // 渐变
    let alphaLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.frame = CGRect(x: 0, y: 0, width: 240, height: 80)
        return layer
    }()

    // 标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.text = BundleI18n.LarkFinance.Lark_RedPacket_CoverDisplay
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    // 描述
    private let desciptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.text = BundleI18n.LarkFinance.Lark_RedPacket_Theme_Default
        return label
    }()

    // 向右箭头
    private let arrow: UIImageView = {
        let imageView = UIImageView(image: Resources.right_arrow)
        return imageView
    }()

    private lazy var defaultThemeImage = Resources.hongbao_open_top

    override func setupCellContent() {
        contentView.addSubview(contaner)
        contaner.backgroundColor = UIColor.ud.bgBody
        contaner.layer.cornerRadius = 10
        contaner.layer.masksToBounds = true
        contaner.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalTo(16)
            $0.bottom.equalToSuperview()
        }

        contaner.addSubview(theme)
        theme.snp.makeConstraints { (maker) in
            maker.top.right.bottom.equalToSuperview()
            maker.width.equalTo(240)
            maker.height.equalTo(48)
        }
        theme.layer.addSublayer(alphaLayer)

        contaner.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(16)
            maker.centerY.equalToSuperview()
        }

        contaner.addSubview(arrow)
        arrow.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }

        contaner.addSubview(desciptionLabel)
        desciptionLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.greaterThanOrEqualTo(titleLabel.snp.left).offset(10)
            maker.right.equalTo(arrow.snp.left).offset(-12)
        }
    }

    override func updateCellContent(_ result: RedPacketCheckResult) {
        if let name = result.content.cover?.name {
            desciptionLabel.text = name
        }
        if let cover = result.content.cover?.selectCover, cover.key.isEmpty == false {
            var pass = ImagePassThrough()
            pass.key = cover.key
            pass.fsUnit = cover.fsUnit
            theme.bt.setLarkImage(with: .default(key: cover.key),
                                  placeholder: defaultThemeImage,
                                  passThrough: pass)
        } else {
            theme.bt.setLarkImage(with: .default(key: ""),
                                  placeholder: defaultThemeImage)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        alphaLayer.colors = [UIColor.ud.bgBody.cgColor, UIColor.ud.bgBody.withAlphaComponent(0.6).cgColor]
        theme.layer.addSublayer(alphaLayer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let tapHandler = tapHandler {
            tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }
}
