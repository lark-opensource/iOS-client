//
//  AVAudioSessionHooker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/27.
//

import AVFAudio

public extension LarkAudioSession {
    // Notification Define
    static let categoryHasChanged = Notification.Name("LarkAudioSession.categoryHasChanged")
    static let modeHasChanged = Notification.Name("LarkAudioSession.modeHasChanged")
    static let activeHasChanged = Notification.Name("LarkAudioSession.activeHasChanged")
    static let categoryValue = Notification.Name("LarkAudioSession.categoryValue")
    static let modeValue = Notification.Name("LarkAudioSession.modeValue")
    static let categoryChangeError = Notification.Name("LarkAudioSession.categoryChangeError")
    static let activeValue = Notification.Name("LarkAudioSession.activeValue")
    static let activeError = Notification.Name("LarkAudioSession.activeError")
}

class AVAudioSessionHooker: Hooker {

    lazy var setterArray: [(Selector, Selector)] = {
        var array = [
            (
                #selector(AVAudioSession.setMode(_:)),
                #selector(AVAudioSession.lk_setMode(_:))
            ), (
                #selector(AVAudioSession.setCategory(_:)),
                #selector(AVAudioSession.lk_setCategory(_:))
            ), (
                #selector(AVAudioSession.setCategory(_:options:)),
                #selector(AVAudioSession.lk_setCategory(_:options:))
            ), (
                #selector(AVAudioSession.setCategory(_:mode:options:)),
                #selector(AVAudioSession.lk_setCategory(_:mode:options:))
            ), (
                #selector(AVAudioSession.setCategory(_:mode:policy:options:)), #selector(AVAudioSession.lk_setCategory(_:mode:policy:options:))
            ), (
                #selector(AVAudioSession.setActive(_:options:)),
                #selector(AVAudioSession.lk_setActive(_:options:))
            ), (
                #selector(AVAudioSession.overrideOutputAudioPort(_:)),
                #selector(AVAudioSession.lk_overrideOutputAudioPort(_:))
            ), (
                #selector(AVAudioSession.setPreferredInput(_:)),
                #selector(AVAudioSession.lk_setPreferredInput(_:))
            ), (
                #selector(AVAudioSession.setPreferredSampleRate(_:)),
                #selector(AVAudioSession.lk_setPreferredSampleRate(_:))
            ), (
                #selector(AVAudioSession.setInputGain(_:)),
                #selector(AVAudioSession.lk_setInputGain(_:))
            ), (
                #selector(AVAudioSession.setPreferredIOBufferDuration(_:)),
                #selector(AVAudioSession.lk_setPreferredIOBufferDuration(_:))
            ), (
                #selector(AVAudioSession.setPreferredInputNumberOfChannels(_:)),
                #selector(AVAudioSession.lk_setPreferredInputNumberOfChannels(_:))
            ), (
                #selector(AVAudioSession.setPreferredOutputNumberOfChannels(_:)),
                #selector(AVAudioSession.lk_setPreferredOutputNumberOfChannels(_:))
            ), (
                #selector(AVAudioSession.setInputDataSource(_:)),
                #selector(AVAudioSession.lk_setInputDataSource(_:))
            ), (
                #selector(AVAudioSession.setOutputDataSource(_:)),
                #selector(AVAudioSession.lk_setOutputDataSource(_:))
            ), (
                #selector(AVAudioSession.setAggregatedIOPreference(_:)),
                #selector(AVAudioSession.lk_setAggregatedIOPreference(_:))
            ),
        ]
        if #available(iOS 13, *) {
            array.append((#selector(AVAudioSession.setAllowHapticsAndSystemSoundsDuringRecording(_:)),
                          #selector(AVAudioSession.lk_setAllowHapticsAndSystemSoundsDuringRecording(_:))))
        }
        if #available(iOS 14.5, *) {
            array.append((#selector(AVAudioSession.setPrefersNoInterruptionsFromSystemAlerts(_:)),
                          #selector(AVAudioSession.lk_setPrefersNoInterruptionsFromSystemAlerts(_:))))
        }
        if #available(iOS 15, *) {
            array.append((#selector(AVAudioSession.setSupportsMultichannelContent(_:)),
                          #selector(AVAudioSession.lk_setSupportsMultichannelContent(_:))))
        }
        return array
    }()

    func willHook() {
        LarkAudioSession.shared._category = .soloAmbient
        LarkAudioSession.shared._categoryOptions = []
        LarkAudioSession.shared._mode = .default
        LarkAudioSession.shared._routeSharingPolicy = .default
    }

    func hook() {
        setterArray.forEach {
            swizzleInstanceMethod(AVAudioSession.self, from: $0.0, to: $0.1)
        }
    }

    func didHook() {
        AudioQueue.execute.async("hook AVAudioSession") {
            let session = LarkAudioSession.shared.avAudioSession
            LarkAudioSession.shared._category = session.category
            LarkAudioSession.shared._categoryOptions = session.categoryOptions
            LarkAudioSession.shared._mode = session.mode
            LarkAudioSession.shared._routeSharingPolicy = session.routeSharingPolicy
        }
        LarkAudioSession.logger.info("AVAudioSession swizzle start")
    }
}

private extension AVAudioSession {
    func categoryCallBack(_ result: Result<Void, Error>,
                          category: AVAudioSession.Category,
                          mode: AVAudioSession.Mode? = nil,
                          policy: AVAudioSession.RouteSharingPolicy? = nil,
                          options: AVAudioSession.CategoryOptions? = nil) {
        var userInfo: [AnyHashable: Any] = [LarkAudioSession.categoryValue: category]
        if let mode = mode {
            userInfo[LarkAudioSession.modeValue] = mode
        }
        switch result {
        case .success:
            LarkAudioSession.shared._category = category
            if let mode = mode {
                LarkAudioSession.shared._mode = mode
            }
            if let policy = policy {
                LarkAudioSession.shared._routeSharingPolicy = policy
            }
            if let options = options {
                LarkAudioSession.shared._categoryOptions = options
            }
        case .failure(let error):
            userInfo[LarkAudioSession.categoryChangeError] = error
            AudioTracker.shared.trackAudioEvent(key: .setCategoryFailed, params: ["error": error.localizedDescription])
        }
        NotificationCenter.default.post(name: LarkAudioSession.categoryHasChanged, object: self, userInfo: userInfo)
    }

    func modeCallBack(_ result: Result<Void, Error>, mode: AVAudioSession.Mode) {
        var userInfo: [AnyHashable: Any] = [LarkAudioSession.modeValue: mode]
        switch result {
        case .success:
            LarkAudioSession.shared._mode = mode
        case .failure(let error):
            userInfo[LarkAudioSession.categoryChangeError] = error
            AudioTracker.shared.trackAudioEvent(key: .setModeFailed, params: ["error": error.localizedDescription])
        }
        NotificationCenter.default.post(name: LarkAudioSession.modeHasChanged, object: self, userInfo: userInfo)
    }

    func activeCallBack(_ result: Result<Bool, Error>) {
        var userInfo: [AnyHashable: Any] = [:]
        switch result {
        case .success(let active):
            userInfo[LarkAudioSession.activeValue] = active
        case .failure(let error):
            userInfo[LarkAudioSession.activeError] = error.localizedDescription
            AudioTracker.shared.trackAudioEvent(key: .setActiveFailed, params: ["error": error.localizedDescription])
        }
        NotificationCenter.default.post(name: LarkAudioSession.activeHasChanged, object: self, userInfo: userInfo)
    }

    @objc func lk_setCategory(_ category: AVAudioSession.Category) throws {
        try LarkAudioSession.hook(category, block: {
            try lk_setCategory(category)
        }, completion: {
            categoryCallBack($0, category: category)
        })
    }

    @objc func lk_setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws {
        try LarkAudioSession.hook(category, options, block: {
            try lk_setCategory(category, options: options)
        }, completion: {
            categoryCallBack($0, category: category, options: options)
        })
    }

    @objc func lk_setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
        try LarkAudioSession.hook(category, mode, options, block: {
            try lk_setCategory(category, mode: mode, options: options)
        }, completion: {
            categoryCallBack($0, category: category, mode: mode, options: options)
        })
    }

    @objc func lk_setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, policy: AVAudioSession.RouteSharingPolicy, options: AVAudioSession.CategoryOptions) throws {
        try LarkAudioSession.hook(category, mode, policy, options, block: {
            try lk_setCategory(category, mode: mode, policy: policy, options: options)
        }, completion: {
            categoryCallBack($0, category: category, mode: mode, policy: policy, options: options)
        })
    }

    @objc func lk_setMode(_ mode: AVAudioSession.Mode) throws {
        try LarkAudioSession.hook(mode, block: {
            try lk_setMode(mode)
        }, completion: {
            modeCallBack($0, mode: mode)
        })
    }

    @objc func lk_setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        try LarkAudioSession.hook(active, options, block: {
            try lk_setActive(active, options: options)
        }, completion: {
            activeCallBack($0.map({ _ in active }))
        })
    }
}

