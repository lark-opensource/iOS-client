//
//  KeyboardSchuduleSendButton.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2022/9/1.
//

import Foundation
import UIKit
import LarkSDKInterface
import LarkKeyboardView
import LarkMessageBase
import UniverseDesignIcon

public final class KeyboardSchuduleSendButton: UIView, KeyboardPanelRightContainerViewProtocol {
    public func layoutWith(superView: UIView) {
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    lazy var button: UIButton = {
        let btn = UIButton()
        return btn
    }()

    public var onTapCallback: (() -> Void)?

    public func updateFor(_ scene: MessengerKeyboardPanel.Scene) {
        if case .scheduleSend(let enable) = scene {
            self.button.isEnabled = enable
            self.button.isUserInteractionEnabled = enable
        }
    }

    public init(enable: Bool) {
        super.init(frame: .zero)
        backgroundColor = .ud.bgBodyOverlay
        addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8))
        }
        button.setTitle(BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_SendAtTime_ScheduleMessage_Button, for: .normal)
        button.titleLabel?.snp.makeConstraints({ make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        })
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.colorfulBlue), for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.fillDisabled), for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.colorfulBlue), for: .selected)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.colorfulBlue), for: .highlighted)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)
        button.lu.addTapGestureRecognizer(action: #selector(onTap), target: self)
        button.isEnabled = enable
        button.isUserInteractionEnabled = enable
    }

    @objc
    private func onTap() {
        onTapCallback?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
