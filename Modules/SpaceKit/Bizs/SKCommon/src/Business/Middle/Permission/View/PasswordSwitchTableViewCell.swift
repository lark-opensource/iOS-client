//
//  PasswordSwitchTableViewCell.swift
//  SpaceKit
//
//  Created by liweiye on 2020/4/11.
//

import UIKit
import RxSwift
import RxCocoa
import SKResource
import UniverseDesignColor

struct PasswordSwitchTableViewCellModel: PasswordTableViewCellModel {
    var cellType: PasswordTableViewCellType {
        return .passwordSwitch
    }
}

class PasswordSwitchTableViewCell: SKGroupTableViewCell {

    var disposeBag = DisposeBag()

    private(set) var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = BundleI18n.SKResource.Doc_Share_UsePassword
        return label
    }()

    var switchButton: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = UIColor.ud.colorfulBlue
        return sw
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
        disposeBag = DisposeBag()
    }

    private func setupUI() {
        containerView.addSubview(switchButton)
        switchButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-11)
            make.width.equalTo(52)
            make.centerY.equalToSuperview()
            make.height.equalTo(31)
        }

        containerView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(switchButton).offset(-16)
            make.centerY.equalTo(switchButton)
            make.height.equalTo(22)
        }
        
        updateSeparator(12)
    }

    func config(enableSwitchPassword: Bool) {
        switchButton.isEnabled = enableSwitchPassword
        contentLabel.textColor = enableSwitchPassword ? UDColor.textTitle : UDColor.textDisabled
    }
}
