//
//  MailSettingAddAccountCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/11/29.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon

protocol MailSettingAddOperationCellDependency: AnyObject {
    func handleAddOperation()
}

class MailSettingAddOperationCell: UITableViewCell {
    weak var dependency: MailSettingAddOperationCellDependency?
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    lazy var titleLabel = self.makeTitleLabel()
    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.primaryContentDefault
        label.textAlignment = .left
        return label
    }

    lazy var addIcon = self.makeAddIcon()
    private func makeAddIcon() -> UIImageView {
        let icon = UIImageView()
        icon.image = UDIcon.addOutlined.withRenderingMode(.alwaysTemplate).ud.withTintColor(.ud.primaryContentDefault)
        return icon
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addClient)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func addClient() {
        dependency?.handleAddOperation()
    }

    func setCellInfo() {
        if let item = item as? MailSettingAddOperationModel {
            titleLabel.text = item.title
        }
    }

    func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(addIcon)
        addIcon.snp.makeConstraints { (make) in
            make.bottom.equalTo(-16)
            make.top.left.equalTo(16)
            make.width.height.equalTo(16)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(addIcon.snp.right).offset(4)
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }
    }
}
