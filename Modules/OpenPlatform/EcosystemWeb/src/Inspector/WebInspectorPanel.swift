//
//  WebInspectorPanel.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2022/9/13.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignShadow
import SnapKit

protocol WebInspectorPanelDelegate: AnyObject {
    func didClickClose()
    func didClickPanel()
}

class WebInspectorPanel: UIView {
    
    weak var actionDelegate: WebInspectorPanelDelegate?
    
    struct Const {
        static let panelWidth: CGFloat = 144
        static let panelHeight: CGFloat = 48
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 悬浮窗中用于打开调试面板的部分
    private lazy var openLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.title3
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.EcosystemWeb.OpenPlatform_WebView_OnlineDebug_Panel
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didClickPanel))
        label.addGestureRecognizer(tap)
        return label
    }()
    
    // 用于关闭悬浮窗的部分
    private lazy var closeImg: UIImageView = {
        let close = UIImageView(frame: .zero)
        close.image = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN2)
        close.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didClickCloseImg))
        close.addGestureRecognizer(tap)
        return close
    }()

    @objc
    private func didClickCloseImg(sender: Any) {
        guard let delegate = actionDelegate else {
            return
        }
        
        delegate.didClickClose()
    }
    
    @objc
    private func didClickPanel(sender: Any) {
        guard let delegate = actionDelegate else {
            return
        }
        
        delegate.didClickPanel()
    }
        
    private func setupViews() {
        backgroundColor = UIColor.ud.bgFiller

        layer.cornerRadius = 12
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(hexString: "#DEE0E3").cgColor
        
        layer.ud.setShadow(type: .s3Down)

        addSubview(openLabel)
        addSubview(closeImg)
        closeImg.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        openLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(closeImg.snp_leading).offset(-10)
        }
    }
}

