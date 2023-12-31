//
//  ImageEditToolBar.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/8/2.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

protocol ImageEditToolBarDelegate: AnyObject {
    func toolBarDidClickCancel(toolBar: ImageEditToolBar)
    func toolBarDidClickFinish(toolBar: ImageEditToolBar)
}

final class ImageEditToolBar: UIView {
    private let cancelButton = UIButton()
    private let finishButton = UIButton()
    private let titleLabel = UILabel()

    private let buttonSize = CGSize(width: 40, height: 40)

    weak var delegate: ImageEditToolBarDelegate?

    init(title: String) {
        super.init(frame: CGRect.zero)

        cancelButton.setImage(Resources.edit_bottom_close, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonDidClick), for: .touchUpInside)
        addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(22)
            make.size.equalTo(buttonSize)
            make.left.equalToSuperview().offset(14)
        }

        finishButton.setImage(Resources.edit_bottom_save, for: .normal)
        finishButton.addTarget(self, action: #selector(finishButtonDidClick), for: .touchUpInside)
        addSubview(finishButton)
        finishButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(22)
            make.size.equalTo(buttonSize)
            make.right.equalToSuperview().offset(-14)
        }

        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.N00
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(22)
            make.centerX.equalToSuperview()
        }

        lu.addTopBorder(color: UIColor.ud.N300.withAlphaComponent(0.1))

        backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.9)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func cancelButtonDidClick() {
        delegate?.toolBarDidClickCancel(toolBar: self)
    }

    @objc
    private func finishButtonDidClick() {
        delegate?.toolBarDidClickFinish(toolBar: self)
    }
}
