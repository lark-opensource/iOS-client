//
//  RTCEntry.swift
//  LarkSensitivityControl
//
//  Created by yifan on 2023/4/24.
//

final public class RTCEntry {

    public static func checkTokenForStartAudioCapture(_ token: Token) throws {
        let context = Context([AtomicInfo.RTC.startAudioCapture.rawValue])
        try Assistant.checkToken(token, context: context)
    }

    public static func checkTokenForVoIPJoin(_ token: Token) throws {
        let context = Context([AtomicInfo.RTC.voIPJoin.rawValue])
        try Assistant.checkToken(token, context: context)
    }

    public static func checkTokenForStartVideoCapture(_ token: Token) throws {
        let context = Context([AtomicInfo.RTC.startVideoCapture.rawValue])
        try Assistant.checkToken(token, context: context)
    }
}
