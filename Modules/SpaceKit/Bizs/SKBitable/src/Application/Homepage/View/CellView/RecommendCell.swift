//
//  BitableRecommendCell.swift
//  SKBitable
//
//  Created by justin on 2023/8/31.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignShadow
import SKCommon
import SKFoundation
import SKResource
import SkeletonView
import ByteWebImage

protocol BitableRecommendCellDelegate: AnyObject {
    func renderCell(_ model: Recommend, indexPath: IndexPath, config: RecommendCardConfig)
    static func cellWithReuseIdentifier() -> String
}

struct RecommendCellLayoutConfig {
    static let innerMargin12: CGFloat = 12.0
    static let innerMargin8: CGFloat = 8.0
    static let innerLength16: CGFloat = 16.0
    static let titleLabelFont: UIFont = UIFont(name: "PingFangSC-Medium", size: 14) ?? .systemFont(ofSize: 14)
}

protocol RecommendCardImageTracker {
    func cardLoadImageResult(success: Bool, error: Error?)
}

class BitableRecommendCell: UICollectionViewCell, BitableRecommendCellDelegate {
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var coverImage: UIImageView = {
        let coverImage = UIImageView(frame: .zero)
        coverImage.contentMode = .scaleAspectFill
        coverImage.clipsToBounds = true
        coverImage.isSkeletonable = true
        coverImage.backgroundColor = UDColor.bgBase
        return coverImage
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.font = RecommendCellLayoutConfig.titleLabelFont
        titleLabel.numberOfLines = 2
        titleLabel.textColor = UDColor.textTitle
        return titleLabel
    }()
    
    private lazy var authorImage: UIImageView = {
        let authorImage = UIImageView(frame: .zero)
        authorImage.contentMode = .scaleAspectFill
        authorImage.layer.cornerRadius = 8.0
        authorImage.layer.masksToBounds = true
        authorImage.clipsToBounds = true
        return authorImage
    }()
    
    private lazy var authorLabel: UILabel = {
        authorLabel = UILabel(frame: .zero)
        authorLabel.font = .systemFont(ofSize: 12.0)
        authorLabel.textColor = UDColor.textTitle
        return authorLabel
    }()
    
    private lazy var readIcon: UIImageView = {
        let readIcon = UIImageView(frame: .zero)
        readIcon.contentMode = .scaleAspectFill
        readIcon.clipsToBounds = true
        readIcon.image = UDIcon.getIconByKey(.visibleOutlined, iconColor: UDColor.iconN3)
        return readIcon
    }()
    
    private lazy var readCountLabel: UILabel = {
        let readCountLabel = UILabel(frame: .zero)
        readCountLabel.font = .systemFont(ofSize: 10.0)
        readCountLabel.textColor = UDColor.textPlaceholder
        return readCountLabel
    }()
    
    private lazy var coverImageLoadFail: UIImageView = {
        let coverImageLoadFail = UIImageView(frame: .zero)
        coverImageLoadFail.contentMode = .scaleAspectFill
        coverImageLoadFail.image = UDIcon.getIconByKey(.loadfailFilled, iconColor: UDColor.iconN3)
        coverImageLoadFail.isHidden = true
        return coverImageLoadFail
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UDColor.bgFloat
        contentView.addSubview(coverImage)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorImage)
        contentView.addSubview(authorLabel)
        contentView.addSubview(readIcon)
        contentView.addSubview(readCountLabel)
        coverImage.addSubview(coverImageLoadFail)
        
