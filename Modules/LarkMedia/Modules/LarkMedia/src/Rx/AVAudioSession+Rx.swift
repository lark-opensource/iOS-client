//
//  AVAudioSession+Rx.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2020/9/16.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa
import LKCommonsLogging

// MARK: Public
public extension LarkAudioSession {

    internal static let scheduler = SerialDispatchQueueScheduler(queue: AudioQueue.callback.queue,
                                                                 internalSerialQueueName: "AudioSessionScenarioScheduler")

    static func activateNotification() {
        AudioQueue.execute.async("activateNotification") {
            _ = routeChangeRelay
            _ = interruptionRelay
            _ = silenceSecondaryAudioHintRelay
            _ = mediaServicesLostRelay
            _ = mediaServicesResetRelay
            _ = outputVolumeInfoRelay
            if #available(iOS 15.1, *) {
                _ = spatialPlaybackCapabilitiesChangedRelay
            }
        }
    }
}

public extension Reactive where Base: LarkAudioSession {

    static var routeChangeObservable: Observable<AVAudioSession.RouteChangeReason> {
        return Base.routeChangeRelay
            .asObservable()
            .observeOn(Base.scheduler)
    }

    static var audioOutputObservable: Observable<AudioOutput> {
        return Base.audioOutputRelay
            .asObservable()
            .observeOn(Base.scheduler)
    }

    static var interruptionObservable: Observable<InterruptionInfo> {
        return Base.interruptionRelay
            .asObservable()
            .observeOn(Base.scheduler)
    }

    static var audioOutputDriver: Driver<AudioOutput> {
        return Base.audioOutputRelay
            .distinctUntilChanged()
            .asDriver(onErrorRecover: { _ in return .empty() })
    }

    static var silenceSecondaryAudioHintObservable: Observable<AVAudioSession.SilenceSecondaryAudioHintType> {
        return Base.silenceSecondaryAudioHintRelay
            .asObservable()
            .observeOn(Base.scheduler)
    }

    static var mediaServicesResetObservable: Observable<Void> {
        return Base.mediaServicesResetRelay
            .asObservable()
            .observeOn(Base.scheduler)
    }

    static var mediaServicesLostObservable: Observable<Void> {
        return Base.mediaServicesLostRelay
            .asObservable()
            .observeOn(Base.scheduler)
    }

#if compiler(>=5.5)
    @available(iOS 15.1, *)
    static var spatialPlaybackCapabilitiesChangedObservable: Observable<Bool> {
        return Base.spatialPlaybackCapabilitiesChangedRelay
            .asObservable()
            .observeOn(Base.scheduler)
    }
#endif

    /// 该接口需要存在MPVolumeView才能生效
    static var outputVolumeInfoObservable: Observable<AudioVolumeInfo?> {
        return Base.outputVolumeInfoRelay
            .asObservable()
            .observeOn(Base.scheduler)
    }
}

// MARK: Private
extension LarkAudioSession {

    static let routeChangeRelay: BehaviorRelay<AVAudioSession.RouteChangeReason> = {
        let relay = BehaviorRelay<AVAudioSession.RouteChangeReason>(value: .unknown)

        _ = NotificationCenter.default.addObserver(forName: LarkAudioSession.lkRouteChangeNotification, object: nil, queue: nil,
                                                   using: { notification in
            relay.accept(notification.routeChangeReason ?? .unknown)
            logger.info(
                """
                receive AVAudioSession.lkRouteChangeNotification:
                reason: \(notification.routeChangeReason?.description ?? "nil"),
                before: \(notification.previousRoute?.description ?? "nil"),
                after: \(notification.currentRoute?.description ?? "nil")
                """
            )
            AudioTracker.shared.trackAudioEvent(key: .routeChange, params: [
                "reason": notification.routeChangeReason?.description ?? "nil",
                "before": notification.previousRoute?.description ?? "nil",
                "after": notification.currentRoute?.description ?? "nil"
            ])
        })
        return relay
    }()

    static let audioOutputRelay: BehaviorRelay<AudioOutput> = {
        let relay = BehaviorRelay<AudioOutput>(value: .unknown)

        _ = rx.routeChangeObservable
            .subscribeOn(scheduler)
            .subscribe(onNext: { _ in
                relay.accept(LarkAudioSession.shared.currentOutput)
            })

        return relay
    }()

    static let interruptionRelay: PublishRelay<InterruptionInfo> = {
        let relay = PublishRelay<InterruptionInfo>()

        _ = NotificationCenter.default.rx
            .notification(AVAudioSession.interruptionNotification, object: LarkAudioSession.shared.avAudioSession)
            .observeOn(scheduler)
            .subscribe(onNext: { notification in
                guard let type = notification.interruptionType else {
                    logger.warn("receive AVAudioSession.interruptionNotification but no data")
                    AudioTracker.shared.trackAudioEvent(key: .interruption, params: [:])
                    return
                }
                let interruptionInfo = InterruptionInfo(type: type,
                                                        options: notification.interruptionOptions ?? [],
                                                        reason: notification.wrappedInterruptionReason ?? .unknown)
                relay.accept(interruptionInfo)
            })

        _ = relay
            .map { (shared.currentRoute, $0) }
            .scan((nil, nil)) { ($0.1, $1) }
            .subscribeOn(scheduler)
            .subscribe(onNext: { last, cur in
                logger.warn(
                    """
                    receive AVAudioSession.interruptionNotification:
                    type: \(cur?.1.type.description ?? "nil"),
                    option: \(cur?.1.options.description ?? "nil"),
                    reason: \(cur?.1.reason.description ?? "nil"),
                    before: \(last?.0.description ?? "nil"),
                    after: \(cur?.0.description ?? "nil")
                    """
                )
                AudioTracker.shared.trackAudioEvent(key: .interruption, params: [
                    "type": cur?.1.type.description ?? "nil",
                    "options": cur?.1.reason.description ?? "nil",
                    "before": last?.0.description ?? "nil",
                    "after": cur?.0.description ?? "nil"
                ])
            })

        return relay
    }()

