//
//  BitableMultiListDecorationView.swift
//  SKSpace
//
//  Created by ByteDance on 2023/11/29.
//

import UIKit
import SKCommon
import SnapKit
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignIcon


enum BitableMultiListDecorationViewStyle: Int {
    //内容铺满
    case listIsfull = 0
    //内容未铺满
    case hasMuchSpace = 1
}

class BitableMultiListDecorationView: UIView {
    struct Const {
        static let bottomMaskViewHeight: CGFloat = 72.0
        static let bottomCreateViewHeight: CGFloat = 128.0
        
        static func bottomMaskGradientColors() -> [UIColor] {
            if UIColor.docs.isCurrentDarkMode {
                return [
                    UIColor.init(red: 37/255.0, green: 37/255.0, blue: 37/255.0, alpha: 0.0),
                    UIColor.init(red: 37/255.0, green: 37/255.0, blue: 37/255.0, alpha: 0.65),
                    UIColor.init(red: 37/255.0, green: 37/255.0, blue: 37/255.0, alpha: 1.0)]
            } else {
               return [
                UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0),
                UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5),
                UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)]
            }
        }
    }
    
    //MARK: 属性
    private var style: BitableMultiListDecorationViewStyle = .listIsfull
 
    //MARK: listIsFull
    private lazy var bottomMaskView: UIView = {
        let mask = UIView.init()
        return mask
    }()

    private lazy var bottomMaskLayer = {
         let layer = CAGradientLayer()
        layer.locations = [0.0,0.53,1.0]
         layer.startPoint = CGPoint(x: 0.0, y: 0.0)
         layer.endPoint = CGPoint(x: 0.0, y: 1.0)
         return layer
     }()
    
    //MARK: hasMuchSpace
    private var createHandler: (() -> Void)?
    
    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        var emptyImage = BundleResources.SKResource.Bitable.multilist_decoration_smile
        imageView.image = emptyImage
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
        label.textColor = UDColor.textCaption
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var lineTipsView: UIImageView = {
        let imageView = UIImageView()
        var emptyImage = BundleResources.SKResource.Bitable.multilist_decoration_line
        imageView.image = emptyImage
        return imageView
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        let image = UDIcon.addOutlined.ud.withTintColor(UDColor.textTitle).ud.resized(to: CGSize(width: 16, height: 16))
        button.setImage(image, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(createButtonDidClick(button:)) , for: .touchUpInside)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
        
    private lazy var bottomCreateView: UIView = {
        let bottomView = UIView.init()
        return bottomView
    }()

    //MARK: lifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    init(style: BitableMultiListDecorationViewStyle, createHanlder: (() -> Void)? = nil) {
        self.style = style
        self.createHandler = createHanlder
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if style == .listIsfull {
            bottomMaskLayer.frame = bottomMaskView.bounds
        }
    }
        
    //MARK: private method
    private func setupUI() {
        if style == .listIsfull {
            decorateIfListIsfull()
        } else if style == .hasMuchSpace {
            decorateIfHasMuchSpace()
        }
    }
    
    private func decorateIfListIsfull() {
        addSubview(bottomMaskView)
        bottomMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bottomMaskView.layer.addSublayer(bottomMaskLayer)
        bottomMaskLayer.ud.setColors(Const.bottomMaskGradientColors())
    }
    
    private func decorateIfHasMuchSpace() {
        addSubview(bottomCreateView)
        bottomCreateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bottomCreateView.addSubview(iconView)
        bottomCreateView.addSubview(titleLabel)
        bottomCreateView.addSubview(lineTipsView)
        bottomCreateView.addSubview(createButton)
        
        iconView.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 32, height: 32))
            make.top.equalToSuperview().offset(0)
            make.left.equalToSuperview().offset(16)
        }
        
        titleLabel.text = BundleI18n.SKResource.Bitable_HomeDashboard_RecentDisplayHere_Desc
        titleLabel.sizeToFit()
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(0)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    
        createButton.isHidden = false
        createButton.setTitle(BundleI18n.SKResource.Bitable_HomeDashboard_CreateNew_Button, for: .normal)
        createButton.titleLabel?.sizeToFit()
        let width = createButton.titleLabel?.btd_width ?? 42
        createButton.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.width.equalTo(width + 12 * 2 + 10 + 16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
        
        lineTipsView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left).offset(30)
            make.width.equalTo(180)
            make.height.equalTo(50)
            make.centerY.equalTo(createButton).offset(0)
        }
    }
    
    //MARK: action
    @objc
    private func createButtonDidClick(button: UIButton) {
        createHandler?()
    }
}


