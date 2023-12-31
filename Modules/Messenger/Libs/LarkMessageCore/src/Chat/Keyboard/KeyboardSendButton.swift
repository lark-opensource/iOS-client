//
//  KeyboardSendButton.swift
//  LarkMessageCore
//
//  Created by bytedance on 6/28/22.
//

import Foundation
import UIKit
import LarkKeyboardView
import LarkMessageBase
import UniverseDesignIcon

public final class DefaultKeyboardSendButton: BaseKeyboardSendButton, KeyboardPanelRightContainerViewProtocol {

    public func layoutWith(superView: UIView) {
        self.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.size.equalTo(KeyboardPanel.ButtonSize)
            make.centerY.equalToSuperview().offset(-1)
        }
    }

    public func updateFor(_ scene: MessengerKeyboardPanel.Scene) {
        if case .sendButton(let enable) = scene {
            self.isEnabled = enable
            self.isUserInteractionEnabled = enable
        }
    }

    public init(enable: Bool) {
        super.init(enable: enable, longPressDuration: 0.4)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
