//
//  VideoConferenceService.swift
//  ByteView
//
//  Created by lvdaqian on 2018/7/19.
//

import Foundation

final class Resources {
    static let ringNotificationSoundName: String = "vc_call_ringing.mp3"
    static let springRingNotificationSoundName: String = "vc_call_ringing_spring.mp3"
}

extension Bundle {

    static let current = BundleConfig.SelfBundle

    static let localResources = Bundle(url: current.url(forResource: "ByteView", withExtension: "bundle")!)!

    static var ringingURL: URL? {
        return Bundle.main.url(forResource: "vc_call_ringing", withExtension: "mp3")
    }

    static var ringingSpringURL: URL? {
        return Bundle.main.url(forResource: "vc_call_ringing_spring", withExtension: "mp3")
    }

    static var countDownEndFilePath: String? {
        return Bundle.main.path(forResource: "meeting_count_down_end", ofType: "aac")
    }

    static var countDownRemindFilePath: String? {
        return Bundle.main.path(forResource: "meeting_count_down_remind", ofType: "aac")
    }

    var shortVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }

}

extension UIImage {

    convenience init?(localNamed name: String) {
        self.init(named: name, in: Bundle.localResources, compatibleWith: nil)
    }
}
