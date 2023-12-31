//
//  TuringService.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/9/21.
//

import UIKit
import BDTuring
import LarkReleaseConfig
import LarkLocalizations
import LKCommonsLogging
import Homeric
import LarkFoundation
import LarkAccountInterface
import LarkContainer
import LarkEnv

/// 图灵（滑块、图片）验证 https://bytedance.feishu.cn/docs/doccnEiACsgboFEgkmNzLuLY3re
class TuringService: NSObject {

    @Provider var deviceService: DeviceService
    @Provider var passportService: PassportService
    @Provider var envManager: EnvironmentInterface

    static let logger = Logger.plog(TuringService.self, category: "SuiteLogin.TuringService")
    static let shared = TuringService()
    private var isFeishuEnv: Bool {
        return passportService.isFeishuBrand
    }

    private lazy var turing: BDTuring = {
        let turing = BDTuring(config: self.turingConfig)
        turing.closeVerifyViewWhenTouchMask = false
        turing.setupProcessorForTTNetworkManager()
        updateConfig(env: envManager.env)
        return turing
    }()

    override init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateLanguage),
            name: .preferLanguageChange,
            object: nil
        )

        /// UI样式调整 https://bytedance.feishu.cn/sheets/shtcnUx8QtrXBV65faLvf1t0Qo8
        BDTuring.setVerifyTheme([
            "feedbackBtnBgColor": "#3370FF",
            "feedbackOnSelectedIconColor": "#3370FF",
            "feedbackBtnBgOpacity": "0.34",
            "slidingSlotBgColor": "rgb(186, 206, 253)"
        ])
    }
    
    /// 设置域名配置
    func updateConfig(env: Env) {
        Self.logger.info("Turing service setup config with env: \(env)")

        // 登录前登录后都使用包域名
        let enableTuringUsePkgDomain = PassportStore.shared.configInfo?.config().getTuringUsePkgDomain() ?? V3NormalConfig.defaultTuringUsePkgDomain
        let dominKey = enableTuringUsePkgDomain ? DomainAliasKey.passportTuringUsingPackageDomain : DomainAliasKey.passportTuring
        if let domain = PassportConf.shared.serverInfoProvider.getDomain(dominKey).value {
            Self.logger.error("Turing service set domain: \(domain) for env: \(env)")

            let regions: [String] = ["cn", "va", "sg", "in"]
            for region in regions {
                BDTuringSettingsHelper.sharedInstance()
                    .updateSettingCustomBlock(kBDTuringSettingsPluginPicture,
                                              key1: kBDTuringSettingsHost,
                                              value: domain,
                                              forAppId: ReleaseConfig.appId,
                                              inRegion: region)
            }
        } else {
            Self.logger.error("Turing service failed to get domain for env: \(env)")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private lazy var turingConfig: BDTuringConfig = {
        let config = BDTuringConfig()
        config.appID = ReleaseConfig.appId
        config.appName = Utils.appName
        config.channel = ReleaseConfig.channelName
        config.delegate = self
        config.language = LanguageManager.currentLanguage.languageCode ?? "en"
        
        /// BDTuringSDK 在滑块验证场景会从下发的 decision 中获取 geo 信息，已经不依赖 regionType，这里设置一个兜底值
        config.regionType = isFeishuEnv ? .CN : .VA
        return config
    }()

    @objc
    private func updateLanguage(_ noti: Notification) {
        turingConfig.language = LanguageManager.currentLanguage.languageCode ?? "en"
    }
}

extension TuringService {
    
    func verify(modelParams: [AnyHashable : Any], completion: @escaping (Bool) -> Void) {
        let isFeishu = isFeishuEnv
        Self.logger.info("start turing verify env is Feishu \(isFeishu)")
        let model = BDTuringVerifyModel.parameterModel(withParameter: modelParams)
        model.callback = { result in
            let resultString: String
            switch result.status {
            case .statusOK:
                resultString = "succ"
            case .statusClose:
                resultString = "cancel"
            default:
                resultString = "fail"
            }
            SuiteLoginTracker.track(Homeric.TURING_VERIFY_RESULT, params: [TrackConst.resultValue: resultString])
            Self.logger.info("turing verify result status \(result.status.rawValue) token len: \(result.token?.count ?? 0) mobile len: \(result.mobile?.count ?? 0)")
            completion(result.status == .statusOK)
        }
        SuiteLoginTracker.track(Homeric.PASSPORT_TURING_SHOW)
        turing.popVerifyView(with: model)
    }
}

extension TuringService: BDTuringConfigDelegate {
    func deviceID() -> String { deviceService.deviceId }
    func installID() -> String { deviceService.installId }
    func sessionID() -> String? { nil }
    func userID() -> String? { nil }
    func secUserID() -> String? { nil }
}

extension TuringService: BDTuringDelegate {
    func verifyWebViewDidLoadFail(_ turing: BDTuring) {
        Self.logger.error("turing verify load fail")
    }
}
