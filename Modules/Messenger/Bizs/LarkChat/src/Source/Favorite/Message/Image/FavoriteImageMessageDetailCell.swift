//
//  FavoriteImageMessageDetailCell.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/14.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import ByteWebImage
import UIKit
import LarkMessageCore
import EENavigator
import LarkMessengerInterface

final class FavoriteImageMessageDetailCell: FavoriteMessageDetailCell {

    private lazy var noPermissionPreviewLayerView = NoPermissonPreviewLayerView()

    override class var identifier: String {
        return FavoriteImageMessageViewModel.identifier
    }

    private var imageViewModel: FavoriteImageMessageViewModel? {
        return viewModel as? FavoriteImageMessageViewModel
    }

    private let favoriteImageView = ByteImageView()

    override public func setupUI() {
        super.setupUI()
        favoriteImageView.backgroundColor = UIColor.ud.bgFloat
        favoriteImageView.layer.ud.setBorderColor(UIColor.ud.N300)
        favoriteImageView.layer.borderWidth = 1.0
        favoriteImageView.animateRunLoopMode = .default
        favoriteImageView.isUserInteractionEnabled = true
        favoriteImageView.contentMode = .scaleAspectFit
        favoriteImageView.clipsToBounds = true
        favoriteImageView.lu.addTapGestureRecognizer(action: #selector(imageViewDidTapped(_:)), target: self)
        favoriteImageView.layer.cornerRadius = 4
        container.addSubview(favoriteImageView)
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let imageViewModel = imageViewModel else {
            return
        }
        let permissionPreview = imageViewModel.permissionPreview
        if !self.handleAuthority(dynamicAuthorityEnum: imageViewModel.dynamicAuthorityEnum, hasPermissionPreview: permissionPreview.0) {
            return
        }
        guard let imageContent = imageViewModel.messageContent else {
            return
        }

        var imageViewHeight: CGFloat = 0
        if imageContent.image.origin.width > 0 {
            imageViewHeight = bubbleContentMaxWidth / CGFloat(imageContent.image.origin.width) * CGFloat(imageContent.image.origin.height)
        }
        favoriteImageView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(imageViewHeight)
        }
        favoriteImageView.setImageWithAction { (imageView, completion) in
            let imageSet = ImageItemSet.transform(imageSet: imageContent.image)
            let placeholder = imageSet.inlinePreview
            let key = imageSet.generateImageMessageKey(forceOrigin: false)
            let resource = LarkImageResource.default(key: key)
            imageView.bt.setLarkImage(with: resource,
                                      placeholder: placeholder,
                                      completion: { result in
                                          switch result {
                                          case let .success(imageResult):
                                              completion(imageResult.image, nil)
                                          case let .failure(error):
                                              completion(placeholder, error)
                                          }
                                      })
        }
    }

    @objc
    private func imageViewDidTapped(_ gesture: UIGestureRecognizer) {
        imageViewModel?.showImage(withDispatcher: dispatcher, imageView: favoriteImageView)
    }
    @objc
    private func noPermissionDidTapped(_ sender: UIGestureRecognizer) {
        guard let window = self.window else {
            assertionFailure()
            return
        }
        guard let imageViewModel = self.imageViewModel else { return }
        if !imageViewModel.dynamicAuthorityEnum.authorityAllowed {
            //优先为动态权限弹窗
            imageViewModel.chatSecurity?.alertForDynamicAuthority(event: .receive,
                                                                 result: imageViewModel.dynamicAuthorityEnum,
                                                                 from: window)
            return
        }
        imageViewModel.chatSecurity?.authorityErrorHandler(event: .localImagePreview, authResult: imageViewModel.permissionPreview.1, from: window, errorMessage: nil, forceToAlert: true)
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

    /// show noPermission layer
    private func showNoPermissionPreviewLayer(dynamicAuthorityEnum: DynamicAuthorityEnum) {
        favoriteImageView.isHidden = true
        if noPermissionPreviewLayerView.superview == nil {
            container.addSubview(noPermissionPreviewLayerView)
            noPermissionPreviewLayerView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.height.equalTo(120)
                make.width.equalTo(200)
            }
            noPermissionPreviewLayerView.lu.addTapGestureRecognizer(action: #selector(noPermissionDidTapped(_:)), target: self)
        }
        noPermissionPreviewLayerView.isHidden = false
        noPermissionPreviewLayerView.setLayerType(dynamicAuthorityEnum: dynamicAuthorityEnum, previewType: .image)
    }
    /// hide NoPermission layer
    private func hideNoPermissionPreviewLayer() {
        favoriteImageView.isHidden = false
        noPermissionPreviewLayerView.isHidden = true
    }
}
