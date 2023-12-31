//
//  LarkAcountDependcy.swift
//  TTMicroApp
//
//  Created by  bytedance on 2022/4/11.
//

import Foundation
import LarkAccountInterface

@objcMembers public final class LarkAcountDependcy: NSObject {
    @objc
    public static func isFeishuBrand() -> Bool {
        return AccountServiceAdapter.shared.isFeishuBrand
    }
}
