//
//  StickerEmotionCell.swift
//  Lark
//
//  Created by lichen on 2017/11/15.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LKCommonsLogging
import SkeletonView
import RustPB
import ByteWebImage
import UniverseDesignShadow

final public class StickerEmotionHeaderView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class StickerEmotionCell: UICollectionViewCell {

    static let logger = Logger.log(StickerEmotionCell.self, category: "Module.Sticker")

    lazy private var emotionView: ByteImageView = {
        let imageView = ByteImageView()
        imageView.autoPlayAnimatedImage = false
        return imageView
    }()
    private var loadingView: UIView = UIView()
    private let loadingGradient = SkeletonGradient(baseColor: UIColor.ud.N300.withAlphaComponent(0.3),
                                                   secondaryColor: UIColor.ud.N300.withAlphaComponent(0.6))

    private var floatView: StickerFloatView?

    var imageLoadCallBack: ((RustPB.Im_V1_Sticker?, ImageLoadState) -> Void)?
    var imageLoading: Bool = false

    var sticker: RustPB.Im_V1_Sticker? {
        willSet {
            if let value = self.sticker, imageLoading {
                self.imageLoadCallBack?(value, .cancel)
            }
        }
        didSet {
            self.emotionView.image = nil
            self.setImageLoading(loading: true)
            self.imageLoading = true
            let start = CACurrentMediaTime()
            if let sticker = sticker {
                var isOrigin = false
                var key = sticker.image.thumbnail.key
                if key.isEmpty {
                    key = sticker.image.origin.key
                    isOrigin = true
                }
                self.imageLoadCallBack?(self.sticker, .start)
                self.emotionView.bt.setLarkImage(with: .sticker(key: key, stickerSetID: sticker.stickerSetID),
                                                 trackStart: {
                                                    TrackInfo(scene: .Chat, isOrigin: isOrigin, fromType: .sticker)
                                                 },
                                                 completion: { [weak self] result in
                                                    self?.imageLoading = false
                                                    let end = CACurrentMediaTime()
                                                    switch result {
                                                    case .success:
                                                        self?.doInMainThread {
                                                            if let sticker = self?.sticker, (sticker.image.thumbnail.key == key || sticker.image.origin.key == key) {
                                                                self?.setImageLoading(loading: false)
                                                            }
                                                        }
                                                        self?.imageLoadCallBack?(self?.sticker, .finish(cost: end - start, error: nil))
                                                    case .failure(let error):
                                                        self?.imageLoadCallBack?(self?.sticker, .finish(cost: end - start, error: error))
                                                        StickerEmotionCell.logger.error(
                                                            "获取Sticker数据失败",
                                                            additionalData: [
                                                                "key": key
                                                            ],
                                                            error: error
                                                        )
                                                    }
                                                 })
            }
        }
    }

    private func setImageLoading(loading: Bool) {
        // 需要async，否则调用时机过早，无法显示
        DispatchQueue.main.async {
            if loading {
                self.loadingView.isHidden = false
                self.loadingView.isSkeletonable = true
                self.loadingView.showAnimatedGradientSkeleton(usingGradient: self.loadingGradient, animation: nil)
            } else {
                self.loadingView.isSkeletonable = false
                self.loadingView.stopSkeletonAnimation()
                self.loadingView.isHidden = true
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        loadingView.isUserInteractionEnabled = false
        self.contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        emotionView.isUserInteractionEnabled = false
        emotionView.contentMode = .scaleAspectFit
        self.contentView.addSubview(emotionView)
        emotionView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // nolint: duplicated_code -- 与识别出来的重复代码差异较大，不建议合并
    func showFloatView() {
        if let window = self.window, self.emotionView.image != nil {
            let floatView = StickerFloatView()
            floatView.sticker = self.sticker
            window.addSubview(floatView)

            let rect = self.convert(self.bounds, to: window)
            let width: CGFloat = 152
            let height: CGFloat = 158
            var x = rect.centerX - width / 2
            floatView.frame = CGRect(
                x: x,
                y: rect.top - height,
                width: width,
                height: height
            )
            if x < 8 {
                x = 8
                floatView.frame.origin.x = x
                floatView.setArrowDirection(direction: .left, height: 140)
            } else if x + width + 8 > window.frame.size.width {
                x = window.frame.size.width - width - 8
                floatView.frame.origin.x = x
                floatView.setArrowDirection(direction: .right, height: 140)
            } else {
                floatView.setArrowDirection(direction: .center, height: 140)
            }
            floatView.layer.ud.setShadow(type: .s4Down)
            self.floatView = floatView
        }
    }

    func removeFloatView() {
        self.floatView?.removeFromSuperview()
    }

    fileprivate func doInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

final class AddStickerEmotionCell: UICollectionViewCell {
    private var addIcon: UIImageView = .init(image: nil)

    override init(frame: CGRect) {
        super.init(frame: frame)

        let addIcon = UIImageView()
        addIcon.isUserInteractionEnabled = false
        addIcon.image = Resources.addEmoji
        self.contentView.addSubview(addIcon)
        addIcon.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        self.addIcon = addIcon
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