        coverImage.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0)
        }
        
        coverImageLoadFail.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 24.0, height: 24.0))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(RecommendCellLayoutConfig.innerMargin12)
            make.right.equalToSuperview().offset(-RecommendCellLayoutConfig.innerMargin12)
            make.top.equalTo(coverImage.snp.bottom).offset(RecommendCellLayoutConfig.innerMargin12)
            make.height.equalTo(0)
        }
        
        authorImage.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(RecommendCellLayoutConfig.innerMargin12)
            make.top.equalTo(titleLabel.snp.bottom).offset(RecommendCellLayoutConfig.innerMargin8)
            make.size.equalTo(CGSize(width: RecommendCellLayoutConfig.innerLength16, height: RecommendCellLayoutConfig.innerLength16))
        }
        readCountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        readCountLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-RecommendCellLayoutConfig.innerMargin12)
            make.centerY.equalTo(authorImage.snp.centerY)
        }
        
        readIcon.snp.makeConstraints { make in
            make.right.equalTo(readCountLabel.snp.left).offset(-4.0)
            make.centerY.equalTo(authorImage.snp.centerY)
            make.size.equalTo(CGSize(width: 14.0, height: 14.0))
        }
        authorLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        authorLabel.snp.makeConstraints { make in
            make.left.equalTo(authorImage.snp.right).offset(6.0)
            make.centerY.equalTo(authorImage.snp.centerY)
            make.right.lessThanOrEqualTo(readIcon.snp.left).offset(-2)
        }
    }
    
    static func cellWithReuseIdentifier() -> String {
        return "BitableRecommendCellIdentifier"
    }

    private func update(config: RecommendCardConfig) {
        let cornerRadius = config.cardCornerRadius
        contentView.layer.cornerRadius = CGFloat(cornerRadius)
        contentView.layer.masksToBounds = true
        layer.cornerRadius = CGFloat(cornerRadius)
        if config.showCardShadow {
            layer.shadowOpacity = 1
            layer.ud.setShadow(type: .s2Down)
        } else {
            layer.shadowOpacity = 0
        }
    }

    func renderCell(_ model: Recommend, indexPath: IndexPath, config: RecommendCardConfig) {
        update(config: config)
        // card start appear , set expose time
        model.cardStartAppear(indexPath: indexPath)

        model.coverLoadState = .loading
        
        authorImage.bt.setLarkImage(
            .default(key: model.owner.avatarUrl ?? ""),
            placeholder: SKResource.BundleResources.SKResource.Common.Collaborator.Unselected,
            completion:  { imageResult in
                switch imageResult {
                case .success:
                    DocsLogger.info("success load avatar image with url: \(model.owner.avatarUrl ?? "")")
                case .failure(let error):
                    DocsLogger.error("fail load avatar image with url: \(model.owner.avatarUrl ?? "") code: \(error.code) userinfo: \(error.userInfo) localizedDescription: \(error.localizedDescription)", error: error)
                }
        })
        authorLabel.text = model.owner.ownerName ?? ""
        readCountLabel.text = model.heat?.formateUseCountDesc() ?? ""
        
        // 更新封面的约束之后,立即更新封面的布局(Skeleton使用的是layer,不会受到autolayout的约束),否则会造成骨架不展示
        coverImage.snp.updateConstraints { make in
            make.height.equalTo(model.imageHeight)
        }
        // 如果loading时要展示骨架屏,下面3行注释代码一定要一起开启
//        coverImage.setNeedsLayout()
//        coverImage.layoutIfNeeded()
//        coverImage.showUDSkeleton()
        
        if model.validWHRate {
            coverImage.bt.setLarkImage(
                .default(key: model.coverUrl ?? ""),
                completion:  { [weak self] imageResult in
                    guard let self = self else { return }
                    switch imageResult {
                    case .success:
                        model.coverLoadState = .success
                        
//                        self.coverImage.hideUDSkeleton()
                        DocsLogger.info("success load cover image with url: \(model.coverUrl ?? "")")
                        model.cardLoadImageResult(success: true, error: nil)
                    case .failure(let error):
                        model.coverLoadState = .failed
                        
                        self.coverImageLoadFail.isHidden = false
//                        self.coverImage.hideUDSkeleton()
                        
                        DocsLogger.error("fail load cover image with url: \(model.coverUrl ?? "") code: \(error.code) userinfo: \(error.userInfo) localizedDescription: \(error.localizedDescription)", error: error)
                        model.cardLoadImageResult(success: false, error: error)
                    }
                })
        } else {
            coverImage.bt.cancelImageRequest()
            coverImage.image = nil
            model.coverLoadState = .failed
            self.coverImageLoadFail.isHidden = false
        }
        
        titleLabel.attributedText = model.title?.buildAttributedString(RecommendCellLayoutConfig.titleLabelFont, lineHeght: 20) ?? NSAttributedString(string: "")
        titleLabel.snp.updateConstraints { make in
            make.height.equalTo(model.titleHeight)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coverImage.image = nil
        coverImage.bt.cancelImageRequest()
//        coverImage.hideUDSkeleton()
        authorImage.image = nil
        authorLabel.text = ""
        readCountLabel.text = ""
        titleLabel.text = ""
        coverImageLoadFail.isHidden = true
    }
}

extension Int {
    func formateUseCountDesc() -> String {
        if DocsSDK.currentLanguage == .zh_CN || DocsSDK.currentLanguage == .ja_JP || DocsSDK.currentLanguage == .zh_HK || DocsSDK.currentLanguage == .zh_TW {
            if self < 10000 {
                if self >= 1000 {
                    // 1000-9999的使用使用逗号分隔符的形式展示
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal

                    if let formattedNumber = numberFormatter.string(from: NSNumber(value: self)) {
                        return formattedNumber
                    } else {
                        return "\(self)"
                    }
                }
                return "\(self)"
            } else {
                let sufixStr = BundleI18n.SKResource.Bitable_Discover_Counter_TenThousand_Unit(lang: .zh_CN)
                return String(format: "%.1f", Float(self) / 10000.0) + sufixStr
            }
        } else {
            if self < 1000 {
                return "\(self)"
            } else {
                return String(format: "%.1f", Float(self) / 1000.0) + "k"
            }
        }
    }
}

