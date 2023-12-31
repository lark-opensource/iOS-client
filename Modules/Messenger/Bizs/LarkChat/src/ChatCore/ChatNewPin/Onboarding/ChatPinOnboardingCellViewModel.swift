//
//  ChatPinOnboardingCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/11/5.
//

import Foundation
import EENavigator
import LarkSDKInterface
import LarkModel

final class ChatPinOnboardingCellViewModel: ChatPinCardContainerCellAbility {

    let closeHandler: () -> Void
    private let refreshHandler: () -> Void

    var height: CGFloat = 250 {
        didSet {
            if height != oldValue {
                self.refreshHandler()
            }
        }
    }

    init(closeHandler: @escaping () -> Void,
         refreshHandler: @escaping () -> Void) {
        self.closeHandler = closeHandler
        self.refreshHandler = refreshHandler
    }

    func getCellHeight() -> CGFloat {
        return height
    }
}
