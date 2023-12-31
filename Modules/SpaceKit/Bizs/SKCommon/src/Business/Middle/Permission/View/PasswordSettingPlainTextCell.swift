//
//  PasswordSettingPlainTextCell.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/11.
//

import Foundation
import SKResource
import UniverseDesignColor

enum PasswordSettingPlainTextCellType: Int {
    /// 更换密码
    case changePassword
    /// 复制链接和密码
    case copyLinkAndPassword
}

class PasswordSettingPlainTextCell: SKGroupTableViewCell {

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulBlue
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    private func setupUI() {
        selectionStyle = .none
        containerView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
        updateSeparator(12)
    }

    func config(with type: PasswordSettingPlainTextCellType) {
        switch type {
        case .changePassword:
            contentLabel.text = BundleI18n.SKResource.Doc_Share_ChangePassword
        case .copyLinkAndPassword:
            contentLabel.text = BundleI18n.SKResource.Doc_Facade_CopyLinkAndPassword
        }
    }
}
