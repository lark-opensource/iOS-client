//
//  DriveAlertView.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/4/2.
//

/*
import UIKit

class DriveAlertView: UIView {

    var firstCallback: (() -> Void)?
    var secondCallback: (() -> Void)?
    var cancelCallback: (() -> Void)?

    private(set) lazy var backMaskView: UIView = {
        let mask = UIView(frame: .zero)
        mask.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.2)
        mask.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(maskTapClick(_:))))
        addSubview(mask)
        return mask
    }()

    private(set) lazy var contentView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.N00
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        addSubview(view)
        return view
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        contentView.addSubview(label)
        return label
    }()

    private(set) lazy var contentLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        contentView.addSubview(label)
        return label
    }()

    private(set) lazy var firstButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.addTarget(self, action: #selector(buttonClick(_:)), for: .touchUpInside)
        contentView.addSubview(button)
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.N300
        button.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        return button
    }()

    private(set) lazy var secondButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.addTarget(self, action: #selector(buttonClick(_:)), for: .touchUpInside)
        contentView.addSubview(button)
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.N300
        button.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        backMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(24)
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }

        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
    }
}

extension DriveAlertView {

    @objc
    private func buttonClick(_ button: UIButton) {
        if button == firstButton {
            firstCallback?()
        } else if button == secondButton {
            secondCallback?()
        }
        removeFromSuperview()
    }

    @objc
    private func maskTapClick(_ tap: UITapGestureRecognizer) {
        cancelCallback?()
        removeFromSuperview()
    }
}
*/
