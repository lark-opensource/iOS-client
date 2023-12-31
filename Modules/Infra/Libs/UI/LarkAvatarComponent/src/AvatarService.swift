//
//  AvatarService.swift
//  LarkAvatarComponent
//
//  Created by 姚启灏 on 2020/6/17.
//

import Foundation
import RxSwift
import LKCommonsLogging

public struct AvatarTuple: Equatable {
    public var identifier: String
    public var avatarKey: String
    public var medalKey: String
    public var medalFsUnit: String

    public init(identifier: String = "",
                avatarKey: String = "",
                medalKey: String = "",
                medalFsUnit: String = "") {
        self.identifier = identifier
        self.avatarKey = avatarKey
        self.medalKey = medalKey
        self.medalFsUnit = medalFsUnit
    }
}

public struct AvatarPublishTuple {
    public var publish: PublishSubject<AvatarTuple>
    public var observer: Observable<AvatarTuple>

    public init(publish: PublishSubject<AvatarTuple>,
                observer: Observable<AvatarTuple>) {
        self.publish = publish
        self.observer = observer
    }
}

/// Responsible for avatar update
public final class AvatarService {

    /// Identifier mapping avatarTuple
    private static let identifierCacheLRU = CacheLRU<String, AvatarTuple>(capacity: 100)

    /// Identifier mapping UpdateCalllback array
    private static let publishCacheLRU = CacheLRU<String, AvatarPublishTuple>(capacity: 100)

    /// Input Observer
    /// Identifier and Avatarkey
    private static var inputObserver: Observable<[AvatarTuple]>?
    private static let logger = Logger.log(AvatarService.self, category: "AvatarService")

    private static let lruIOQueue: DispatchQueue = DispatchQueue(label: "AvatarService.lruIOQueue")

    private static var disposeBag = DisposeBag()

    /// Observe the input source
    /// - Parameter inputObserver: Input Observer
    public static func setInputObserver(_ inputObserver: Observable<[AvatarTuple]>) {
        AvatarService.inputObserver = inputObserver
        AvatarService.disposeBag = DisposeBag()
        AvatarService.inputObserver?
            .subscribe(onNext: { (tuples) in
                for tuple in tuples {
                    if AvatarService.identifierCacheLRU.getValue(for: tuple.identifier) != nil {
                        AvatarService.identifierCacheLRU.setValue(tuple, for: tuple.identifier)
                        if let publishCache = AvatarService.publishCacheLRU.getValue(for: tuple.identifier) {
                            Self.logger.info("setInputObserver,\(tuple.medalKey)")
                            publishCache.publish.onNext(tuple)
                        }
                    }
                }
            }).disposed(by: AvatarService.disposeBag)
    }

    /// Register the callback corresponding to the identifier
    /// When the avatarkey is updated, call the callback corresponding to the identifier to update the avatar
    /// - Parameters:
    ///   - identifier: userID or chatID
    ///   - callback: Update avatar callback
    public static func getObserverByIdentifier(_ identifier: String) -> Observable<AvatarTuple> {
        if let publishCache = AvatarService.publishCacheLRU.getValue(for: identifier) {
            return publishCache.observer
        } else {
            let publish = PublishSubject<AvatarTuple>()
            let observer = publish.asObserver()
            AvatarService.publishCacheLRU.setValue(AvatarPublishTuple(publish: publish,
                                                                      observer: observer),
                                                   for: identifier)
            return observer
        }

    }

    /// Set or update avatarkey corresponding to identifier
    /// - Parameters:
    ///   - identifier: userID or chatID
    ///   - avatarKey: avatar key
    public static func setAvatarTupleByIdentifier(_ identifier: String, tuple: AvatarTuple) {
        if AvatarService.inputObserver != nil {
            if AvatarService.identifierCacheLRU.getValue(for: identifier) == nil {
                AvatarService.identifierCacheLRU.setValue(tuple, for: identifier)

                if let publishCache = AvatarService.publishCacheLRU.getValue(for: identifier) {
                    publishCache.publish.onNext(tuple)
                }
            }
        } else {
            if AvatarService.identifierCacheLRU.getValue(for: identifier) != tuple {
                AvatarService.identifierCacheLRU.setValue(tuple, for: identifier)
            }

            if let publishCache = AvatarService.publishCacheLRU.getValue(for: identifier) {
                publishCache.publish.onNext(tuple)
            }
        }
    }

    /// Reset identifierMap/callbacksMap/inputObserver
    public static func reset() {
        AvatarService.identifierCacheLRU.reset()
        AvatarService.publishCacheLRU.reset()
        AvatarService.disposeBag = DisposeBag()
        AvatarService.inputObserver = nil
    }
}
