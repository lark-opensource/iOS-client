//
//  BTKeyboardInputAccessoryView.swift
//  DocsSDK
//
//  Created by Webster on 2020/3/13.
//

import Foundation
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignShadow

protocol BTKeyboardInputAccessoryViewDelegate: AnyObject {
    func didRequestFinishEdit(_ view: BTKeyboardInputAccessoryView)
}

final class BTKeyboardInputAccessoryView: UIView {

    weak var delegate: BTKeyboardInputAccessoryViewDelegate?

    lazy var closeButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.SKResource.Bitable_BTModule_Done, for: .normal)
        btn.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.addTarget(self, action: #selector(requestFinishEdit), for: .touchUpInside)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgFloat
        layer.ud.setShadow(type: .s4Up)
        addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func requestFinishEdit() {
        delegate?.didRequestFinishEdit(self)
    }

}
