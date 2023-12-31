//
//  MoreViewV2HeaderView.swift
//  SKCommon
//
//  Created by majie.7 on 2022/9/19.
//

import SKFoundation
import SKUIKit
import UniverseDesignColor

class MoreHeaderView: UITableViewHeaderFooterView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.backgroundColor = .clear
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
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(27)
            make.top.equalToSuperview().offset(5)
            make.height.equalTo(22)
        }
    }
    
    func setupLabelTitle(_ title: String) {
        titleLabel.text = title
    }
}
