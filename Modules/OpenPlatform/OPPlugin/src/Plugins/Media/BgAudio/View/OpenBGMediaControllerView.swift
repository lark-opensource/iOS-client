//
//  OpenBGMediaControllerView.swift
//  OPPlugin
//
//  Created by zhysan on 2022/6/21.
//

import UIKit
import SnapKit
import FigmaKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont

/// 小程序后台音频管理中心的 View，目前只会展示一个
final class OpenBGMediaControllerView: UIView {
    
    // MARK: - public vars
    
    let playButton: UIButton = {
        let vi = UIButton(type: .custom)
        vi.layer.masksToBounds = true
        vi.layer.cornerRadius = 18
        vi.layer.borderWidth = 1
        vi.setImage(UDIcon.getIconByKey(.playFilled, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16)), for: .normal)
        vi.setImage(UDIcon.getIconByKey(.pauseFilled, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16)), for: .selected)
        return vi
    }()
    
    let closeButton: UIButton = {
        let vi = UIButton(type: .custom)
        let img = UDIcon.getIconByKey(
            .closeOutlined,
            iconColor: UIColor.ud.iconN3,
            size: CGSize(width: 16, height: 16)
        )
        vi.setImage(img, for: .normal)
        return vi
    }()
    
    let iconView: UIImageView = {
        let vi = UIImageView()
        vi.layer.ux.setSmoothCorner(radius: 12.0)
        vi.layer.masksToBounds = true
        vi.backgroundColor = UIColor.ud.bgFiller
        return vi
    }()
    
    let titleLabel: UILabel = {
        let vi = UILabel()
        vi.font = UIFont.ud.title4
        vi.textColor = UIColor.ud.textTitle
        return vi
    }()
  
    let timeLabel: UILabel = {
        let vi = UILabel()
        vi.font = UIFont.ud.caption1
        vi.textColor = UIColor.ud.textCaption
        return vi
    }()
    
    // MARK: - lifecycle    
    override init(frame: CGRect) {
        super.init(frame: frame)
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private funcs
    
    private func subviewsInit() {
        backgroundColor = UIColor.ud.bgBody
        playButton.layer.ud.setBorderColor(UIColor.ud.lineDividerDefault)
        
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(timeLabel)
        addSubview(playButton)
        addSubview(closeButton)
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.top.equalTo(iconView)
            make.height.equalTo(24)
            make.right.equalTo(playButton.snp.left).offset(-8)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.height.equalTo(24)
            make.right.equalTo(titleLabel)
        }
        
        playButton.snp.makeConstraints { make in
            make.width.height.equalTo(36)
            make.centerY.equalToSuperview()
            make.right.equalTo(closeButton.snp.left).offset(-16)
        }
        
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.right.equalTo(-8)
        }
    }
}
