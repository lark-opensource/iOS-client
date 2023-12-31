//
//  WindowTags.swift
//  ByteView
//
//  Created by kiri on 2021/5/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public enum WindowTag: Int {
    /// FloatingWindow
    case floating = 30307 // 'vc'
    /// ThemeAlertWindow
    case alert
    /// PromptWindow
    case prompt
    /// ToastWindow
    case toast
    /// broadcastWindow
    case broadcast
    /// ringrefuse
    case ringrefuse
}
