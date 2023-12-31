//
//  FavoriteImageMessageCell.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
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

public final class FavoriteImageMessageCell: FavoriteMessageCell {
    override class var identifier: String {
        return FavoriteImageMessageViewModel.identifier
    }

    var imageViewModel: FavoriteImageMessageViewModel? {
        return self.viewModel as? FavoriteImageMessageViewModel
    }

    private let imageViewWidth: CGFloat = 80
    private let imageViewHeight: CGFloat = 80

    private lazy var favoriteImageView: ChatImageViewWrapper = {
        return ChatImageViewWrapper(maxSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight),
                                    minSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight))
    }()

    private lazy var noPermissonPreviewSmallLayerView: NoPermissonPreviewSmallLayerView = {
        let view = NoPermissonPreviewSmallLayerView()
        view.tapAction = { [weak self] _ in
            guard let self = self else { return }
            self.imageViewModel?.showImage(withDispatcher: self.dispatcher, imageView: self.favoriteImageView.imageView)
        }
        return view
    }()

//    private var retrieveTask: DownloadTask?

    override public func setupUI() {
        super.setupUI()
        favoriteImageView.backgroundColor = UIColor.ud.bgFloat
        favoriteImageView.layer.ud.setBorderColor(UIColor.ud.N300)
        favoriteImageView.layer.borderWidth = 1.0
        favoriteImageView.isUserInteractionEnabled = true
        favoriteImageView.imageView.adaptiveContentModel = false
        favoriteImageView.imageView.contentMode = .scaleAspectFill
        favoriteImageView.clipsToBounds = true
        favoriteImageView.layer.cornerRadius = 4
        favoriteImageView.imageView.autoPlayAnimatedImage = false
        favoriteImageView.imageView.origionSize = CGSize(width: self.imageViewWidth, height: self.imageViewHeight)
        favoriteImageView.imageView.stopAnimating()

        contentWraper.addSubview(favoriteImageView)

        favoriteImageView.snp.remakeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(imageViewHeight)
        }
        favoriteImageView.addSubview(noPermissonPreviewSmallLayerView)
        noPermissonPreviewSmallLayerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let imageViewModel = imageViewModel else { return }
        let permissionPreview = imageViewModel.permissionPreview
        noPermissonPreviewSmallLayerView.isHidden = permissionPreview.0 && imageViewModel.dynamicAuthorityEnum.authorityAllowed
        guard let imageContent = imageViewModel.messageContent else { return }
        let imageItemSet = ImageItemSet.transform(imageSet: imageContent.image)
        let imageKey = imageItemSet.generateImageMessageKey(forceOrigin: false)
        let placeholder = imageItemSet.inlinePreview
        let resource = LarkImageResource.default(key: imageKey)
        let metrics: [String: String] = [
            "message_id": imageViewModel.message.id ?? ""
        ]
        favoriteImageView.set(
            originSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight),
            needLoading: imageItemSet.inlinePreview == nil,
            animatedDelegate: nil,
            forceStartIndex: 0,
            forceStartFrame: nil,
            imageTappedCallback: { [weak self] _ in
                guard let self = self else { return }
                self.imageViewModel?.showImage(withDispatcher: self.dispatcher, imageView: self.favoriteImageView.imageView)
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
//        retrieveTask?.cancel()
    }
}
