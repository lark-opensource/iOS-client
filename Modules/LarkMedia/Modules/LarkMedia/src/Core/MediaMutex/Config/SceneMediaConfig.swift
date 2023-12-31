//
//  SceneMediaConfig.swift
//  LarkMedia
//
//  Created by fakegourmet on 2022/7/7.
//

import Foundation

public class SceneMediaConfig {
    public let scene: MediaMutexScene
    public let sceneDescription: String
    var mediaConfig: [MediaMutexType: MediaMutexPriority]
    var mixConfig: [MediaMutexType: Bool]
    var isEnabled: Bool

    required init(scene: MediaMutexScene,
                  mediaConfig: [MediaMutexType: MediaMutexPriority],
                  mixConfig: [MediaMutexType: Bool] = [:],
                  sceneDescription: String = "",
                  isEnabled: Bool = true) {
        self.scene = scene
        self.mediaConfig = mediaConfig
        self.mixConfig = mixConfig
        self.sceneDescription = sceneDescription
        self.isEnabled = isEnabled
    }

    public init(scene: MediaMutexScene,
                rawConfig: [MediaMutexType: Int],
                mixWithOthers: Bool = false,
                sceneDescription: String = "",
                isEnabled: Bool = true) {
        self.scene = scene
        self.mediaConfig = rawConfig.compactMapValues { MediaMutexPriority(rawValue: UInt($0)) }
        self.mixConfig = [.play: mixWithOthers]
        self.sceneDescription = sceneDescription
        self.isEnabled = isEnabled
    }
}

extension SceneMediaConfig {

    var isActive: Bool {
        LarkMediaManager.shared.mediaMutex.lockers.map { $0.value }.reduce(false) { $0 || $1.contains(config: self) }
    }

    func config(options: MediaMutexOptions) -> Self {
        if options.contains(.mixWithOthers) {
            mixConfig[.play] = true
        }

        if scene.isMixRecordScene {
            mixConfig[.record] = true
        }

        if options.contains(.onlyAudio) {
            mediaConfig.removeValue(forKey: .camera)
        }
        return self
    }

    func config(mediaType: MediaMutexType, priority: MediaMutexPriority?) -> Self {
        if let priority = priority {
            mediaConfig[mediaType] = priority
        } else {
            mediaConfig.removeValue(forKey: mediaType)
        }
        return self
    }

    func merge(with config: SceneMediaConfig) -> Self {
        mixConfig.merge(config.mixConfig, uniquingKeysWith: { $0 || $1 })
        return self
    }

    func copy(scene: MediaMutexScene) -> Self {
        Self.init(scene: scene,
                  mediaConfig: mediaConfig,
                  mixConfig: mixConfig,
                  sceneDescription: sceneDescription,
                  isEnabled: isEnabled)
    }

    func mixWithOthers(_ mediaType: MediaMutexType) -> Bool {
        mixConfig[mediaType] ?? false
    }
}

extension SceneMediaConfig: Hashable {
    public static func == (lhs: SceneMediaConfig, rhs: SceneMediaConfig) -> Bool {
        lhs.scene == rhs.scene
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(scene)
    }
}

extension SceneMediaConfig: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        debugDescription
    }

    public var debugDescription: String {
        """
        scene: \(scene),
        mediaConfig: record: \(String(describing: mediaConfig[.record])), play: \(String(describing: mediaConfig[.play])), camera: \(String(describing: mediaConfig[.camera])),
        mixConfig: \(mixConfig),
        sceneDescription: \(sceneDescription),
        isEnabled: \(isEnabled)
        """
    }
}
