//
//  MailSettingSwipeActionCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/2/6.
//

import Foundation
import UIKit
import UniverseDesignCheckBox
import RxSwift

final class MailSettingSwipeActionCell: UITableViewCell {
    private let iconView: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()
    private var checkBox: UDCheckBox = UDCheckBox()
    
    weak var dependency: MailSettingStatusCellDependency?
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }
    var aliginDown: Bool = true {
        didSet {
            iconView.snp.remakeConstraints { (make) in
                make.left.equalTo(16)
                if aliginDown {
                    make.bottom.equalToSuperview().offset(-14)
                } else {
                    make.top.equalToSuperview().offset(14)
                }
                make.width.height.equalTo(20)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }
    
    func setupViews() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkBox)

        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            if aliginDown {
                make.bottom.equalToSuperview().offset(-14)
            } else {
                make.top.equalToSuperview().offset(14)
            }
            make.width.height.equalTo(20)
        }
        
        checkBox.isUserInteractionEnabled = false
        checkBox.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(iconView)
            make.width.height.equalTo(20)
        }
        
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.centerY.equalTo(iconView)
            make.right.equalTo(checkBox.snp.left).offset(8)
            make.height.equalTo(22)
        }

//        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickCell)))
        contentView.backgroundColor = UIColor.ud.bgFloat
    }

//    @objc
//    func didClickCell() {
//        if let item = item as? MailSettingSwipeActionModel {
//            updateStatus(isSelected: !checkBox.isSelected, isEnabled: true)
//            item.switchHandler(checkBox.isSelected)
//        }
//    }
    
    func setCellInfo() {
        titleLabel.isHidden = true
        checkBox.isHidden = true
        iconView.isHidden = true
        if let item = item as? MailSettingSwipeActionModel {
            iconView.isHidden = false
            iconView.image = item.action.actionIcon().ud.colorize(color: UIColor.ud.iconN1)
            
            titleLabel.isHidden = false
            titleLabel.text = item.action.previewTitle()

            checkBox.isHidden = false
            var config = UDCheckBoxUIConfig()
            config.style = .circle
            checkBox.updateUIConfig(boxType: .multiple, config: config)
            checkBox.isSelected = item.status
            checkBox.isEnabled = true
        }
    }
    
    func updateStatus(isSelected: Bool, isEnabled: Bool) {
        self.checkBox.isSelected = isSelected
        self.checkBox.isEnabled = isEnabled
    }
}
