//
//  LabEffectBgCell.swift
//  ByteView
//
//  Created by wangpeiran on 2021/3/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import ByteViewNetwork
import UniverseDesignIcon
import ByteViewUI

class LabEffectBgCell: UICollectionViewCell {
    struct Layout {
        static func cellImageWidth() -> CGFloat { Layout.isRegular() ? 78 : 48 }
        static let cellCornerRadius: CGFloat = 8
        static let borderCornerRadius: CGFloat = 10
        static func cellBorderWidth() -> CGFloat { Layout.isRegular() ? 2.5 : 2 }
        static func cellBorderGapSize() -> CGFloat { Layout.isRegular() ? 4 : 2 }
        static func iconSize() -> CGFloat { Layout.isRegular() ? 32 : 20 }
        static let smallImageSize: CGFloat = 48
        static func titleTopMargin() -> CGFloat { Layout.isRegular() ? 8 : 6 }
        static func titleHeight() -> CGFloat { Layout.isRegular() ? 20 : 13 }
        static let loadingViewSize: CGFloat = 20
        static func cellBorderTotalWidth() -> CGFloat { Layout.cellBorderWidth() + Layout.cellBorderGapSize() }
        static let dotTopMargin: CGFloat = 6
        static func dotHeight() -> CGFloat { Layout.isRegular() ? 6 : 4 }

        static func isRegular() -> Bool {
            return VCScene.rootTraitCollection?.isRegular ?? false
        }
    }

    private lazy var layerContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.borderCornerRadius
        view.layer.borderWidth = CGFloat(Layout.cellBorderWidth())
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.cellCornerRadius
        view.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1)
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = Layout.cellCornerRadius
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    // 图标
    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: Layout.isRegular() ? 14 : 10, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var dotView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.dotHeight() / 2
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    private var loadingView: LoadingView = {
        let loadingView = LoadingView(frame: CGRect(x: 0, y: 0, width: Layout.loadingViewSize, height: Layout.loadingViewSize), style: .white)
        return loadingView
    }()

    private var loadingContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgMask
        view.isHidden = true
        return view
    }()

    var model: ByteViewEffectModel?

    override init(frame: CGRect) {
        super.init(frame: frame)

        switchSelectedState(selected: true)

        addSubview(layerContainerView)
        addSubview(titleLabel)
        addSubview(dotView)
        layerContainerView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(iconView)
        containerView.addSubview(loadingContainerView)
        loadingContainerView.addSubview(loadingView)

        layerContainerView.snp.makeConstraints { maker in
            maker.centerX.left.right.equalToSuperview()
            maker.height.equalTo(layerContainerView.snp.width)
        }

        containerView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().offset(Layout.cellBorderGapSize())
        }

        // 初始和cell差不多大，但是不同样式会变
        imageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(Layout.cellBorderGapSize())
        }

        iconView.snp.makeConstraints { maker in
            maker.size.equalTo(Layout.iconSize())
            maker.center.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { maker in
            maker.width.equalTo(contentView)
            maker.bottom.equalTo(dotView.snp.top).offset(-Layout.dotTopMargin)
            maker.centerX.equalToSuperview()
            maker.height.equalTo(Layout.titleHeight())
        }

        dotView.snp.makeConstraints { maker in
            maker.bottom.equalTo(contentView)
            maker.centerX.equalToSuperview()
            maker.size.equalTo(CGSize(width: Layout.dotHeight(), height: Layout.dotHeight()))
        }

        loadingContainerView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        loadingView.snp.makeConstraints { maker in
            maker.size.equalTo(Layout.loadingViewSize)
            maker.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindData(model: ByteViewEffectModel, account: AccountInfo) {
        self.model = model

        switchSelectedState(selected: model.isSelected)
        let iconColor = model.isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.iconN2

        titleLabel.text = model.title
        self.dotView.isHidden = true

        switch model.bgType {
        case .none, .auto, .customize:
            self.iconView.isHidden = false
            self.iconView.image = UDIcon.getIconByKey(model.icon ?? .banOutlined, iconColor: iconColor, size: CGSize(width: Layout.iconSize(), height: Layout.iconSize()))
            self.imageView.image = nil
            self.imageView.isHidden = true
            self.containerView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1)
            if model.labType == .animoji {
                self.containerView.backgroundColor = .clear
            }
        case .set:
            self.iconView.isHidden = true
            self.imageView.isHidden = false
            if model.labType == .retuschieren, let value = model.currentValue, value > 0 {
                self.dotView.isHidden = false
                titleLabel.textColor = iconColor
                dotView.backgroundColor = iconColor
            }
            if model.labType == .animoji {
                self.containerView.backgroundColor = .clear
            }
            if let icon = model.icon {
                self.imageView.image = UDIcon.getIconByKey(icon, iconColor: iconColor, size: CGSize(width: Layout.iconSize(), height: Layout.iconSize()))
                imageView.snp.remakeConstraints { maker in
                    maker.size.equalTo(Layout.iconSize())
                    maker.center.equalToSuperview()
                }
                imageView.layer.cornerRadius = 0
            } else {
                self.imageView.vc.setImage(url: model.effectModel.iconDownloadURLs[0], accessToken: account.accessToken)
                imageView.snp.remakeConstraints { maker in
                    maker.edges.equalToSuperview()
                }
            }
        }
        containerView.snp.remakeConstraints { maker in
            maker.size.equalTo(Layout.cellImageWidth())
            maker.center.equalToSuperview()
        }
        if isHasTitle(labType: model.labType) {
            titleLabel.isHidden = false
            layerContainerView.snp.remakeConstraints { maker in
                maker.top.left.right.equalToSuperview()
                maker.height.equalTo(layerContainerView.snp.width)
            }
        } else {
            titleLabel.isHidden = true
            layerContainerView.snp.remakeConstraints { maker in
                maker.centerX.left.right.equalToSuperview()
                maker.height.equalTo(layerContainerView.snp.width)
            }
        }
        titleLabel.snp.remakeConstraints { maker in
            maker.width.equalTo(contentView)
            if model.labType == .filter {
                maker.bottom.equalToSuperview()
            } else {
                maker.bottom.equalTo(dotView.snp.top).offset(-Layout.dotTopMargin)
            }
            maker.centerX.equalToSuperview()
            maker.height.equalTo(Layout.titleHeight())
        }
    }

    private func switchSelectedState(selected: Bool) {
        layerContainerView.layer.vc.borderColor = selected ? UIColor.ud.primaryContentDefault : nil
        titleLabel.textColor = selected ? UIColor.ud.primaryContentDefault : UIColor.ud.textCaption
    }

    private func isHasTitle(labType: EffectType) -> Bool {
        switch labType {
        case .animoji:
            return false
        default:
            return true
        }
    }

    func playLoading() {
        loadingContainerView.isHidden = false
        loadingView.play()
    }

    func stopLoading() {
        loadingView.stop()
        self.loadingContainerView.isHidden = true
    }
}
