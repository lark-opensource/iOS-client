//
//  Device.swift
//  MinutesFoundation
//
//  Created by yangyao on 2022/12/5.
//

import Foundation
import LarkEMM
import LarkSensitivityControl
import CoreTelephony

public enum DeviceToken: String {
    case isOnPhoneCall = "LARK-PSDA-minutes_record_check_is_incall"
    case pasteboardSubtitle = "LARK-PSDA-pasteboard-token-for-subtitle"
    case pasteboardComment = "LARK-PSDA-pasteboard-token-for-comments"
    case pasteboardRecord = "LARK-PSDA-pasteboard-token-for-record"
    case pasteboardSummary = "LARK-PSDA-pasteboard-token-for-summary"
    case microphoneAccess = "LARK-PSDA-minutes_request_microphone_access"
}

public class Device {
    public static func IsOnPhoneCall() -> Bool {
        do {
            let calls = try DeviceInfoEntry.currentCalls(forToken: Token(withIdentifier: DeviceToken.isOnPhoneCall.rawValue), callCenter: CTCallCenter())
            return calls?.isEmpty == false
        } catch {
            return false
        }
    }
    
    public static func pasteboard(token: DeviceToken, text: String) {
        let config = PasteboardConfig(token: Token(withIdentifier: token.rawValue))
        SCPasteboard.general(config).string = text
    }
}
