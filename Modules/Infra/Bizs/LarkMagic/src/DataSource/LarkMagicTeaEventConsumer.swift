//
//  LarkMagicTeaEventConsumer.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/3.
//

import Foundation
import RxSwift
import LarkContainer
import LKCommonsTracker
import ADFeelGood

typealias Event = LKCommonsTracker.Event
typealias TeaEvent = LKCommonsTracker.TeaEvent

final class LarkMagicTeaEventConsumer: TrackerService, UserResolverWrapper {
    var serviceQueue: DispatchQueue = DispatchQueue(label: "lk.magic.service", qos: .default)
    @ScopedProvider private var magicService: LarkMagicService?
    private let config: LarkMagicConfig

    let userResolver: UserResolver
    init(config: LarkMagicConfig, userResolver: UserResolver) {
        self.config = config
        self.userResolver = userResolver
    }

    public func post(event: Event) {
        guard let teaEvent = event as? TeaEvent else {
            return
        }

        serviceQueue.async {
            let eventName = teaEvent.name
            guard self.config.whiteList.keys.contains(eventName),
                  let configParams = self.config.whiteList[eventName],
                  let uploadParams = self.filterUploadParams(configParams, teaEvent.params) else {
                return
            }
            DispatchQueue.main.async {
                self.magicService?.triggerEvent(eventName: eventName, extraParams: uploadParams)
            }
        }
    }

    private func filterUploadParams(_ configParams: EventParamsConfig, _ teaParams: [AnyHashable: Any]) -> [AnyHashable: Any]? {
        var isMatch = true
        var uploadParams: [AnyHashable: Any] = [:]
        configParams.forEach { (key, value) in
            if let teaParamsValue = teaParams[key],
               (value.isEmpty || value.contains("\(teaParamsValue)")) {
                uploadParams[key] = teaParamsValue
                return
            }
            isMatch = false
        }
        return isMatch ? uploadParams : nil
    }
}

final class LarkMagicConsumerManager {

    public var consumer: LarkMagicTeaEventConsumer?

    static var shared: LarkMagicConsumerManager = {
        let instance = LarkMagicConsumerManager()
        return instance
    }()

    /// construction calls with the `new` operator.
    private init() {}
}
