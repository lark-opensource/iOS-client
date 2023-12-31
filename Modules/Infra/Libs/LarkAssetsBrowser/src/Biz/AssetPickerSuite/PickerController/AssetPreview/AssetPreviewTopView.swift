//
//  AssetPreviewTopView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/2.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit

protocol AssetPreviewTopViewDelegate: AnyObject {
    func topViewBackButtonDidClick(_ topView: AssetPreviewTopView)
    func topViewNumberButtonDidClick(_ topView: AssetPreviewTopView)
}

final class AssetPreviewTopView: UIView {
    enum Style {
        case cancel, back
    }

    var style: Style = .back {
        didSet {
            switch style {
            case .cancel:
                cancelButton.isHidden = false
                backButton.isHidden = true
            case .back:
                cancelButton.isHidden = true
                backButton.isHidden = false
            }
        }
    }

    weak var delegate: AssetPreviewTopViewDelegate?

    var selectIndex: Int? {
        didSet {
            // 这里需要外界传入的index + 1表示选中的数量
            if let index = selectIndex {
                numberBox.number = index + 1
            } else {
                numberBox.number = nil
            }
        }
    }

    private let contentView = UIView()
    private let backButton = UIButton()
    private let cancelButton = UIButton()
    private let numberBox = NumberBox(number: nil)

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 33 / 255, green: 33 / 255, blue: 33 / 255, alpha: 0.8)

        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(44)
        }

        contentView.addSubview(backButton)
        backButton.setImage(Resources.navigation_back_white_light, for: .normal)
        backButton.setTitle(BundleI18n.LarkAssetsBrowser.Lark_Legacy_Back, for: .normal)
        backButton.addTarget(self, action: #selector(backOrCancelButtonDidClick), for: .touchUpInside)
        backButton.titleLabel?.adjustsFontSizeToFitWidth = true
        backButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(cancelButton)
        cancelButton.setTitle(BundleI18n.LarkAssetsBrowser.Lark_Legacy_Cancel, for: .normal)
        cancelButton.addTarget(self, action: #selector(backOrCancelButtonDidClick), for: .touchUpInside)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        cancelButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        cancelButton.isHidden = true

        numberBox.delegate = self
        contentView.addSubview(numberBox)
        numberBox.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(CGSize(width: 30, height: 30))
            make.centerY.equalToSuperview()
        }
    }

    @objc
    private func backOrCancelButtonDidClick() {
        delegate?.topViewBackButtonDidClick(self)
    }

    @objc
    private func numberButtonDidClick() {
        delegate?.topViewNumberButtonDidClick(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AssetPreviewTopView: NumberBoxDelegate {
    func didTapNumberbox(_ numberBox: NumberBox) {
        numberButtonDidClick()
    }
}
