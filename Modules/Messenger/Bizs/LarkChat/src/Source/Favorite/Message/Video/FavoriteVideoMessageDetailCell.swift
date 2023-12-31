//
//  FavoriteVideoMessageDetailCell.swift
//  LarkFavorite
//
//  Created by K3 on 2018/8/23.
//

import UIKit
import Foundation
import ByteWebImage
import EENavigator
import LarkMessageCore
import LarkMessengerInterface

final class FavoriteVideoMessageDetailCell: FavoriteMessageDetailCell {
    override class var identifier: String {
        return FavoriteVideoMessageViewModel.identifier
    }

    private var videoViewModel: FavoriteVideoMessageViewModel? {
        return viewModel as? FavoriteVideoMessageViewModel
    }

    private let favoriteImageView = UIImageView()
    private var iconImageView: UIImageView = {
        return UIImageView(image: Resources.favorite_video_play)
    }()

    private let noPermissionPreviewLayerView = NoPermissonPreviewLayerView()

    override public func setupUI() {
        super.setupUI()
        favoriteImageView.backgroundColor = UIColor.ud.N300
        favoriteImageView.layer.ud.setBorderColor(UIColor.ud.N300)
        favoriteImageView.layer.borderWidth = 1.0
        favoriteImageView.contentMode = .scaleAspectFit
        favoriteImageView.clipsToBounds = true
        favoriteImageView.lu.addTapGestureRecognizer(action: #selector(imageViewDidTapped(_:)), target: self)
        favoriteImageView.layer.cornerRadius = 4
        container.addSubview(favoriteImageView)
        iconImageView.contentMode = .scaleAspectFit
        container.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(40)
            maker.center.equalTo(favoriteImageView.snp.center)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let videoViewModel = videoViewModel else { return}
        if !handleAuthority(dynamicAuthorityEnum: videoViewModel.dynamicAuthorityEnum,
                            hasPermissionPreview: videoViewModel.permissionPreview.0) {
            return
        }
        guard let videoContent = videoViewModel.messageContent else { return }
        var imageViewHeight: CGFloat = 0
        if videoContent.image.origin.width > 0 {
            imageViewHeight = bubbleContentMaxWidth / CGFloat(videoContent.image.origin.width) * CGFloat(videoContent.image.origin.height)
        }
        favoriteImageView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(imageViewHeight)
        }
        let imageSet = ImageItemSet.transform(imageSet: videoContent.image)
        let placeholder = imageSet.inlinePreview
        let key = imageSet.generateVideoMessageKey(forceOrigin: false)
        favoriteImageView.bt.setLarkImage(with: LarkImageResource.default(key: key),
                                          placeholder: placeholder,
                                          trackStart: {
                                              return TrackInfo(scene: .Chat, fromType: .media)
                                          })
    }

    @objc
    private func imageViewDidTapped(_ gesture: UIGestureRecognizer) {
        videoViewModel?.showVideo(withDispatcher: dispatcher, imageView: favoriteImageView)
    }

    //返回值：是否有权限
    private func handleAuthority(dynamicAuthorityEnum: DynamicAuthorityEnum, hasPermissionPreview: Bool) -> Bool {
        if dynamicAuthorityEnum.authorityAllowed && hasPermissionPreview {
            hideNoPermissionPreviewLayer()
            return true
        } else {
            showNoPermissionPreviewLayer(dynamicAuthorityEnum: dynamicAuthorityEnum)
            return false
        }
    }
    /// show NoPermission layer
    private func showNoPermissionPreviewLayer(dynamicAuthorityEnum: DynamicAuthorityEnum) {
        if noPermissionPreviewLayerView.superview == nil {
            noPermissionPreviewLayerView.lu.addTapGestureRecognizer(action: #selector(noPermissionDidTapped(_:)), target: self)
            noPermissionPreviewLayerView.isHidden = true
            container.addSubview(noPermissionPreviewLayerView)
            noPermissionPreviewLayerView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.height.equalTo(120)
                make.width.equalTo(200)
            }
        }
        self.favoriteImageView.isHidden = true
        self.iconImageView.isHidden = true
        noPermissionPreviewLayerView.isHidden = false
        noPermissionPreviewLayerView.setLayerType(dynamicAuthorityEnum: dynamicAuthorityEnum, previewType: .video)
    }
    @objc
    private func noPermissionDidTapped(_ sender: UIGestureRecognizer) {
        guard let window = self.window else {
            assertionFailure()
            return
        }
        guard let videoViewModel = self.videoViewModel else { return }
        if let dynamicAuthorityEnum = noPermissionPreviewLayerView.dynamicAuthorityEnum,
           !dynamicAuthorityEnum.authorityAllowed {
            videoViewModel.chatSecurity?.alertForDynamicAuthority(event: .receive, result: dynamicAuthorityEnum, from: window)
        } else {
            videoViewModel.chatSecurity?.authorityErrorHandler(event: .localVideoPreview, authResult: videoViewModel.permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
        }
    }

    /// hide NoPermission layer
    private func hideNoPermissionPreviewLayer() {
        self.favoriteImageView.isHidden = false
        self.iconImageView.isHidden = false
        noPermissionPreviewLayerView.isHidden = true
    }
}
