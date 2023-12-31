//
//  TemplateTag.swift
//  SKUIKit
//
//  Created by 曾浩泓 on 2022/1/3.
//  


import Foundation
import UIKit
import SKResource
import UniverseDesignColor

public final class TemplateTag: UIView {
//    private let iconView: UIImageView = {
//        let icon = UIImageView()
//        icon.image = BundleResources.SKResource.Common.Other.template
//        return icon
//    }()
    
    private let label: UILabel = {
        let lb = UILabel()
        lb.text = BundleI18n.SKResource.Doc_Create_File_ByTemplate
        lb.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        lb.textColor = UDColor.udtokenTagTextSIndigo
        return lb
    }()
    
    init() {
        super.init(frame: .zero)
        setupSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        backgroundColor = UDColor.udtokenTagBgIndigo
        layer.cornerRadius = 4
        layer.masksToBounds = true
        
//        addSubview(iconView)
        addSubview(label)
//        iconView.snp.makeConstraints { make in
//            make.width.height.equalTo(12)
//            make.centerY.equalToSuperview()
//            make.leading.equalToSuperview().offset(4)
//        }
        label.snp.makeConstraints { make in
//            make.leading.equalToSuperview().offset(4)
//            make.trailing.equalToSuperview().offset(-4)
            make.center.equalToSuperview()
        }
    }
    
    override public var intrinsicContentSize: CGSize {
        let textWidth = label.intrinsicContentSize.width
        return CGSize(width: textWidth + 8, height: 18)
    }
}
