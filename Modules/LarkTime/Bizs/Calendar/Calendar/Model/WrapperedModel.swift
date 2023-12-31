//
//  Model.swift
//  Calendar
//
//  Created by zc on 2018/7/24.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RustPB

extension RustPB.Basic_V1_Chat: CalendarChat {
    public var isShortCut: Bool {
        get { return self.isShortcut }
        set { self.isShortcut = newValue }
    }

    public var isMember: Bool {
        return self.role == .member
    }
}
