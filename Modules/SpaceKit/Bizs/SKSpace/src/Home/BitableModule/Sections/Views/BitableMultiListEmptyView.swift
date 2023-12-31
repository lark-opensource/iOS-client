//
//  BitablePlaceHolderEmptyView.swift
//  SKSpace
//
//  Created by ByteDance on 2023/11/19.
//

import UIKit
import SKCommon
import SnapKit
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignIcon

enum BitableMultiListEmptyViewStyle {
    case normal
    case hasCreateButton
}

class BitableMultiListEmptyView: UIView {
    struct Const {
        static let iconSize: CGSize = .init(width: 188, height: 144)
    }
    
    //MARK: 属性
    private var style: BitableMultiListEmptyViewStyle = .normal
    private var title: String = ""
    private var createTitle: String = ""
    private var createHandler: ((UIView) -> Void)?
    
    //MARK: 懒加载
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = UDColor.textCaption
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        return label
    }()

    private lazy var imgView: UIImageView = {
        let imageView = UIImageView()
        var emptyImage = BundleResources.SKResource.Bitable.multilist_empty_bg
        imageView.image = emptyImage
        return imageView
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.backgroundColor = UDColor.B500        
        let image = UDIcon.addOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill).ud.resized(to: CGSize(width: 16, height: 16))
        button.setImage(image, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        button.setTitleColor(UDColor.staticWhite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(createButtonDidClick(button:)) , for: .touchUpInside)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isHidden = true
        return button
    }()

    //MARK: lifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    //MARK: public method
    func update(style: BitableMultiListEmptyViewStyle, title: String, createTitle: String?, createCompletion: ((UIView) -> Void)?) {
        self.style = style
        self.title = title
        self.createTitle = createTitle ?? ""
        self.createHandler = createCompletion
        if style == .normal {
            decorateNormalStyle()
        } else if style == .hasCreateButton {
            decorateCreateButtonStyle()
        }
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    //MARK: private method
    private func setupUI() {
        addSubview(imgView)
        addSubview(titleLabel)
        addSubview(createButton)
    }
    
    private func decorateNormalStyle() {
        imgView.snp.remakeConstraints { make in
            make.size.equalTo(Const.iconSize)
            make.top.equalToSuperview().offset(0)
            make.centerX.equalToSuperview()
        }
        
        titleLabel.text = title
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(imgView.snp.bottom).offset(3)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview()
        }
        createButton.isHidden = true
    }
    
    private func decorateCreateButtonStyle() {
        imgView.snp.remakeConstraints { make in
            make.size.equalTo(Const.iconSize)
            make.top.equalToSuperview().offset(0)
            make.centerX.equalToSuperview()
        }
        
        titleLabel.text = title
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(imgView.snp.bottom).offset(3)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        createButton.isHidden = false
        createButton.setTitle(self.createTitle, for: .normal)
        createButton.titleLabel?.sizeToFit()
        let width = createButton.titleLabel?.btd_width ?? 56
        createButton.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.width.equalTo(width + 12 * 2 + 10 + 16)
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
            make.bottom.equalToSuperview().offset(0)
        }
    }
    
    //MARK: action
    @objc
    private func createButtonDidClick(button: UIButton) {
        createHandler?(button)
    }
}
