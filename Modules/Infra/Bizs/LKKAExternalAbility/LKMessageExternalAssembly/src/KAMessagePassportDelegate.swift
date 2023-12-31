//
//  KAMessagePassportDelegate.swift
//  LKMessageExternalAssembly
//
//  Created by Ping on 2023/11/23.
//

import LKMessageExternal
import LarkAccountInterface

final class KAMessagePassportDelegate: PassportDelegate {
    func userDidOnline(state: PassportState) {
        switch state.action {
        case .fastLogin, .login, .switch:
            KAMessageExternal.shared.navigator = KAMessageNavigatorImp()
        default: break
        }
    }
}
