//
//  RecommendedCell.swift
//  SKSpace
//
//  Created by yinyuan on 2023/4/10.
//

import UIKit
import ByteWebImage
import UniverseDesignColor
import SKUIKit
import SKFoundation

class RecommendedCell: UICollectionViewCell {

    // MARK: - Properties

    static let identifier = "RecommendedCell"
    private static let titleInsets: CGFloat = 0
    private static let titleFont = UIFont.systemFont(ofSize: 12)
    private static let titleMaxLine: Int = 2
    static func titleLabelHeight(_ text: String, cellWidth: CGFloat) -> CGFloat {
        let stringSize = text.boundingRect(
            with: CGSize(width: cellWidth - titleInsets * 2, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: titleFont],
            context: nil
        ).size
        let minHeight: CGFloat = 18
        let maxHeight = ceil(CGFloat(titleMaxLine) * titleFont.lineHeight)  // 最多2行
        return max(minHeight, min(stringSize.height, maxHeight))
    }
    static let titleLabelTopMargin: CGFloat = 8
    static let imageWidthHeightRatio: CGFloat = 0.548

    private let imageView = UIImageView()
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        if !UserScopeNoChangeFG.YY.bitableBannerTitleMultiLineDisable {
            view.numberOfLines = RecommendedCell.titleMaxLine
        } else {
            view.numberOfLines = 1
        }
        view.textAlignment = .center
        view.font = Self.titleFont
        return view
    }()
    
    private let shadowView = UIView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        shadowView.backgroundColor = UDColor.bgBase
        shadowView.layer.cornerRadius = 8
        shadowView.layer.masksToBounds = false
        shadowView.layer.shadowColor = UIColor(red: 0.067, green: 0.133, blue: 0.2, alpha: 0.06).cgColor
        shadowView.layer.shadowOffset = .init(width: 0, height: 2)
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowRadius = 5
        contentView.addSubview(shadowView)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        _ = imageView.addGradientLoadingView()
        contentView.addSubview(imageView)

        _ = titleLabel.addGradientLoadingView(cornerRadius: 6)
        contentView.addSubview(titleLabel)

        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(imageView.snp.width).multipliedBy(Self.imageWidthHeightRatio)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Self.titleInsets)
            make.top.equalTo(imageView.snp.bottom).offset(Self.titleLabelTopMargin)
        }
        
        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(with card: BannerCard?) {
        if let card = card {
            shadowView.isHidden = false
            imageView.hideGradientLoadingView()
            titleLabel.hideGradientLoadingView()
            
            titleLabel.text = card.title
            
            let options = ImageRequestOptions(arrayLiteral: .notDownsample)
            imageView.bt.setImage(URL(string: card.cover ?? ""), options: options)
        } else {
            // Loading style
            shadowView.isHidden = true
            titleLabel.text = "        "
        }
    }
}
