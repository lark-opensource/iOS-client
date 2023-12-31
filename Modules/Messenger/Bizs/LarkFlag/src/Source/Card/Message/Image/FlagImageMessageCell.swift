//
//  FlagImageMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import Kingfisher
import LarkModel
import LarkCore
import LarkMessageCore
import ByteWebImage

public final class FlagImageMessageCell: FlagMessageCell {

    override class var identifier: String {
        return FlagImageMessageViewModel.identifier
    }

    var imageViewModel: FlagImageMessageViewModel? {
        return self.viewModel as? FlagImageMessageViewModel
    }

    private let imageViewWidth: CGFloat = 120
    private let imageViewHeight: CGFloat = 120

    private lazy var flagImageView: ChatImageViewWrapper = {
        return ChatImageViewWrapper(maxSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight),
                                    minSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight))
    }()

    private lazy var noPermissionPreviewLayerView = NoPermissonPreviewLayerView()

    private func showNoPermissionPreviewLayer() {
        if noPermissionPreviewLayerView.superview == nil {
            self.flagImageView.addSubview(noPermissionPreviewLayerView)
            noPermissionPreviewLayerView.snp.makeConstraints({ make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalToSuperview()
            })
        }
        noPermissionPreviewLayerView.isHidden = false
        noPermissionPreviewLayerView.setLayerType(dynamicAuthorityEnum: self.imageViewModel?.dynamicAuthorityEnum ?? .loading,
                                                  previewType: .image)
    }

    private func hideNoPermissionPreviewLayer() {
        noPermissionPreviewLayerView.isHidden = true
    }

    override public func setupUI() {
        super.setupUI()

        flagImageView.backgroundColor = UIColor.ud.bgFloat
        flagImageView.layer.cornerRadius = 4
        flagImageView.clipsToBounds = true
        flagImageView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        flagImageView.layer.borderWidth = 1 / UIScreen.main.scale
        flagImageView.isUserInteractionEnabled = true
        flagImageView.imageView.adaptiveContentModel = false
        flagImageView.imageView.contentMode = .scaleAspectFill
        flagImageView.imageView.autoPlayAnimatedImage = false
        flagImageView.imageView.origionSize = CGSize(width: self.imageViewWidth, height: self.imageViewHeight)
        flagImageView.imageView.stopAnimating()

        contentWraper.addSubview(flagImageView)

        flagImageView.snp.remakeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.left.bottom.equalToSuperview()
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(imageViewHeight)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let imageViewModel = imageViewModel else { return}
        guard !imageViewModel.message.isRecalled else {
            flagImageView.isHidden = true
            return
        }
        let permissionPreview = imageViewModel.permissionPreview
        if permissionPreview.0 && imageViewModel.dynamicAuthorityEnum.authorityAllowed {
            hideNoPermissionPreviewLayer()
        } else {
            showNoPermissionPreviewLayer()
            flagImageView.set(originSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight),
                              needLoading: false,
                              animatedDelegate: nil,
                              forceStartIndex: 0,
                              forceStartFrame: nil,
                              imageTappedCallback: { [weak self] _ in
                guard let self = self else { return }
                self.imageViewModel?.showImage(withDispatcher: self.dispatcher, imageView: self.flagImageView.imageView)
            }, setImageAction: { _, _ in })
            return
        }
        guard let imageContent = imageViewModel.messageContent else { return }
        let imageItemSet = ImageItemSet.transform(imageSet: imageContent.image)
        let imageKey = imageItemSet.generateImageMessageKey(forceOrigin: false)
        let placeholder = imageItemSet.inlinePreview
        let resource = LarkImageResource.default(key: imageKey)
        let metrics: [String: String] = [
            "message_id": imageViewModel.message.id
        ]
        flagImageView.set(
            originSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight),
            needLoading: imageItemSet.inlinePreview == nil,
            animatedDelegate: nil,
            forceStartIndex: 0,
            forceStartFrame: nil,
            imageTappedCallback: { [weak self] _ in
                guard let self = self else { return }
                self.imageViewModel?.showImage(withDispatcher: self.dispatcher, imageView: self.flagImageView.imageView)
            },
            setImageAction: { (imageView, completionHandler) in
                imageView.bt.setLarkImage(with: resource,
                                          placeholder: placeholder,
                                          trackStart: {
                                              TrackInfo(biz: .Messenger,
                                                        scene: .Favorite,
                                                        fromType: .image,
                                                        metric: metrics)
                                          },
                                          completion: { result in
                                              switch result {
                                              case let .success(res):
                                                  completionHandler(res.image, nil)
                                              case let .failure(error):
                                                  completionHandler(placeholder, error)
                                              }
                                          })
            }
        )
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
    }
}
