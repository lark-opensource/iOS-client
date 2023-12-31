//
//  LarkBoxSettingAssembly.swift
//  LarkBoxSettingAssembly
//
//  Created by Aslan on 2021/4/1.
//

import Foundation
import BootManager
import LKCommonsLogging
import RustPB
import RxSwift
import LarkRustClient
import LarkBoxSetting
import LarkContainer
import LarkReleaseConfig

private enum RequestParams {
    /// 从v7.8.0开始 https://cloud.bytedance.net/appSettings-v2/detail/config/188677/detail/status
    static let saasField = "box_setting_saas"
    /// https://cloud.bytedance.net/appSettings-v2/detail/config/172043/detail/status
    static let kaField = "box_setting"
}

final class LarkBoxSettingTask: FlowBootTask, Identifiable { //Global
    static var identify = "LarkBoxSettingTask"

    static let logger = Logger.log(LarkBoxSettingTask.self, category: "Module.LarkBoxSettingAssembly")

    // 索引文件的初始化需要确保在UI初始化之前，所以这里使用同步，资源下载会切换到异步线程
    override var scheduler: Scheduler { return .async }
    
    override var runOnlyOnceInUserScope: Bool { return false }

    private let disposeBag = DisposeBag()

    override func execute(_ context: BootContext) {
        Self.logger.info("boxsetting: new excute process")
        let globalService = Container.shared.resolve(GlobalRustService.self)
        let field = self.isSaas(ReleaseConfig.releaseChannel) ? RequestParams.saasField : RequestParams.kaField 
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = [field]
        request.syncDataStrategy = .forceServer
        globalService?.sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        })
        .subscribe(onNext: { (settingDic) in
            guard let infoDict = settingDic[field] else { return }
            Self.logger.info("fetch remote setting dict: \(infoDict)")
            guard let data = infoDict.data(using: .utf8) else { return }
            if let config = try? JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any],
               let isOn = config["result"] as? Bool {
                Self.logger.info("setting box result is \(isOn)")
                BoxSettingStore().save(config: isOn)
            } else {
                Self.logger.info("setting box decode failed")
            }
        }, onError: { error in
            Self.logger.error("request error: \(error)")
        })
        .disposed(by: self.disposeBag)
    }

    func isSaas(_ channel: String) -> Bool {
        /// 对应 @wangbohong 团队维护的发版channel
        return ["Release", "Oversea", "fssw", "gwfssw"].contains(channel)
    }

    deinit {
        Self.logger.info("deinit")
    }
}
