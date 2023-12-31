//
//  FlagVideoMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import LarkModel
import LarkCore
import ByteWebImage
import LarkMessageCore

public final class FlagVideoMessageCell: FlagMessageCell {

    override class var identifier: String {
        return FlagVideoMessageViewModel.identifier
    }

    var videoViewModel: FlagVideoMessageViewModel? {
        return self.viewModel as? FlagVideoMessageViewModel
    }

    private let imageViewWidth: CGFloat = 120
    private let imageViewHeight: CGFloat = 120

    private lazy var flagVideoView: UIImageView = {
        return UIImageView()
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
        imageView.layer.borderWidth = 0.5
        imageView.ud.setLayerBorderColor(UIColor.ud.primaryOnPrimaryFill)
        imageView.image = UDIcon.getIconByKey(.playFilled, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        imageView.layer.cornerRadius = 12
        imageView.contentMode = .center
        return imageView
    }()

    private var retrieveTask: ImageRequest?

    override public func setupUI() {
        super.setupUI()
        flagVideoView.backgroundColor = UIColor.ud.bgFloat
        flagVideoView.layer.cornerRadius = 4
        flagVideoView.clipsToBounds = true
        flagVideoView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        flagVideoView.layer.borderWidth = 1 / UIScreen.main.scale
        flagVideoView.isUserInteractionEnabled = true
        flagVideoView.contentMode = .scaleAspectFill
        flagVideoView.lu.addTapGestureRecognizer(action: #selector(imageViewDidTapped(_:)), target: self)

        contentWraper.addSubview(flagVideoView)

        contentWraper.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(24)
            maker.center.equalTo(flagVideoView.snp.center)
        }

        flagVideoView.snp.remakeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.left.bottom.equalToSuperview()
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(imageViewHeight)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let videoViewModel = videoViewModel else { return }

        let permissionPreview = videoViewModel.permissionPreview
        if permissionPreview.0 && videoViewModel.dynamicAuthorityEnum.authorityAllowed {
            hideNoPermissionPreviewLayer()
        } else {
            showNoPermissionPreviewLayer()
            return
        }
        guard let videoContent = videoViewModel.messageContent else { return }
        let imageSet = ImageItemSet.transform(imageSet: videoContent.image)
        let key = imageSet.generateVideoMessageKey(forceOrigin: false)
        let placeholder = imageSet.inlinePreview
        let resource = LarkImageResource.default(key: key)
        flagVideoView.bt.setLarkImage(with: resource,
                                      placeholder:
                                      placeholder,
                                      trackStart: {
                                          TrackInfo(scene: .Chat, fromType: .media)
                                      })
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        retrieveTask?.cancel()
    }

    @objc
    fileprivate func imageViewDidTapped(_ gesture: UIGestureRecognizer) {
        videoViewModel?.showVideo(withDispatcher: dispatcher, imageView: flagVideoView)
    }

    private lazy var noPermissionPreviewLayerView = NoPermissonPreviewLayerView()

    private func showNoPermissionPreviewLayer() {
        iconImageView.isHidden = true
        if noPermissionPreviewLayerView.superview == nil {
            self.flagVideoView.addSubview(noPermissionPreviewLayerView)
            noPermissionPreviewLayerView.isUserInteractionEnabled = false
            noPermissionPreviewLayerView.snp.makeConstraints({ make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalToSuperview()
            })
        }
        noPermissionPreviewLayerView.isHidden = false
        noPermissionPreviewLayerView.setLayerType(dynamicAuthorityEnum: self.videoViewModel?.dynamicAuthorityEnum ?? .loading,
                                                  previewType: .video)
    }

    private func hideNoPermissionPreviewLayer() {
        iconImageView.isHidden = false
        noPermissionPreviewLayerView.isHidden = true
    }
}
