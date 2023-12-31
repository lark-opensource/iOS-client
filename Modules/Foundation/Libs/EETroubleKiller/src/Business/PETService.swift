//
//  PETService.swift
//  EETroubleKiller
//
//  Created by Meng on 2019/5/13.
//

import Foundation
import LKCommonsLogging

public protocol PETService: AnyObject {
    func triggerRoute(target: Any, domainKey: [String: String])

    func triggerAppear(target: Any, domainKey: [String: String])

    func triggerToast(text: String, domainKey: [String: String])
}

final class PETServiceImpl: PETService {

    static let logger = Logger.log(PETServiceImpl.self, category: "TroubleKiller.PET")

    func triggerRoute(target: Any, domainKey: [String: String]) {
        assert(Thread.current.isMainThread)
        guard TroubleKiller.config.enable else { return }
        TroubleKiller.logger.debug("Begin PET route trigger.", tag: LogTag.log)

        var domainKey = domainKey
        let targetObject = ObjectItem(target)
        if !TroubleKiller.config.checkInRouterWhiteList(targetObject.name) {
            domainKey = [:]
        }
        let info = PInfo(source: nil, target: ObjectItem(target))
        let event = Event<PInfo>(topic: .route, domainKey: domainKey, info: info)
        guard let data = try? TroubleKiller.encoder.encode(event),
              let eventString = String(data: data, encoding: .utf8) else {
            TroubleKiller.logger.error("PET route info encode failed.", tag: LogTag.log)
            return
        }

        TroubleKiller.hook.beginPetHook?(.route)
        PETServiceImpl.logger.info(eventString, tag: LogTag.PET.p)
        TroubleKiller.hook.endPetHook?(.route)

        TroubleKiller.logger.debug("End PET route trigger.", tag: LogTag.log)
    }

    func triggerAppear(target: Any, domainKey: [String: String]) {
        assert(Thread.current.isMainThread)
        guard TroubleKiller.config.enable else { return }
        TroubleKiller.logger.debug("Begin PET appear trigger.", tag: LogTag.log)

        let info = PInfo(source: nil, target: ObjectItem(target))
        let event = Event<PInfo>(topic: .appear, domainKey: domainKey, info: info)
        guard let data = try? TroubleKiller.encoder.encode(event),
              let eventString = String(data: data, encoding: .utf8) else {
            TroubleKiller.logger.error("PET appear info encode failed.", tag: LogTag.log)
            return
        }

        TroubleKiller.hook.beginPetHook?(.appear)
        PETServiceImpl.logger.info(eventString, tag: LogTag.PET.p)
        TroubleKiller.hook.endPetHook?(.appear)

        TroubleKiller.logger.debug("End PET appear trigger.", tag: LogTag.log)
    }

    func triggerToast(text: String, domainKey: [String: String]) {
        assert(Thread.current.isMainThread)
        guard TroubleKiller.config.enable else { return }
        TroubleKiller.logger.debug("Begin PET toast trigger.", tag: LogTag.log)

        let info = TInfo(text: text)
        let event = Event<TInfo>(topic: .toast, domainKey: domainKey, info: info)
        guard let data = try? TroubleKiller.encoder.encode(event),
              let eventString = String(data: data, encoding: .utf8) else {
            TroubleKiller.logger.error("PET toast info encode failed.", tag: LogTag.log)
            return
        }

        TroubleKiller.hook.beginPetHook?(.toast)
        PETServiceImpl.logger.info(eventString, tag: LogTag.PET.t)
        TroubleKiller.hook.endPetHook?(.toast)

        TroubleKiller.logger.debug("End PET route trigger.", tag: LogTag.log)
    }
}
