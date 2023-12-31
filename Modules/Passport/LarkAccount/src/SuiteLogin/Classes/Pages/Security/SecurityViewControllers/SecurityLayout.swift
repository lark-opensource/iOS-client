//
//  SecurityLayout.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/7/31.
//

import Foundation
import LarkUIKit

struct Security {
    struct Layout {
        static let desTopSpace: CGFloat = { Display.pad ? 112 : 68 }()
        static let desInputSpace: CFloat = 24
        static let buttonPadding: CGFloat = { Display.pad ? 57 : 16 }()
        static let inputButtonSpace: CGFloat = 32
        static let titleHeight: CGFloat = { Display.pad ? 56 : 44 }()
        static let titleTopSpace: CGFloat = 20
        static let verifyInputTopSpace: CGFloat = { Display.pad ? 68 : 60 }()
        static let verifyForgetButtonSpace: CGFloat = 20
        static let verifyForgetButtonBottomSpaceKeyboardShow: CGFloat = 20
        static let closeBtnRight: CGFloat = 12
        static let setPwdLeftPadding: CFloat = 8
    }
}
