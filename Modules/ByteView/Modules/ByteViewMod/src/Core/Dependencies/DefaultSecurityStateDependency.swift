//
//  DefaultSecurityStateDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2023/1/3.
//

import Foundation
import ByteView
import ByteViewCommon
import UIKit

final class DefaultSecurityStateDependency: SecurityStateDependency {
    func didSecurityViewAppear() -> Bool {
        return false
    }

    // 截屏录屏保护（共享屏幕场景豁免保护）
    func vcScreenCastChange(_ vcCast: Bool) {}

    func setPasteboardText(_ message: String, token: String, shouldImmunity: Bool) -> Bool {
        UIPasteboard.general.string = message
        return true
    }

    func getPasteboardText(token: String) -> String? {
        return UIPasteboard.general.string
    }
}
