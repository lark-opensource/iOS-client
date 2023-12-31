//
//  OnBoardingLabelView.swift
//  SKUIKit
//
//  Created by ByteDance on 2022/10/26.
//
//  替代红点的新的标签样式
//
// disable-lint: magic number

import Foundation
import UniverseDesignColor
import SKResource

public final class OnBoardingLabelView: UIView {

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UDColor.bgBody
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UDColor.functionDangerContentDefault
        self.clipsToBounds = true
        self.layer.cornerRadius = 10
        self.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview().inset(1)
            make.height.equalTo(18)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func useDefaultTip() {
        contentLabel.text = BundleI18n.SKResource.LarkCCM_CM_Verify_New_Tag
    }
}
