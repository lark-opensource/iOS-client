//
//  StickerManageCollectionViewCell.swift
//  Lark
//
//  Created by ChalrieSu on 2017/11/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import ByteWebImage
import LarkModel
import RustPB

final class StickerManageCollectionViewCell: UICollectionViewCell {
    var model: RustPB.Im_V1_Sticker? {
        didSet {
            self.emotionView.image = nil
            self.setImageLoading(loading: true)
            if let sticker = model {
                var key = sticker.image.thumbnail.key
                if key.isEmpty {
                    //防止为空
                    key = sticker.image.origin.key
                }
                self.emotionView.bt.setLarkImage(with: .sticker(key: key, stickerSetID: sticker.stickerSetID),
                                                 trackStart: {
                                                    return TrackInfo(scene: .Chat, fromType: .sticker)
                                                 },
                                                 completion: { [weak self] result in
                                                    switch result {
                                                    case .success:
                                                        if let sticker = self?.model, (sticker.image.thumbnail.key == key || sticker.image.origin.key == key) {
                                                            self?.setImageLoading(loading: false)
                                                        }
                                                    case .failure:
                                                        break
                                                    }
                                                 })
            }
        }
    }

    var selectIndex: Int? {
        didSet {
            if let selectIndex = selectIndex {
                numberBox.number = selectIndex + 1
                self.emotionView.alpha = 0.4
            } else {
                numberBox.number = nil
                self.emotionView.alpha = 1
            }
        }
    }

    private var loadingIcon: UIImageView
    private let emotionView: ByteImageView
    private let numberBox = LKNumberBox(number: nil)

    override init(frame: CGRect) {
        emotionView = ByteImageView()
        emotionView.autoPlayAnimatedImage = false
        loadingIcon = UIImageView()

        super.init(frame: CGRect.zero)

        self.backgroundColor = UIColor.ud.commonBackgroundColor
        loadingIcon.isUserInteractionEnabled = false
        loadingIcon.contentMode = .scaleAspectFit
        loadingIcon.image = BundleResources.send_loading
        self.contentView.addSubview(loadingIcon)
        loadingIcon.snp.makeConstraints({ make in
            make.center.equalToSuperview()
            make.width.height.equalTo(15)
        })

        self.addSubview(emotionView)
        emotionView.contentMode = .scaleAspectFit
        emotionView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })

        self.addSubview(numberBox)
        numberBox.isUserInteractionEnabled = false
        numberBox.snp.makeConstraints { (make) in
            make.width.greaterThanOrEqualTo(30)
            make.height.equalTo(30)
            make.top.equalTo(3)
            make.right.equalToSuperview().offset(-3)
        }

        self.lu.addRightBorder(color: UIColor.ud.N300)
        self.lu.addBottomBorder(color: UIColor.ud.N300)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setImageLoading(loading: Bool) {
        if loading {
            self.backgroundColor = UIColor.ud.N300
            self.loadingIcon.isHidden = false
            self.loadingIcon.lu.addRotateAnimation()
        } else {
            self.backgroundColor = UIColor.clear
            self.loadingIcon.isHidden = true
            self.loadingIcon.lu.removeRotateAnimation()
        }
    }
}
