//
//  SCPasteboardServiceImp.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/12/24.
//

import Foundation

extension PasteboardService {
    func shouldDisableThirdKeyboard() -> Bool {
        if SCPasteboard.enablePasteProtectOpt {
            return false
        } else {
            return self.checkProtectPermission()
        }
    }
}
