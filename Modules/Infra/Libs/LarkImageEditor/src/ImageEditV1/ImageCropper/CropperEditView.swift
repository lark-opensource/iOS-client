//
//  CropperEditView.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2018/8/3.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

protocol CropperEditViewDelegate: AnyObject {
    func editViewDidTapRotate(_ view: CropperEditView)
    func editViewDidTapRevert(_ view: CropperEditView)
}

final class CropperEditView: UIView {
    private lazy var rotateButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(Resources.edit_rotate, for: .normal)
        button.setImage(Resources.edit_rotate_highlight, for: .highlighted)
        button.addTarget(self, action: #selector(rotateButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var revertButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(Resources.edit_revert, for: .normal)
        button.setImage(Resources.edit_revert_highlight, for: .highlighted)
        button.addTarget(self, action: #selector(revertButtonTapped), for: .touchUpInside)
        return button
    }()

    private let buttonSize = CGSize(width: 24, height: 24)

    weak var delegate: CropperEditViewDelegate?

    var showRevert: Bool = false {
        didSet {
            revertButton.isHidden = !showRevert
        }
    }

    var isEnabled: Bool = true {
        didSet {
            self.rotateButton.isEnabled = isEnabled
            self.revertButton.isEnabled = isEnabled
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)

        self.addSubview(rotateButton)
        rotateButton.snp.makeConstraints { (make) in
            make.size.equalTo(buttonSize)
            make.left.equalTo(20)
            make.top.equalToSuperview()
            make.bottom.equalTo(-20)
        }

        self.addSubview(revertButton)
        revertButton.snp.makeConstraints { (make) in
            make.size.equalTo(buttonSize)
            make.right.equalTo(-20)
            make.top.equalToSuperview()
            make.bottom.equalTo(-20)
        }
        revertButton.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func rotateButtonTapped() {
        self.delegate?.editViewDidTapRotate(self)
    }

    @objc
    private func revertButtonTapped() {
        self.delegate?.editViewDidTapRevert(self)
    }
}