    static let silenceSecondaryAudioHintRelay: PublishRelay<AVAudioSession.SilenceSecondaryAudioHintType> = {
        let relay = PublishRelay<AVAudioSession.SilenceSecondaryAudioHintType>()

        _ = NotificationCenter.default.rx
            .notification(AVAudioSession.silenceSecondaryAudioHintNotification, object: LarkAudioSession.shared.avAudioSession)
            .observeOn(scheduler)
            .subscribe(onNext: { notification in
                guard let type = notification.silenceSecondaryAudioHintType else {
                    logger.debug("receive AVAudioSession.silenceSecondaryAudioHintNotification but no data")
                    AudioTracker.shared.trackAudioEvent(key: .silenceSecondaryAudio, params: ["type": "nil"])
                    return
                }
                logger.debug("receive AVAudioSession.silenceSecondaryAudioHintNotification: \(type.description)")
                AudioTracker.shared.trackAudioEvent(key: .silenceSecondaryAudio, params: ["type": type.description])
                relay.accept(type)
            })

        return relay
    }()

    static let mediaServicesResetRelay: PublishRelay<Void> = {
        let relay = PublishRelay<Void>()

        _ = NotificationCenter.default.rx
            .notification(AVAudioSession.mediaServicesWereResetNotification, object: LarkAudioSession.shared.avAudioSession)
            .observeOn(scheduler)
            .subscribe(onNext: { notification in
                logger.warn("receive AVAudioSession.mediaServicesWereResetNotification")
                AudioTracker.shared.trackAudioEvent(key: .mediaServicesReset, params: [:])
                relay.accept(())
            })

        return relay
    }()

    static let mediaServicesLostRelay: PublishRelay<Void> = {
        let relay = PublishRelay<Void>()

        _ = NotificationCenter.default.rx
            .notification(AVAudioSession.mediaServicesWereLostNotification, object: LarkAudioSession.shared.avAudioSession)
            .observeOn(scheduler)
            .subscribe(onNext: { notification in
                logger.warn("receive AVAudioSession.mediaServicesWereLostNotification")
                AudioTracker.shared.trackAudioEvent(key: .mediaServicesLost, params: [:])
                relay.accept(())
            })

        return relay
    }()

#if compiler(>=5.5)
    @available(iOS 15.1, *)
    static let spatialPlaybackCapabilitiesChangedRelay: PublishRelay<Bool> = {
        let relay = PublishRelay<Bool>()

        _ = NotificationCenter.default.rx
            .notification(AVAudioSession.spatialPlaybackCapabilitiesChangedNotification, object: LarkAudioSession.shared.avAudioSession)
            .observeOn(scheduler)
            .subscribe(onNext: { notification in
                guard let spatialAudioEnabled = notification.userInfo?[AVAudioSessionSpatialAudioEnabledKey] as? Bool else {
                    logger.debug("receive AVAudioSession.spatialPlaybackCapabilitiesChangedNotification but no data")
                    return
                }
                logger.debug("receive AVAudioSession.spatialPlaybackCapabilitiesChangedNotification")
                relay.accept(spatialAudioEnabled)
            })

        return relay
    }()
#endif

    static let outputVolumeInfoRelay: PublishRelay<AudioVolumeInfo?> = {
        let relay = PublishRelay<AudioVolumeInfo?>()

        if #available(iOS 15.0, *) {
            _ = NotificationCenter.default.rx
                .notification(NSNotification.Name(rawValue: "SystemVolumeDidChange"), object: LarkAudioSession.shared.avAudioSession)
                .observeOn(scheduler)
                .subscribe(onNext: { notification in
                    // 过滤 FigSystemControllerRemote 触发的相同通知
                    guard String(describing: notification.object).contains("AVSystemController") else { return }
                    let volumeInfo = notification.volumeInfo
                    logger.debug(
                        """
                        receive SystemVolumeDidChange:
                        audioVolume: \(volumeInfo?.audioVolume.description ?? "nil")
                        userVolumeAboveEUVolumeLimit: \(volumeInfo?.userVolumeAboveEUVolumeLimit.description ?? "nil"),
                        changeReason: \(volumeInfo?.changeReason.description ?? "nil")
                        category: \(volumeInfo?.category.description ?? "nil")
                        """
                    )
                    relay.accept(volumeInfo)
                })
        } else {
            _ = NotificationCenter.default.rx
                .notification(NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: LarkAudioSession.shared.avAudioSession)
                .observeOn(scheduler)
                .subscribe(onNext: { notification in
                    let volumeInfo = notification.volumeInfo
                    logger.debug(
                        """
                        receive AVSystemController_SystemVolumeDidChangeNotification:
                        audioVolume: \(volumeInfo?.audioVolume.description ?? "nil")
                        userVolumeAboveEUVolumeLimit: \(volumeInfo?.userVolumeAboveEUVolumeLimit.description ?? "nil"),
                        changeReason: \(volumeInfo?.changeReason.description ?? "nil")
                        category: \(volumeInfo?.category.description ?? "nil")
                        """
                    )
                    relay.accept(volumeInfo)
                })
        }

        return relay
    }()
}
