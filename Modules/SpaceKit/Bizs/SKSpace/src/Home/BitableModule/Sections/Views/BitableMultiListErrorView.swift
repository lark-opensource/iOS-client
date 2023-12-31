//
//  BitableMultiListErrorView.swift
//  SKSpace
//
//  Created by ByteDance on 2023/11/27.
//

import UIKit
import SKCommon
import SnapKit
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignIcon

class BitableMultiListErrorView: UIView {
    struct Const {
        static let iconSize: CGSize = .init(width: 188, height: 144)
    }
    
    //MARK: 属性
    private var title: String = ""
    private var clickHandler: (() -> Void)?
    
    //MARK: 懒加载
    private lazy var control: UIControl =  {
        let control = UIControl.init()
        control.backgroundColor = UIColor.clear
        control.addTarget(self, action: #selector(controlDidClick(control:) ), for: .touchUpInside)
        return control
    }()
        
    private lazy var label: UILabel = {
        let label = UILabel.init()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = UDColor.textCaption
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var imgView: UIImageView = {
        let imageView = UIImageView()
        var emptyImage = BundleResources.SKResource.Bitable.multilist_error_bg
        imageView.image = emptyImage
        return imageView
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
    func update(title: String, clickCompletion: (() -> Void)?) {
        self.title = title
        clickHandler = clickCompletion
        decorateNormalStyle()
    }
    
    //MARK: private method
    private func setupUI() {
        addSubview(imgView)
        addSubview(label)
        addSubview(control)
    }
    
    private func decorateNormalStyle() {
        imgView.snp.remakeConstraints { make in
            make.size.equalTo(Const.iconSize)
            make.top.equalToSuperview().offset(0)
            make.centerX.equalToSuperview()
        }
        label.text = title
        label.sizeToFit()
        label.snp.remakeConstraints { make in
            make.top.equalTo(imgView.snp.bottom).offset(3)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview()
        }
        control.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    //MARK: action
    @objc
    private func controlDidClick(control: UIControl) {
        clickHandler?()
    }
}
