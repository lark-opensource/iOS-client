//
//  FavoriteStickerMessageDetailCell.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/14.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import ByteWebImage
import LarkModel

final class FavoriteStickerMessageDetailCell: FavoriteMessageDetailCell {

    override class var identifier: String {
        return FavoriteStickerMessageViewModel.identifier
    }

    private var stickerViewModel: FavoriteStickerMessageViewModel? {
        return viewModel as? FavoriteStickerMessageViewModel
    }

    private let stickerView = ByteImageView()

    override public func setupUI() {
        super.setupUI()

        stickerView.backgroundColor = .clear
        stickerView.layer.ud.setBorderColor(UIColor.ud.N300)
        stickerView.layer.borderWidth = 1.0
        stickerView.animateRunLoopMode = .default
        stickerView.isUserInteractionEnabled = true
        stickerView.contentMode = .scaleAspectFit
        stickerView.clipsToBounds = true
        stickerView.lu.addTapGestureRecognizer(action: #selector(imageViewDidTapped(_:)), target: self)
        stickerView.layer.cornerRadius = 4

        container.addSubview(stickerView)
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let stickerContent = stickerViewModel?.messageContent else {
            return
        }

        var imageViewHeight: CGFloat = 0
        if stickerContent.width > 0 {
            imageViewHeight = bubbleContentMaxWidth / CGFloat(stickerContent.width) * CGFloat(stickerContent.height)
        }
        stickerView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(imageViewHeight)
        }
        let key = stickerContent.key
        stickerView.setImageWithAction { (imageView, completion) in
            imageView.bt.setLarkImage(with: .sticker(key: key, stickerSetID: stickerContent.stickerSetID),
                                      trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .sticker)
                                      },
                                      completion: { result in
                                        switch result {
                                        case .success(let imageResult):
                                            completion(imageResult.image, nil)
                                        case .failure(let error):
                                            completion(nil, error)
                                        }
                                      })
        }
    }

    @objc
    private func imageViewDidTapped(_ gesture: UIGestureRecognizer) {
        stickerViewModel?.showSticker(withDispatcher: dispatcher, imageView: stickerView)
    }
}
