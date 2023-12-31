//
//  PickerTracker.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/10/11.
//

import Foundation
import Homeric
#if canImport(LKCommonsTracker)
import LKCommonsTracker
class PickerTracker {
    var scene: String
    init(scene: String = "") {
        self.scene = scene
    }
    public func track(_ event: String, params: [String: Any]) {
        Tracker.post(TeaEvent(event, params: params))
    }
}
#else
class PickerTracker {
    var scene: String
    init(scene: String = "") {
        self.scene = scene
    }
    public func track(_ event: String, params: [String: Any]) {
        print("track(\(event)): \(params)")
    }
}
#endif

extension PickerTracker {
    func trackTargetPreviewShowed() {
        track(Homeric.PUBLIC_PICKER_SELECT_CLICK, params: pickerTrackInfo(scene: self.scene, target: "none", click: "chat_detail"))
    }

    func pickerTrackInfo(
        scene: String? = nil,
        target: String,
        click: String
    ) -> [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["target"] = target
        trackInfo["click"] = click
        if let scene = scene {
            trackInfo["scene"] = scene
        } else {
            trackInfo["scene"] = "others"
        }
        return trackInfo
    }
}
