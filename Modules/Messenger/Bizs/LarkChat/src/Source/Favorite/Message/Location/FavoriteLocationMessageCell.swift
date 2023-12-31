//
//  FavoriteLocationMessageCell.swift
//  LarkFavorite
//
//  Created by Fangzhou Liu on 2019/6/12.
//  Copyright © 2019 Bytedance Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkCore
import LarkMessengerInterface
import LarkMessageCore
import LarkModel
import LarkUIKit
import EENavigator
import SnapKit
import ByteWebImage

public final class FavoriteLocationMessageCell: FavoriteMessageCell {

    override class var identifier: String {
        return FavoriteLocationMessageViewModel.identifier
    }

    private var locationViewModel: FavoriteLocationMessageViewModel? {
        return self.viewModel as? FavoriteLocationMessageViewModel
    }

    private lazy var favoriteLocationView: ChatLocationViewWrapper = {
        return ChatLocationViewWrapper(
            setting: ChatLocationViewStyleSetting(
                nameFont: UIFont.ud.body1,
                descriptionFont: UIFont.ud.caption1,
                imageSize: FavoriteUtil.locationScreenShotSize
            )
        )
    }()

    override public func setupUI() {
        super.setupUI()

        /// 添加卡片边框
        favoriteLocationView.backgroundColor = UIColor.clear
        favoriteLocationView.layer.ud.setBorderColor(UIColor.ud.N300)
        favoriteLocationView.layer.borderWidth = 1.0
        favoriteLocationView.layer.cornerRadius = 8
        favoriteLocationView.isUserInteractionEnabled = true
        favoriteLocationView.clipsToBounds = true
        favoriteLocationView.lu.addTapGestureRecognizer(action: #selector(locationViewDidTapped), target: self)
        contentWraper.addSubview(favoriteLocationView)

        favoriteLocationView.snp.remakeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.width.equalTo(FavoriteUtil.locationScreenShotSize.width).priority(.high)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let locationContent = locationViewModel?.messageContent else {
            return
        }
        // origin 的数据可能不是不准确的，有intact优先用intact，并根据exifOrientation决定宽高
        let originSize = locationContent.image.intactSize

        let name = locationContent.location.name.isEmpty ? BundleI18n.LarkChat.Lark_Chat_MessageReplyStatusLocation("") : locationContent.location.name
        let setting = ChatLocationViewStyleSetting(
            labelGap: locationContent.location.description_p.isEmpty ? 0 : 3.5
        )

        favoriteLocationView.set(
            name: name,
            description: locationContent.location.description_p,
            originSize: originSize,
            setting: setting,
            locationTappedCallback: { [weak self] in
                self?.locationViewDidTapped()
            },
            setLocationViewAction: { (imageView, completion) in
                let imageSet = ImageItemSet.transform(imageSet: locationContent.image)
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
                                                  completion(nil, error)
                                              }
                                          })
            },
            settingGifLoadConfig: self.locationViewModel?.userSetting?.gifLoadConfig
        )
    }

    @objc
    fileprivate func locationViewDidTapped() {
        guard let locationViewModel = self.locationViewModel else {
            assertionFailure("locationVM cannot be nil")
            return
        }
        guard let window = self.window else {
            assertionFailure()
            return
        }
        let body = LocationNavigateBody(messageID: locationViewModel.message.id,
                                        message: locationViewModel.message,
                                        source: .favorite(id: locationViewModel.favorite.id ?? ""),
                                        psdaToken: "LARK-PSDA-FavoriteDetailLocation-requestLocationAuthorization")
        locationViewModel.navigator.push(body: body, from: window)
    }
}
