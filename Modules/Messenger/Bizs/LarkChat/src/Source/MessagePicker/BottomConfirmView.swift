//
//  BottomConfirmView.swift
//  Lark
//
//  Created by zc09v on 2018/5/17.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit

final class BottomConfirmView: UIView {
    private let finishButton = UIButton(type: .custom)

    static let height: CGFloat = Display.iPhoneXSeries ? 32 + BottomConfirmView.buttonHeight : BottomConfirmView.buttonHeight

    static let buttonHeight: CGFloat = 49

    var cancelCallBack: ((UIButton) -> Void)?

    var finishCallBack: ((UIButton) -> Void)?

    var finishText: String = BundleI18n.LarkChat.Lark_Legacy_Finished

    override init(frame: CGRect) {
        super.init(frame: frame)

        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle(BundleI18n.LarkChat.Lark_Legacy_Cancel, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.N900, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.addTarget(self, action: #selector(cancelTapped(_:)), for: .touchUpInside)
        finishButton.setTitle(finishText, for: .normal)
        finishButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        finishButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        finishButton.addTarget(self, action: #selector(finishTapped(_:)), for: .touchUpInside)

        self.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(BottomConfirmView.buttonHeight)
            make.bottom.equalToSuperview().offset(-(BottomConfirmView.height - BottomConfirmView.buttonHeight))
        }

        self.addSubview(finishButton)
        finishButton.snp.makeConstraints { (make) in
            make.right.top.equalToSuperview()
            make.height.equalTo(cancelButton)
            make.width.equalToSuperview().multipliedBy(0.5)
        }

        let middleLine = UIView()
        middleLine.backgroundColor = UIColor.ud.N300
        self.addSubview(middleLine)
        middleLine.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(9.5)
            make.bottom.equalTo(cancelButton).offset(-9.5)
            make.width.equalTo(1 / UIScreen.main.scale)
        }

        self.layer.shadowOffset = CGSize(width: 0, height: -2)
        self.ud.setLayerShadowColor(UIColor.ud.staticBlack.withAlphaComponent(0.03))
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func cancelTapped(_ button: UIButton) {
        cancelCallBack?(button)
    }

    @objc
    private func finishTapped(_ button: UIButton) {
        finishCallBack?(button)
    }
}
