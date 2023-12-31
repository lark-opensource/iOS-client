//
//  ReadPrivacyHeaderView.swift
//  SKCommon
//
//  Created by peilongfei on 2023/11/30.
//  


import UIKit
import SKResource
import UniverseDesignColor

class ReadPrivacyHeaderView: UITableViewHeaderFooterView {

    static let height: CGFloat = 50
    static let reuseIdentifier = "ReadPrivacyHeaderView"

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.CreationMobile_Common_PrivacySettings_title
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        return label
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(20)
        }
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}
