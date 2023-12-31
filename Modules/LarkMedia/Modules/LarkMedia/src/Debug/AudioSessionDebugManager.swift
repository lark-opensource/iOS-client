//
//  AudioSessionDebugManager.swift
//  AudioSessionScenario
//
//  Created by ford on 2020/6/8.
//

import Foundation

open class AudioSessionDebugManager {

    public static let shared = AudioSessionDebugManager()

    private init() {
        entryView = AudioSessionDebugEntryView()
    }

    private let entryView: AudioSessionDebugEntryView

    public var isEntryHidden: Bool {
        return entryView.isHidden
    }

    public func showEntry() {
        entryView.isHidden = false
    }

    public func hideEntry() {
        entryView.isHidden = true
    }
}
