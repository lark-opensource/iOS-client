//
//  EmbedDocAuthCell.swift
//  SKCommon
//
//  Created by guoqp on 2022/3/1.
//

import Foundation
import SKUIKit
import SKResource
import Kingfisher
import SKFoundation
import RxSwift
import UniverseDesignCheckBox
import UniverseDesignColor
import UIKit

struct EmbedDocAuthCellItem {
    let title: String
    var ownerName: String
    var image: UIImage
    var isAuth: Bool
}

// MARK: - EmbedDocAuthCell
class EmbedDocAuthCell: UITableViewCell {
    private let disposeBag: DisposeBag = DisposeBag()
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = UDColor.textTitle
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UDColor.textPlaceholder
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var permissonLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UDColor.textCaption
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UDColor.bgBody
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(permissonLabel)
        contentView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)

        iconView.snp.makeConstraints({ (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
            make.left.equalTo(16)
        })
        titleLabel.snp.makeConstraints({ (make) in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.right.equalTo(permissonLabel.snp.left).offset(-10)
            make.top.equalToSuperview().inset(12)
        })
        subtitleLabel.snp.makeConstraints({ (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(permissonLabel.snp.left).offset(-10)
            make.bottom.equalToSuperview().inset(12)

        })
        permissonLabel.snp.makeConstraints({ make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(item: EmbedDocAuthCellItem) {
        titleLabel.text = item.title
        subtitleLabel.text = BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Owner(item.ownerName)
        permissonLabel.text = item.isAuth ?
        BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Granted :
        BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_NotGranted
        permissonLabel.textColor = item.isAuth ?
        UDColor.textPlaceholder :
        UDColor.textTitle
        iconView.image = item.image
    }
}