private extension AVAudioSession {
    @objc func lk_setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws {
        try LarkAudioSession.hook(inValue, block: {
            try lk_setAllowHapticsAndSystemSoundsDuringRecording(inValue)
        }, completion: { _ in

        })
    }

    @objc func lk_overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws {
        try LarkAudioSession.hook(portOverride, block: {
            try lk_overrideOutputAudioPort(portOverride)
        }, completion: { _ in

        })
    }

    @objc func lk_setPreferredInput(_ inPort: AVAudioSessionPortDescription?) throws {
        try LarkAudioSession.hook(inPort, block: {
            try lk_setPreferredInput(inPort)
        }, completion: { _ in

        })
    }

    @objc func lk_setPreferredSampleRate(_ sampleRate: Double) throws {
        try LarkAudioSession.hook(sampleRate, block: {
            try lk_setPreferredSampleRate(sampleRate)
        }, completion: { _ in

        })
    }

    @objc func lk_setPreferredIOBufferDuration(_ duration: TimeInterval) throws {
        try LarkAudioSession.hook(duration, block: {
            try lk_setPreferredIOBufferDuration(duration)
        }, completion: { _ in

        })
    }

    @objc func lk_setPreferredInputNumberOfChannels(_ count: Int) throws {
        try LarkAudioSession.hook(count, block: {
            try lk_setPreferredInputNumberOfChannels(count)
        }, completion: { _ in

        })
    }

