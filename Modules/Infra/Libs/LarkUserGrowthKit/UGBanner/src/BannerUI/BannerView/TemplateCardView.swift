//
//  TemplateCardView.swift
//  LarkBanner
//
//  Created by mochangxing on 2020/12/29.
//

import UIKit
import Foundation
import LarkUIKit

final class TemplateCardView: UIView {
    private let contentView = UIView()
    private let frontImageView = UIImageView()
    private let backgroundImageView = UIImageView()
    private let cardModel: TemplateCardModel
    private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.boldSystemFont(ofSize: 12)
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    var tapBlock: (() -> Void)?

    private lazy var titleBottom: CGFloat = {
        switch cardModel.layout {
        case .style1, .style2:
            return 0
        case .style3, .style4:
            return -7
        @unknown default:
            return 0
        }
    }()

    private lazy var contentHeight: CGFloat = {
        switch cardModel.layout {
        case .style1:
            return 94
        case .style2:
            return 122
        case .style3, .style4:
            return 122
        @unknown default:
            return 122
        }
    }()

    private lazy var frontImageSize: CGSize = {
        switch cardModel.layout {
        case .style1:
            return CGSize(width: 88, height: 72)
        case .style2, .style3, .style4:
            return CGSize(width: 160, height: 56)
        @unknown default:
            return CGSize(width: 160, height: 56)
        }
    }()

    private lazy var backgroundImageSize: CGSize = {

        switch cardModel.layout {
        case .style1:
            return CGSize(width: 88, height: 72)
        case .style2, .style3, .style4:
            return CGSize(width: 170, height: 122)
        @unknown default:
            return CGSize(width: 170, height: 122)
        }
    }()

    init(cardModel: TemplateCardModel) {
        self.cardModel = cardModel
        super.init(frame: .zero)
        setupSubviews()
        bindData()
        // 点击view
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler(ges:)))
        self.addGestureRecognizer(tap)
    }

    @objc
    fileprivate func tapHandler(ges: UIGestureRecognizer) {
        self.tapBlock?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        self.clipsToBounds = true
        contentView.layer.cornerRadius = 6
        self.addSubview(contentView)
        self.addSubview(backgroundImageView)
        self.addSubview(frontImageView)
        self.addSubview(titleLabel)
        titleLabel.numberOfLines = cardModel.layout == .style1 ? 2 : 1

        contentView.snp.makeConstraints { (make) in
            make.top.left.width.equalToSuperview()
            make.height.equalTo(self.contentHeight)
        }

        backgroundImageView.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(self.backgroundImageSize)
        }

        frontImageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            if self.cardModel.layout == .style1 {
                make.top.equalToSuperview()
            } else {
                make.bottom.equalToSuperview().offset(-32)
            }
            make.size.equalTo(self.frontImageSize)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(2)
            make.trailing.equalToSuperview().offset(-2)
            if self.cardModel.layout == .style1 {
                make.top.equalTo(frontImageView.snp.bottom).offset(8)
            } else {
                make.bottom.equalToSuperview().offset(self.titleBottom)
            }
        }
    }

    func bindData() {
        titleLabel.text = cardModel.categoryName

        if !cardModel.bgImageUrl.isEmpty {
            backgroundImageView.contentMode = .scaleAspectFit
            backgroundImageView.bt.setLarkImage(with: .default(key: cardModel.bgImageUrl))
        }
        if !cardModel.fgImageUrl.isEmpty {
            frontImageView.bt.setLarkImage(with: .default(key: cardModel.fgImageUrl))
        }

        if !cardModel.backgroundColor.isEmpty {
            contentView.backgroundColor = UIColor.rgba(cardModel.backgroundColor)
        }
        if cardModel.layout == .style1 {
            backgroundImageView.layer.ud.setShadowColor(UIColor.ud.color(0, 0, 0, 0.05))
            backgroundImageView.layer.shadowOpacity = 1
            backgroundImageView.layer.shadowRadius = 0
            backgroundImageView.layer.shadowOffset = CGSize(width: 0, height: 2)

            frontImageView.layer.ud.setShadowColor(UIColor.ud.color(0, 0, 0, 0.05))
            frontImageView.layer.shadowOpacity = 1
            frontImageView.layer.shadowRadius = 0
            frontImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        } else {
            if let frameColor = cardModel.frameColor {
                contentView.layer.borderWidth = 1
                contentView.layer.ud.setBorderColor(UIColor.rgba(frameColor))
            }
            contentView.layer.ud.setShadowColor(UIColor.ud.color(0, 0, 0, 0.05))
            contentView.layer.shadowOpacity = 1
            contentView.layer.shadowRadius = 12
            contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }
}
