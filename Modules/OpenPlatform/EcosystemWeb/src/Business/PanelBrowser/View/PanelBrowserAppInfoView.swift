//
//  PanelBrowserAppInfoView.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2022/8/30.
//

import Foundation
import UIKit
import OPFoundation
import UniverseDesignIcon
import WebBrowser

class PanelBrowserAppInfoView: UIView {
    
    private lazy var bgImageView: UIImageView = {
        let bgImageView = UIImageView()
        bgImageView.contentMode = .scaleAspectFit
        bgImageView.layer.masksToBounds = true
        bgImageView.image = BundleResources.WebBrowser.panel_infobg_icon
        return bgImageView
    }()
    
    //  EBEBEB
    private let textColor = UIColor(red: 235.0 / 255.0, green: 235.0 / 255.0, blue: 235.0 / 255.0, alpha: 1.0)
    
    // 应用图标
    private lazy var logoView: UIImageView = {
        let logoView = UIImageView()
        logoView.contentMode = .scaleAspectFit
        logoView.layer.masksToBounds = true
        logoView.layer.ux.setSmoothCorner(radius: 10)
        logoView.layer.ux.setSmoothBorder(width: 1.5, color: UIColor.ud.lineDividerDefault)
        return logoView
    }()
    
    // 应用名称
    private lazy var appNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = textColor
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    // 多语言展示'提供服务'
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0)
        label.textColor = textColor
        label.backgroundColor = .clear
        label.numberOfLines = 1
        return label
    }()
    
    // 箭头
    private lazy var arrowImageView: UIImageView = {
        let arrowImageView = UIImageView()
        arrowImageView.backgroundColor = .clear
        arrowImageView.contentMode = .scaleAspectFit
        return arrowImageView
    }()
    
    public init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
            
        self.layer.cornerRadius = 8.0
        self.layer.masksToBounds = true
        
        self.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(312)
        }

        self.addSubview(logoView)
        logoView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        self.addSubview(appNameLabel)
        self.addSubview(descriptionLabel)
        
        appNameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.centerY.equalToSuperview()
        }
                
        descriptionLabel.snp.makeConstraints { make in
            make.left.equalTo(appNameLabel.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        self.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.left.equalTo(descriptionLabel.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 10, height: 10))
        }
        arrowImageView.image = UDIcon.rightBoldOutlined.ud.withTintColor(textColor)
    }
    
    //点击扩大热区
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var bounds = self.bounds
        bounds = bounds.insetBy(dx: -4, dy: -8)
        return bounds.contains(point)
    }
    
    public func updateViews(appName: String, appIconURLString: String, appId: String = "") {
        self.appNameLabel.text = appName
        self.logoView.bt.setLarkImage(with: .avatar(
            key: appIconURLString,
            entityID: appId,
            params: .init(sizeType: .size(20))), placeholder: BundleResources.WebBrowser.web_app_header_icon)
        self.descriptionLabel.text = BundleI18n.EcosystemWeb.OpenPlatform_MobApp_AppPresents
    }
}
