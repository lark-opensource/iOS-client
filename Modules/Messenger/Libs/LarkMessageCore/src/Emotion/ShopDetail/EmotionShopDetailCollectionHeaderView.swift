//
//  EmotionShopDetailCollectionHeaderView.swift
//  LarkMessageCore
//
//  Created by huangjianming on 2019/8/21.
//

import Foundation
import UIKit
import RxSwift
import LarkModel
import LarkMessengerInterface
import LarkUIKit
import RustPB
import ByteWebImage

final class EmotionShopDetailCollectionHeaderView: UICollectionReusableView {
    var disposeBag = DisposeBag()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        return titleLabel
    }()

    lazy var descLabel: UILabel = {
        let descLabel = UILabel()
        self.descLabel = descLabel
        descLabel.numberOfLines = 0
        descLabel.textColor = UIColor.ud.N500
        return descLabel
    }()

    lazy var bannerImgView: UIImageView = {
        let bannerImgView = UIImageView()
        bannerImgView.contentMode = .scaleAspectFill
        bannerImgView.clipsToBounds = true
        return bannerImgView
    }()

    lazy var stateView: EmotionStateView = {
        let stateView = EmotionStateView()
        stateView.isHidden = true
        stateView.setStyle(style: .forEmotionPackageDetail)
        return stateView
    }()

    lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.N300
        return lineView
    }()

    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        //banner图片
        self.addSubview(bannerImgView)

        self.addSubview(lineView)

        //描述
        self.addSubview(descLabel)

        self.addSubview(stateView)

        //标题
        self.addSubview(titleLabel)
    }

    public func layoutForIphone() {
        bannerImgView.snp.remakeConstraints { (make) in
            make.left.top.width.equalToSuperview()
            make.height.equalTo(190)
        }

        lineView.snp.remakeConstraints { (make) in
            make.height.equalTo(0.5)
            make.left.width.equalToSuperview()
            make.bottom.equalTo(-16)
        }

        stateView.snp.remakeConstraints { (make) in
            make.height.equalTo(28)
            make.top.equalTo(bannerImgView.snp.bottom).offset(16)
            make.right.equalTo(-16)
            make.width.greaterThanOrEqualTo(72)
        }

        descLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(stateView.snp.bottom).offset(12)
            make.right.equalTo(-16)
            make.bottom.equalTo(-32)
        }

        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(stateView.snp.left).offset(-10)
            make.centerY.equalTo(stateView)
        }
    }

    public func layoutForIpad() {
        lineView.snp.remakeConstraints { (make) in
            make.height.equalTo(0.5)
            make.left.width.equalToSuperview()
            make.bottom.equalTo(-16)
        }

        bannerImgView.snp.remakeConstraints { (make) in
            make.left.equalTo(20)
            make.top.bottom.equalTo(10)
            make.bottom.equalTo(lineView).offset(-10)
            make.width.lessThanOrEqualTo(534).priority(.high)
            make.width.equalToSuperview().multipliedBy(0.6).priority(.medium)
        }

        stateView.snp.remakeConstraints { (make) in
            make.bottom.equalTo(bannerImgView)
            make.width.greaterThanOrEqualTo(96)
            make.height.equalTo(47)
            make.left.equalTo(bannerImgView.snp.right).offset(20)
        }

        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(bannerImgView.snp.right).offset(20)
            make.right.equalTo(stateView.snp.left).offset(-10)
            make.top.equalTo(bannerImgView)
        }

        descLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
            make.right.equalTo(-16)
            make.bottom.lessThanOrEqualTo(lineView).offset(-60)
        }
    }

    static func attributes() -> [NSAttributedString.Key: NSObject] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 22
        let attributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
        return attributes
    }

    static func headerHeight(stickerSet: RustPB.Im_V1_StickerSet, superViewWidth: CGFloat) -> CGFloat {
        let attributedText = NSAttributedString(string: stickerSet.description_p, attributes: attributes())
        let desHeight = attributedText.boundingRect(with: CGSize(width: superViewWidth - 32, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, context: nil).height
        return 294 + desHeight
    }

    func configure(stickerSet: RustPB.Im_V1_StickerSet,
                   addBtnOn: @escaping () -> Void = {},
                   addedBtnOn: @escaping () -> Void = {}) {
        self.titleLabel.text = stickerSet.title
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 22
        self.descLabel.attributedText = NSAttributedString(string: stickerSet.description_p, attributes: EmotionShopDetailCollectionHeaderView.attributes())
        self.stateView.setHasPaid(hasPaid: stickerSet.hasPaid_p)
        self.bannerImgView.bt.setLarkImage(with: .sticker(key: stickerSet.preview.key,
                                                          stickerSetID: stickerSet.stickerSetID),
                                           placeholder: BundleResources.emotionBannerPlaceholderIcon,
                                           trackStart: {
                                            return TrackInfo(scene: .Chat, fromType: .sticker)
                                           })
        self.stateView.addBtn.rx.tap.subscribe {( _ ) in
            addBtnOn()
        }.disposed(by: disposeBag)
        self.stateView.addedBtn.rx.tap.subscribe { (_) in
            addedBtnOn()
        }.disposed(by: disposeBag)
//        self.layout()
    }

    func setState(state: Observable<EmotionStickerSetState>) {
        self.stateView.setState(state: state)
    }
}
