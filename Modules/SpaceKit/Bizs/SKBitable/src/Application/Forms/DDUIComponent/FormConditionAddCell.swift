//
//  FormConditionAddCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/5/18.
//

import Foundation
import UniverseDesignColor

final class FormConditionAddCell: UITableViewCell {
    
    private lazy var iconImage: UIImageView = {
        return UIImageView()
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.primaryPri500
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var containerView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.layer.cornerRadius = 10
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(containerView)
        containerView.addSubview(iconImage)
        containerView.addSubview(titleLabel)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        iconImage.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(17)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImage.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
    }
    
    func setData(_ model: AddCondition) {
        iconImage.image = model.leftIcon?.image?.ud.withTintColor(UDColor.primaryPri500)
        titleLabel.text = model.content?.text
    }
    
}
