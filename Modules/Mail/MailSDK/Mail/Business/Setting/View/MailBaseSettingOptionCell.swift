//
//  MailBaseSettingOptionCell.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/12/19.
//

import Foundation
import UniverseDesignCheckBox

class MailBaseSettingOptionCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.ud.textTitle
        l.font = UIFont.systemFont(ofSize: 16)
        return l
    }()
    lazy var selectView: UDCheckBox = {
        let v = UDCheckBox(boxType: .list, config: UDCheckBoxUIConfig(), tapCallBack: nil)
        v.isUserInteractionEnabled = false
        return v
    }()
    override var isSelected: Bool {
        didSet {
            selectView.isSelected = isSelected
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : UIColor.ud.bgFloat
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(selectView)
        selectView.snp.makeConstraints { (make) in
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(14)
            make.left.equalTo(16)
            make.height.equalTo(22)
            make.right.equalToSuperview().offset(-48)
        }
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgFloat
        self.isSelected = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
