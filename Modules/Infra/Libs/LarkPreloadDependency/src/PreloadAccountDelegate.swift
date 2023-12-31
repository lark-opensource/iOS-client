//
//  PreloadAccountDelegate.swift
//  LarkPreload
//
//  Created by huanglx on 2023/4/12.
//

import LarkAccountInterface
import LarkPreload

final class PreloadAccountDelegate: PassportDelegate {
    let name = "PreloadAccountDelegate"
    
    func stateDidChange(state: PassportState) {
       //切换账户
        if state.loginState == .offline {
           PreloadMananger.shared.switchAccount()
       }
    }
}
