//
//  PanelNavigationView.swift
//  SKBrowser
//
//  Created by liujinwei on 2023/3/10.
//  


import Foundation
import UniverseDesignColor
import UniverseDesignIcon

class PanelNavigationView: UIView {

    private let backButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = .clear
        btn.setImage(UDIcon.leftSmallCcmOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        return btn
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        return label
    }()

    let seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let backButtonContent = UIView()
        backButton.docs.addStandardHighlight()
        backButtonContent.addSubview(backButton)

        self.addSubview(backButtonContent)
        self.addSubview(titleLabel)
        self.addSubview(seperatorView)

        backButtonContent.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(titleLabel.snp.left)
        }

        backButton.snp.makeConstraints { (make) in
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-7)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.center.equalToSuperview()
        }
        
        seperatorView.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.left.right.bottom.equalToSuperview()
        }
        
        //增加返回图标可点击的范围
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickBackButton(sender:)))
        tapGesture.cancelsTouchesInView = false
        backButtonContent.addGestureRecognizer(tapGesture)
        
        backgroundColor = UIColor.ud.bgBody
        layer.cornerRadius = 12
        layer.maskedCorners = .top
        layer.masksToBounds = true
    }

    public func updateTitle(_ title: String) {
        titleLabel.text = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didClickBackButton(sender: UIButton) {
        assertionFailure("Implemented by subclasses")
    }
}
