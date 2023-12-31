//
//  StickerSetEmotionCell.swift
//  LarkKeyboardView
//
//  Created by 李晨 on 2019/8/28.
//

import UIKit
import Foundation
import ByteWebImage
import LarkModel
import LarkUIKit
import LKCommonsLogging
import SkeletonView
import RustPB
import UniverseDesignShadow

final public class StickerSetEmotionHeaderView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class StickerSetEmotionCell: UICollectionViewCell {

    static let logger = Logger.log(StickerSetEmotionCell.self, category: "Module.Sticker")

    lazy private var emotionView: ByteImageView = {
        let imageView = ByteImageView()
        imageView.autoPlayAnimatedImage = false
        return imageView
    }()
    private var loadingView: UIView = UIView()
    private let loadingGradient = SkeletonGradient(baseColor: UIColor.ud.N300.withAlphaComponent(0.3),
                                                   secondaryColor: UIColor.ud.N300.withAlphaComponent(0.6))
    private var titleLabel: UILabel = UILabel()

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
                self.titleLabel.text = sticker.description_p
                let key = sticker.image.thumbnail.key
                self.imageLoadCallBack?(self.sticker, .start)
                self.emotionView.bt.setLarkImage(with: .sticker(key: key, stickerSetID: sticker.stickerSetID),
                                                 trackStart: {
                                                    TrackInfo(scene: .Chat, fromType: .sticker)
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

        emotionView.isUserInteractionEnabled = false
        emotionView.contentMode = .scaleAspectFit
        self.contentView.addSubview(emotionView)
        emotionView.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(50)
        })

        loadingView.isUserInteractionEnabled = false
        emotionView.addSubview(loadingView)
        loadingView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })

        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = UIColor.ud.N600
        titleLabel.textAlignment = .center
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.centerX.bottom.equalToSuperview()
            maker.height.equalTo(16.5)
            maker.width.equalToSuperview()
        }

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
            var height: CGFloat = 158
            if let sticker = floatView.sticker, !sticker.description_p.isEmpty {
                height = 170
                floatView.desLabel.text = sticker.description_p
            }
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
                floatView.setArrowDirection(direction: .left, height: 154)
            } else if x + width + 8 > window.frame.size.width {
                x = window.frame.size.width - width - 8
                floatView.frame.origin.x = x
                floatView.setArrowDirection(direction: .right, height: 154)
            } else {
                floatView.setArrowDirection(direction: .center, height: 154)
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
