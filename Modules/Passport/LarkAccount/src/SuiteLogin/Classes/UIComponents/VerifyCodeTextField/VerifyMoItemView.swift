//
//  VerifyMoItemBox.swift
//  LarkAccount
//
//  Created by ZhaoKejie on 2022/9/16.
//

import UIKit
import SnapKit
import RxSwift
import UniverseDesignIcon
import UniverseDesignColor
import Homeric

class VerifyMoItemView: UIView {

    let disposeBag = DisposeBag()
    
    init(title: String, content: String, buttonText: String, itemType: Int) {
        super.init(frame: .zero)

        self.backgroundColor = UDColor.bgContentBase
        self.layer.cornerRadius = 4
        setupTextView(title: title, content: content)
        setupButton(buttonText: buttonText)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let titleView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N600
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
       return label
    }()
    let contentView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()
    let copyButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
        button.backgroundColor = UDColor.udtokenComponentOutlinedBg
        button.layer.borderColor = UDColor.N400.cgColor
        return button
    }()
    
    func setupTextView(title: String, content: String) {
        self.titleView.text = title
        self.contentView.text = content
        self.addSubview(titleView)
        self.addSubview(contentView)
        
        titleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.topMargin)
            make.left.equalToSuperview().inset(Layout.leftMargin)
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(Layout.textMiddle)
            make.left.equalToSuperview().inset(Layout.leftMargin)
        }
        
    }
    
    func setupButton(buttonText: String) {
        
        self.addSubview(self.copyButton)
        copyButton.snp.makeConstraints { make in
            make.width.equalTo(Layout.buttonWidth)
            make.height.equalTo(Layout.buttonHeight)
            make.right.equalToSuperview().inset(Layout.rightMargin)
            make.centerY.equalTo(contentView)
        }
        
        //添加图标和提示文字
        let leftImage = UIImageView(image: UDIcon.getIconByKey(.copyOutlined, iconColor: UDColor.N900,size: CGSize(width: Layout.copyImageSize, height: Layout.copyImageSize)))
        let rightLabel = UILabel()

        //重设Layout
        copyButton.addSubview(leftImage)
        leftImage.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Layout.leftToImage)
            make.width.equalTo(Layout.copyImageSize)
            make.height.equalTo(Layout.copyImageSize)
            make.centerY.equalToSuperview()
        }
        copyButton.addSubview(rightLabel)
        rightLabel.text = buttonText
        rightLabel.textColor = UDColor.N900
        rightLabel.snp.removeConstraints()
        rightLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        rightLabel.snp.makeConstraints { make in
            make.left.equalTo(leftImage.snp.right).offset(4)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    
    }
    
       
    struct Layout {
        static let leftMargin = 16
        static let rightMargin = 16
        static let topMargin = 16
        static let bottomMargin = 16
        static let textMiddle = 12
        
        //buttonSize
        static let buttonHeight = 28
        static let buttonWidth = 60
        
        static let leftToImage = 8
        static let copyImageSize = 16
    }

}

class VerifyMoBoxView: UIView {
    var recipientsView: VerifyMoItemView?
    var mesContentView: VerifyMoItemView?
}