    @objc func lk_setPreferredOutputNumberOfChannels(_ count: Int) throws {
        try LarkAudioSession.hook(count, block: {
            try lk_setPreferredOutputNumberOfChannels(count)
        }, completion: { _ in

        })
    }

    @objc func lk_setPreferredInputOrientation(_ orientation: AVAudioSession.StereoOrientation) throws {
        try LarkAudioSession.hook(orientation, block: {
            try lk_setPreferredInputOrientation(orientation)
        }, completion: { _ in

        })
    }

    @objc func lk_setInputGain(_ gain: Float) throws {
        try LarkAudioSession.hook(gain, block: {
            try lk_setInputGain(gain)
        }, completion: { _ in

        })
    }

    @objc func lk_setInputDataSource(_ dataSource: AVAudioSessionDataSourceDescription?) throws {
        try LarkAudioSession.hook(dataSource, block: {
            try lk_setInputDataSource(dataSource)
        }, completion: { _ in

        })
    }

    @objc func lk_setOutputDataSource(_ dataSource: AVAudioSessionDataSourceDescription?) throws {
        try LarkAudioSession.hook(dataSource, block: {
            try lk_setOutputDataSource(dataSource)
        }, completion: { _ in

        })
    }

    @objc func lk_setAggregatedIOPreference(_ inIOType: AVAudioSession.IOType) throws {
        try LarkAudioSession.hook(inIOType, block: {
            try lk_setAggregatedIOPreference(inIOType)
        }, completion: { _ in

        })
    }

    @objc func lk_setSupportsMultichannelContent(_ inValue: Bool) throws {
        try LarkAudioSession.hook(inValue, block: {
            try lk_setSupportsMultichannelContent(inValue)
        }, completion: { _ in

        })
    }

    @objc func lk_setPrefersNoInterruptionsFromSystemAlerts(_ inValue: Bool) throws {
        try LarkAudioSession.hook(inValue, block: {
            try lk_setPrefersNoInterruptionsFromSystemAlerts(inValue)
        }, completion: { _ in

        })
    }
}
