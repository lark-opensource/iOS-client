//
//  SCRealTimeSettingImp.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/7/26.
//

import Foundation
import RxSwift
import LarkContainer
import LarkSetting
import SwiftyJSON

struct SettingObserver {
    let key: SCSettingKey
    let callback: ((Any?) -> Void)?
}

class SCRealTimeSettingIMP: SCRealTimeSettingService {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "lark_security_compliance_config")
    private let disposeBag = DisposeBag()

    @SafeWrapper private var registedObservers = [String: SettingObserver]()
    @SafeWrapper var json: JSON {
        didSet {
            SCLogger.info("SCRealTimeSettings get new settings \(json.rawValue)")
        }
    }

    init(resolver: UserResolver) {
        do {
            let settingService = try resolver.resolve(assert: SettingService.self)
            let settings = try settingService.setting(with: Self.settingKey)
            self.json = JSON(rawValue: settings) ?? JSON()
            let rawObservable: Observable<[String: Any]> = settingService.observe(key: Self.settingKey)
            rawObservable.compactMap {
                JSON(rawValue: $0)
            }
            .observeOn(MainScheduler.instance)
            .filter { [weak self] in
                self?.json != $0
            }
            .subscribe(onNext: { [weak self] in
                self?.updateSettings($0)
            })
            .disposed(by: disposeBag)
        } catch {
            self.json = JSON()
            SCLogger.info("SCRealTimeSettings init failed")
            SCMonitor.error(business: .settings,
                            eventName: "init_fail",
                            error: error)
        }
    }

    func registObserver(key: SCSettingKey, callback: ((Any?) -> Void)?) -> String {
        let uuid = UUID().uuidString
        let observer = SettingObserver(key: key, callback: callback)
        registedObservers[uuid] = observer
        return uuid
    }

    func unregistObserver(identifier: String) {
        registedObservers.removeValue(forKey: identifier)
    }
}

extension SCRealTimeSettingIMP {
    private func updateSettings(_ settings: JSON) {
        notifyObserverIfNeed(settings: settings)
        json = settings
    }

    private func notifyObserverIfNeed(settings: JSON) {
        registedObservers.forEach { (_, observer) in
            let key = observer.key
            let lastValue = json[key.rawValue]
            let currentValue = settings[key.rawValue]
            if lastValue != currentValue {
                observer.callback?(currentValue.rawValue)
            }
        }
    }

}
