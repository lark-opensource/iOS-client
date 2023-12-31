//
//  PanelBrowserNavigationBar.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2022/8/31.
//

import UIKit
import UniverseDesignIcon

class PanelBrowserNavigationBar: UIView {
    
    private let textColor = UIColor.ud.textTitle
    
    public lazy var backBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        btn.isHidden = true
        return btn
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17.0, weight: .medium)
        label.textColor = textColor
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    public lazy var closeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        btn.setImage(UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        return btn
    }()

    public init() {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(backBtn)
        backBtn.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(44)
            make.height.equalTo(24)
        }
        
        self.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.size.height.equalTo(20)
        }
    }
    
    public func setNavigationTitle(_ title: String) {
        self.titleLabel.text = title ?? ""
    }

    public func showBackBtn(_ show: Bool) {
        self.backBtn.isHidden = !show
    }
}
