//
//  LarkAudioSessionManager.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/26.
//

import Foundation

final class LarkAudioSessionManager {

    @RwAtomic
    private var cachedScenarios: Set<AudioSessionScenarioWrapper> = Set([])

    private let monitor = HeartBeatMonitor<AudioSessionScenarioWrapper>(interval: 30, duration: 7200)

    var scene: MediaMutexScene
    init(scene: MediaMutexScene) {
        self.scene = scene
    }

    func release() {
        cachedScenarios.forEach {
            leave($0.scenario)
        }
    }
}

extension LarkAudioSessionManager: LarkAudioSessionService {
    public func enter(_ scenario: AudioSessionScenario,
                      options: ScenarioEntryOptions,
                      completion: AudioSessionScenarioCompletion?) {
        guard scene.isActive || !scene.isEnabled else {
            Self.logger.info("Enter Audio Session Scenario \(scenario.name) failed, not allowed")
            completion?()
            return
        }
        let scenarioWrapper = AudioSessionScenarioWrapper(scenario: scenario)
        cachedScenarios.insert(scenarioWrapper)
        monitor.addObservable(scenarioWrapper)
        Self._enter(scenario, options: options, completion: completion)
    }

    public func leave(_ scenario: AudioSessionScenario, options: ScenarioEntryOptions) {
        Self._leave(scenario, options: options)
        let scenarioWrapper = AudioSessionScenarioWrapper(scenario: scenario)
        monitor.removeObservable(scenarioWrapper)
        cachedScenarios.remove(scenarioWrapper)
    }

    public var activeScenario: [AudioSessionScenario] {
        Self.scenarioCache.values
    }
}

extension LarkAudioSessionManager {

    static let logger = LarkAudioSession.logger

    static let scenarioCache = LRUStack<AudioSessionScenario>()

    static let dispatchQueue = DispatchQueue(label: "LarkMedia.AudioSessionScenario.DispatchQueue", qos: .userInteractive)

    static func _enter(_ scenario: AudioSessionScenario,
                       options: ScenarioEntryOptions,
                       completion: AudioSessionScenarioCompletion?) {
        let tag = logger.getTag()
        logger.info(with: tag, "Enter Audio Session Scenario \(scenario.name) options: \(options)")
        AudioQueue.execute.async("enter scenario \(scenario.name)") {
            if !options.contains(.forceEntry) {
                guard scenario != scenarioCache.top() else {
                    logger.info(with: tag, "Enter Audio Session Scenario \(scenario.name) skip for repeated")
                    dispatchQueue.async {
                        completion?()
                    }
                    return
                }
            }
            if let mergedScenario = scenarioCache.reduce(scenario, { $0?.merge($1) }) {
                LarkAudioSession.shared._updateScenario(mergedScenario)
            }
            // 排除 enableSpeakerIfNeeded：0 && force: 0 的情况
            let enableSpeakerIfNeeded: Bool = options.contains(.enableSpeakerIfNeeded)
            let force: Bool = options.contains(.forceEnableSpeaker)
            if enableSpeakerIfNeeded || force {
                LarkAudioSession.shared._enableSpeakerIfNeeded(enable: enableSpeakerIfNeeded, force: force)
            }

            scenarioCache.use(scenario)
            if !options.contains(.manualActive) {
                _setActiveIfNeeded(true)
            }

            logger.info(with: tag, "Enter Audio Session Scenario \(scenario.name) finished")

            dispatchQueue.async {
                completion?()
            }
        }
    }

    static func _leave(_ scenario: AudioSessionScenario, options: ScenarioEntryOptions) {
        let tag = logger.getTag()
        logger.info(with: tag, "Leave Audio Session Scenario \(scenario.name) options: \(options)")
        AudioQueue.execute.async("leave scenario \(scenario.name)") {
            guard scenario.isActive else {
                logger.info(with: tag, "Leave Audio Session Scenario \(scenario.name) finished. scenario isNotActive.")
                return
            }
            scenarioCache.remove(scenario)
            if !options.contains(.disableCategoryChange),
               let lastScenario = scenarioCache.reduce(scenarioCache.top(), { $0?.merge($1) }) {
                logger.info(with: tag, "Leave Audio Session Scenario \(scenario.name) and then enter \(lastScenario.name)")
                LarkAudioSession.shared._updateScenario(lastScenario)
            }

            // deactive if no new scenario in 1 second
            AudioQueue.execute.async("deactive AVAudioSession after leave scenario \(scenario.name)", delay: .seconds(1)) {
                _setActiveIfNeeded(false)
                logger.info(with: tag, "Leave Audio Session Scenario \(scenario.name) finished")
            }
        }
    }

    static func _setActiveIfNeeded(_ active: Bool) {
        let isNeedActive = scenarioCache.exist({ $0.isNeedActive == true })
        guard active == isNeedActive else { return }
        LarkAudioSession.shared._setActive(active, enableResetSessionWhenDeactivating: scenarioCache.isEmpty)
    }
}
