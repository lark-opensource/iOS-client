//
//  SectionHeaderView.swift
//  SKSpace
//
//  Created by yinyuan on 2023/4/10.
//

import UIKit
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignColor

public struct SectionHeaderInfo {
    public let title: String
    public var info: String?
    public var rightIcon: UIImage?
    public var rightClickHandler: ((_ info: SectionHeaderInfo) -> Void)?
    public var height: CGFloat?
    
    public init(title: String) {
        self.title = title
    }
}

class SectionHeaderView: UICollectionViewCell {
    
    static let height: CGFloat = 50
    
    private var info: SectionHeaderInfo?

    lazy var  titleView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        view.textColor = UDColor.textTitle
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var rightViewControl: UIControl = {
        let view = UIControl()
        return view
    }()
    
    lazy var rightView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [infoView, rightIconView])
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 2
        return view
    }()
    
    lazy var  infoView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UDColor.textPlaceholder
        view.textAlignment = .right
        return view
    }()
    
    lazy var  rightIconView: UIImageView = {
        let view = UIImageView()
        view.tintColor = UDColor.iconN3
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    private func setupUI() {
        backgroundColor = UDColor.bgBody
        
        addSubview(titleView)
        addSubview(rightView)
        addSubview(rightViewControl)
        
        rightView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(8)
            make.height.equalTo(22)
            make.left.equalToSuperview().inset(16)
            make.right.lessThanOrEqualTo(rightView.snp.left)
        }
        
        rightView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        rightView.snp.makeConstraints { make in
            make.centerY.equalTo(titleView.snp.centerY)
            make.right.equalToSuperview().inset(16)
            make.width.greaterThanOrEqualTo(100)
        }
        
        infoView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        rightIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightIconView.snp.makeConstraints { make in
            make.width.height.equalTo(14)
        }
        
        rightViewControl.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(rightView.snp.left).offset(-21)
        }
        rightViewControl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rightViewClick)))
    }
    
    @objc
    func rightViewClick() {
        guard let info = info else {
            return
        }
        info.rightClickHandler?(info)
    }
    
    func update(_ info: SectionHeaderInfo?) {
        self.info = info
        if let info = info {
            titleView.backgroundColor = .clear
            titleView.text = info.title
            infoView.text = info.info
            infoView.isHidden = info.info == nil
            rightIconView.image = info.rightIcon?.withRenderingMode(.alwaysTemplate)
            rightIconView.isHidden = info.rightIcon == nil
        } else {
            titleView.text = "        "
            titleView.backgroundColor = UDColor.bgBase
            infoView.isHidden = true
            rightIconView.isHidden = true
        }
    }
}
