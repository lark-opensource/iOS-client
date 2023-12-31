//
//  CollaboratorInvitationCell.swift
//  SKCommon
//
//  Created by liweiye on 2020/9/15.
//

import Foundation
import SKUIKit
import SKResource
import RxSwift
import UniverseDesignColor

enum CollaboratorInvitationType {
    case organization               // 从组织架构选择
    case userGroup
}

struct CollaboratorInvitationCellItem {
    let cellType: CollaboratorInvitationType
    let title: String
    let iconImage: UIImage
}

class CollaboratorInvitationCell: UITableViewCell {
    private let disposeBag: DisposeBag = DisposeBag()
    var item: CollaboratorInvitationCellItem?

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UDColor.bgBody
        contentView.addSubview(iconView)
        contentView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(17)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(17)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }
    }

    func update(with item: CollaboratorInvitationCellItem) {
        self.item = item
        iconView.image = item.iconImage
        contentLabel.text = item.title
    }
}
