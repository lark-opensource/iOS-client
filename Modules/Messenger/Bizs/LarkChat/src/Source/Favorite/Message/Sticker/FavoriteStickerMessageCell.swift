//
//  FavoriteStickerMessageCell.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkModel
import LarkCore
import LarkMessageCore
import ByteWebImage

public final class FavoriteStickerMessageCell: FavoriteMessageCell {
    override public class var identifier: String {
        return FavoriteStickerMessageViewModel.identifier
    }

    private let imageViewWidth: CGFloat = 80
    private let imageViewHeight: CGFloat = 80

    var retrieveTask: ImageRequest?

    private var stickerViewModel: FavoriteStickerMessageViewModel? {
        return viewModel as? FavoriteStickerMessageViewModel
    }

    private lazy var stickerView: ChatImageViewWrapper = {
        return ChatImageViewWrapper(maxSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight),
                                    minSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight))
    }()

    override public func setupUI() {
        super.setupUI()

        stickerView.backgroundColor = .clear
        stickerView.layer.ud.setBorderColor(UIColor.ud.N300)
        stickerView.layer.borderWidth = 1.0
        stickerView.isUserInteractionEnabled = true
        stickerView.imageView.adaptiveContentModel = false
        stickerView.imageView.contentMode = .scaleAspectFill
        stickerView.layer.cornerRadius = 4
        stickerView.layer.masksToBounds = true
        stickerView.imageView.autoPlayAnimatedImage = false
        stickerView.imageView.stopAnimating()

        contentWraper.addSubview(stickerView)

        stickerView.snp.remakeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(imageViewHeight)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let stickerContent = stickerViewModel?.messageContent else {
            return
        }

        let key = stickerContent.key
        let metrics: [String: String] = ["message_id": stickerViewModel?.message.id ?? ""]
        stickerView.set(
            originSize: CGSize(width: self.imageViewWidth, height: self.imageViewHeight),
            dynamicAuthorityEnum: .allow,
            needLoading: true,
            animatedDelegate: nil,
            forceStartIndex: 0,
            forceStartFrame: nil,
            imageTappedCallback: { [weak self] _ in
                guard let self = self else { return }
                self.stickerViewModel?.showSticker(withDispatcher: self.dispatcher, imageView: self.stickerView.imageView)
            },
            setImageAction: { (imageView, completion) in
                imageView.bt.setLarkImage(with: .sticker(key: key, stickerSetID: stickerContent.stickerSetID),
                                          trackStart: {
                                            TrackInfo(scene: .Favorite,
                                                      fromType: .sticker,
                                                      metric: metrics)
                                          },
                                          completion: { result in
                                            switch result {
                                            case .success(let imageResult):
                                                completion(imageResult.image, nil)
                                            case .failure(let error):
                                                completion(nil, error)
                                            }
                                          })
            }, settingGifLoadConfig: self.stickerViewModel?.userSetting?.gifLoadConfig
        )
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        retrieveTask?.cancel()
    }
}
