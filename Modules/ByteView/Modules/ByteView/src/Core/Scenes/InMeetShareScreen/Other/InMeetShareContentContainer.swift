//
//  InMeetShareContentContainer.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/11/5.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

protocol OrientationAware {
    var isPortrait: Bool {
        get
        set
    }
    var isTranslucent: Bool {
        get
    }

    var backgroundView: UIView? {
        get
    }
}

extension OrientationAware {
    var isTranslucent: Bool {
        return false
    }

    var backgroundView: UIView? {
        return nil
    }
}
