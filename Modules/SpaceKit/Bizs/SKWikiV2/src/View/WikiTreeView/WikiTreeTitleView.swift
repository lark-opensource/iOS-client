//
//  WikiTreeTitleView.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/26.
//

import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

protocol WikiTreeTitleView where Self: UIView {
    func setTitle(_ title: String)
}

class WikiTreeDraggleTitleView: UIView, WikiTreeTitleView {

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 0, height: 65)
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        label.textAlignment = .left
        return label
    }()

    private let topLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        view.layer.cornerRadius = 3
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(titleLabel)
        addSubview(topLine)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(18)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(33)
        }
        topLine.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(4)
            make.width.equalTo(40)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}

class WikiTreeNormalTitleView: UIView, WikiTreeTitleView {

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 0, height: 56)
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    let closeButton: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(titleLabel)
        addSubview(closeButton)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualTo(closeButton.snp.right).offset(20)
            make.right.lessThanOrEqualToSuperview().offset(-60)
        }
        closeButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}
