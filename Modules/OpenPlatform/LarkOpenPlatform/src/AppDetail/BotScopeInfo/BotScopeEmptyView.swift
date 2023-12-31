//
//  BotScopeEmptyView.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/4/26.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignEmpty
import SnapKit

public final class BotScopeEmptyView: UIView {
    let tipsLabel: UILabel = {
        let tipsLable = UILabel(frame: .zero)
        tipsLable.textColor = UIColor.ud.textCaption
        tipsLable.text = BundleI18n.GroupBot.Lark_Bot_BotPermissionsPlaceholder
        tipsLable.numberOfLines = 0
        tipsLable.textAlignment = .center
        tipsLable.lineBreakMode = .byWordWrapping
        tipsLable.font = UIFont.systemFont(ofSize: 14.0)
        return tipsLable
    }()
    
    let tipsImage: UIImageView = {
        let tipsImage = UIImageView()
        tipsImage.image = UDEmptyType.noContent.defaultImage()
        return tipsImage
    }()
    
    public init() {
        super.init(frame: .zero)
        setupSubViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubViews() {
        self.backgroundColor = UIColor.ud.bgBody
        var contentView = UIView()
        contentView.addSubview(tipsImage)
        tipsImage.snp.makeConstraints { make in
            make.height.width.equalTo(120)
            make.top.centerX.equalToSuperview()
        }
        
        contentView.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { make in
            make.top.equalTo(tipsImage.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
            make.leading.equalTo(contentView).offset(12)
            make.trailing.equalTo(contentView).offset(-12)
        }
        self.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
    }
}
