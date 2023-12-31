//
//  BTFieldUnreadableNitceView.swift
//  SKBitable
//
//  Created by X-MAN on 2022/10/31.
//

import Foundation
import UniverseDesignNotice
import SKUIKit
import UniverseDesignColor
import UniverseDesignFont
import SKResource

private extension UDNoticeUIConfig {
    static func infoConfigWithContentText(_ text: String) -> UDNoticeUIConfig {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.02
        let attrStr = NSMutableAttributedString(string: text)
        attrStr.addAttributes(
            [.font: UDFont.body2,
             .foregroundColor: UDColor.textTitle,
             .paragraphStyle: paragraphStyle
            ]
        )
        var config = UDNoticeUIConfig(type: .info, attributedText: attrStr)
        config.backgroundColor = UDColor.functionInfoFillSolid02
        return config
    }
}

final class BTFieldUnreadableNitceView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var udNoticeView: UDNotice = {
        UDNotice(config: .infoConfigWithContentText(""))
    }()
    
    func subviewsInit() {
        addSubview(udNoticeView)
        udNoticeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        layer.cornerRadius = 10
        layer.masksToBounds = true
    }
    
    func updateNoticeContent(_ text: String) {
        let config = UDNoticeUIConfig.infoConfigWithContentText(text)
        udNoticeView.updateConfigAndRefreshUI(config)
    }
}
