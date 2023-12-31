//
//  MinutesMonitor.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/7/14.
//

import Foundation
import LKCommonsLogging

public enum InnoPerfScene: String {
    case minutesHome = "MinutesHome"
    case minutesDetail = "MinutesDetail"
    case minutesRecording = "MinutesRecording"
    case minutesPodcast = "MinutesPodcast"
    case larkLive = "LarkLive"
    case minutesClip = "MinutesClip"
}

public final class InnoPerfMonitor {

    static let logger = Logger.log(InnoPerfMonitor.self, category: "InnoPerfMonitor")

    public static let shared = InnoPerfMonitor()

    private init() {
        Self.logger.debug("init")
        reporters = [InnoPerfPowerStatisticsReporter(workQueue: queue)]
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterforeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    let queue: DispatchQueue = DispatchQueue(label: "MinutesMonitor", qos: .background, autoreleaseFrequency: .workItem)

    var reporters: [Reporter]

    var scenes: [InnoPerfScene] = [] {
        didSet {
            guard oldValue.last != scenes.last else { return }
            let restart = !scenes.isEmpty
            fire(restart)
        }
    }

    var background: Bool = false {
        didSet {
            if !scenes.isEmpty {
                fire()
            }
        }
    }

    var floating: Bool = false {
        didSet {
            if !scenes.isEmpty {
                fire()
            }
        }
    }

    var extra: [String: Any] = [:]
    var category: [String: Any] {
        var value: [String: Any] = [:]
        value["scene"] = scenes.last?.rawValue
        value["background"] = background
        value["floating"] = floating
        return value
    }

    func fire(_ keepAlive: Bool = true) {

        let category = self.category
        reporters.forEach { $0.fire(keepAlive: keepAlive, category: category) }

    }

    @objc func didEnterBackground() {
        update(background: true)
    }

    @objc func willEnterforeground() {
        update(background: false)
    }
}

extension InnoPerfMonitor {
    public func entry(scene: InnoPerfScene) {
        queue.async {
            var scenes = self.scenes
            scenes.removeAll { $0 == scene }
            // 目前，只有MinutesHome场景会和其他场景同时出现。 降低该场景优先级。
            if self.floating {
                let index = scenes.endIndex - 1 > 0 ? scenes.endIndex - 1 : 0
                scenes.insert(scene, at: index)
            } else {
                scenes.append(scene)
            }
            self.scenes = scenes
        }
    }

    public func leave(scene: InnoPerfScene) {
        queue.async {
            var scenes = self.scenes
            if scenes.contains(scene) {
                scenes.removeAll { $0 == scene }
                self.scenes = scenes
            }
        }
    }

    public func update(background: Bool) {
        queue.async {
            self.background = background
        }

    }

    public func update(floating: Bool) {
        queue.async {
            self.floating = floating
        }
    }

    public func update(extra: [String: Any]) {
        queue.async {
            for (key, value) in extra {
                self.extra[key] = value
            }
            self.reporters.forEach { $0.update(extra: self.extra) }
        }
    }

    public func setExtra(_ extra: [String: Any]) {
        queue.async {
            self.extra = extra
            self.reporters.forEach { $0.update(extra: self.extra) }
        }
    }
}
