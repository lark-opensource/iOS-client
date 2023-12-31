//
//  BotScopeInfoCell.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/4/26.
//

import Foundation
import SnapKit

public final class BotScopeInfoCell: UITableViewCell {

    private lazy var descLabel: UILabel = {
        let descLabel = UILabel(frame: .zero)
        descLabel.textColor = UIColor.ud.textTitle
        descLabel.numberOfLines = 0
        descLabel.font = UIFont.systemFont(ofSize: 16.0)
        return descLabel
    }()
    
    private lazy var icon: UIView = {
        let icon = UIView(frame: .zero)
        icon.backgroundColor = UIColor.ud.iconN3
        icon.layer.cornerRadius = 2
        icon.layer.masksToBounds = true
        return icon
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateInfo(scopeInfo: ScopeInfo) {
        descLabel.text = scopeInfo.scopeDesc
        self.contentView.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.equalTo(self.contentView).offset(32)
            make.right.equalToSuperview()
            make.top.equalTo(self.contentView).offset(6)
            make.bottom.equalTo(self.contentView).offset(-6)
        }
        
        self.contentView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(4)
            make.top.equalTo(self.contentView).offset(12)
            make.left.equalTo(self.contentView).offset(20)
        }
    }
}
