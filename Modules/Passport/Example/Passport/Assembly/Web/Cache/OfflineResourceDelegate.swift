//
//  OfflineResourceDelegate.swift
//  LarkApp
//
//  Created by Miaoqi Wang on 2019/12/4.
//

import Foundation
import Swinject
import RxSwift
import LarkAccountInterface
import OfflineResourceManager
import LarkFeatureGating
import LKCommonsLogging
import RustPB
import LarkRustClient

let dynamicUrlMapperKey = "dynamic_url_mapper"

public class OfflineResourceDelegate: LauncherDelegate {

    public var name: String = "OfflineResourceManager"
    private static let logger = Logger.log(OfflineResourceDelegate.self)
    fileprivate static let updateQueue = DispatchQueue(label: "com.lark.baseService.offlineResoureDelegate")

    private let resolver: Resolver
    private let disposeBag = DisposeBag()

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    func updateDevice() {
        // in case env change
        let domain = OfflineResourceApplicationDelegate.geckoDomain()
        OfflineResourceManager.setDomain(domain)

        let deviceService = resolver.resolve(DeviceService.self)!
        OfflineResourceManager.setDeviceId(deviceService.deviceId)
    }

    func updateSetting() {
        // update setting after login for this user
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = [dynamicUrlMapperKey]

        resolver.resolve(RustService.self)!
            .sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
                response.fieldGroups
            })
            .subscribeOn(scheduler)
            .subscribe(onNext: { (settingDic) in
                OfflineResourceDelegate.logger.debug("fetched dynamic settings")
                OfflineResourceDelegate.updateDynamicConfig(settings: settingDic)
            })
            .disposed(by: disposeBag)
    }

    public func afterSetAccount(_ account: Account) {
        updateDevice()
        updateSetting()
    }
}

extension OfflineResourceDelegate {

    class func updateDynamicConfig(settings: [String: String]) {
        updateQueue.async {
            // 更新动态化配置，先移除旧的配置
            OfflineResourceManager.removeBizConfigs(of: [.dynamic])

            guard let mapperInfo = settings[dynamicUrlMapperKey] else {
                OfflineResourceDelegate.logger.info("no mapper setting will not register biz")
                return
            }

            let json = try! JSONSerialization.jsonObject(
                with: mapperInfo.data(using: .utf8)!,
                options: .allowFragments
            ) as! [String: Any]

            let mappersJson = json[dynamicUrlMapperKey] as! [[String: Any]]

            var mappers: [DynamicUrlInfo] = []
            mappersJson.forEach { (mapper) in
                let urlInfoData = try! JSONSerialization.data(withJSONObject: mapper["url"] as! [String: Any], options: .fragmentsAllowed)
                let urlInfo = try! JSONDecoder().decode(DynamicUrlInfo.self, from: urlInfoData)
                mappers.append(urlInfo)
            }

            let bizConfigs = mappers.map({ (mapper) -> OfflineResourceBizConfig in
                let urlInfo = mapper
                return OfflineResourceBizConfig(
                    bizID: urlInfo.bizName,
                    bizKey: urlInfo.accessKey,
                    subBizKey: urlInfo.channel,
                    bizType: .dynamic
                )
            })

            OfflineResourceManager.registerBiz(configs: bizConfigs)
            bizConfigs.forEach { (cfg) in
                OfflineResourceManager.fetchResource(byId: cfg.bizID)
            }
        }
    }
}

struct DynamicUrlInfo: Codable {
    let bizName: String
    let accessKey: String
    let channel: String
}
