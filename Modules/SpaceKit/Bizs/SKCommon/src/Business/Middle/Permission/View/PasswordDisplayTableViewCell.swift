//
//  PasswordDisplayTableViewCell.swift
//  SpaceKit
//
//  Created by liweiye on 2020/4/11.
//

import UIKit
import RxSwift
import RxCocoa
import SKResource
import UniverseDesignColor

struct PasswordDisplayTableViewCellModel: PasswordTableViewCellModel {
    var cellType: PasswordTableViewCellType {
        return .passwordDisplay
    }
    let password: String

    init(password: String) {
        self.password = password
    }
}

class PasswordDisplayTableViewCell: SKGroupTableViewCell {

    var mainTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = BundleI18n.SKResource.Doc_Share_Password
        return label
    }()

    var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N600
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = BundleI18n.SKResource.LarkCCM_CM_ExSharing_PasswordValidForCurrentPage_Text
        label.numberOfLines = 0
        return label
    }()

    var passwordLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N600
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func config(isToC: Bool, password: String) {
        passwordLabel.text = password
        // C端不显示组织外需要输入密码的提示
        subTitleLabel.isHidden = isToC
        containerView.addSubview(mainTitleLabel)
        mainTitleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(15)
            if isToC {
                make.bottom.equalToSuperview().offset(-15)
            }
            make.height.equalTo(22)
        }

        containerView.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-90)
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(isToC ? 0 : 2)
            make.bottom.equalToSuperview().offset(isToC ? 0 : -15)
        }

        containerView.addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.left.greaterThanOrEqualTo(subTitleLabel.snp.right).offset(13)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
        
        updateSeparator(12)
    }
}
