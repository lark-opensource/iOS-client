//
//  RecommendedDataModel.swift
//  SKSpace
//
//  Created by yinyuan on 2023/4/11.
//

import SKFoundation
import SKCommon
import LarkSetting
import RxSwift
import SKInfra

public struct BannerMoreButton: SKFastDecodable {
    public var text: String?
    public var url: String?
    
    public static func deserialized(with dictionary: [String : Any]) -> BannerMoreButton {
        var model = BannerMoreButton()
        model.text <~ (dictionary, "text")
        model.url <~ (dictionary, "url")
        return model
    }
}

public struct BaseLandingPageBanner: SKFastDecodable {
    public var bannerTitle: String?
    public var cards: [BannerCard] = []
    public var moreBtn: BannerMoreButton?
    public var activityFetchInterval: Int64?    // 轮询间隔
    
    public static func deserialized(with dictionary: [String : Any]) -> BaseLandingPageBanner {
        var model = BaseLandingPageBanner()
        model.bannerTitle <~ (dictionary, "bannerTitle")
        model.cards <~ (dictionary, "cards")
        model.moreBtn <~ (dictionary, "moreBtn")
        return model
    }
}

public struct BannerCard: SKFastDecodable {
    public var title: String?
    public var cover: String?
    public var redirectUrl: String?
    
    public static func deserialized(with dictionary: [String : Any]) -> BannerCard {
        var model = BannerCard()
        model.title <~ (dictionary, "title")
        model.cover <~ (dictionary, "cover")
        model.redirectUrl <~ (dictionary, "redirectUrl")
        return model
    }
}

public final class RecommendedDataModel {
    private static let settingsKey = UserSettingKey.make(userKeyLiteral: "ccm_base_homepage")
    private let disposeBag = DisposeBag()
    
    var banner: BaseLandingPageBanner?
    
    var dataUpdatedCallback: ((_ banner: BaseLandingPageBanner?) -> Void)?
    var configReloadDelay: TimeInterval = 5 // 下次检查时间延迟
    
    public init() {
        update()
        // 监听变化
        SettingManager.shared.observe(key: Self.settingsKey)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] value in
                DocsLogger.info("receive ccm_base_homepage config update")
                self?.update(value: value)
            })
            .disposed(by: disposeBag)
    }
    
    public func update(value: [String: Any]? = nil) {
        var settings = value
        if settings == nil {
            do {
                settings = try SettingManager.shared.setting(with: Self.settingsKey)
            } catch {
                DocsLogger.error("ccm_base_homepage get settings error", error: error)
            }
        }
        if let settings = settings {
            banner = BaseLandingPageBanner.deserialized(with: settings)
            
            if value != nil {
                dataUpdatedCallback?(banner)
            }
        } else {
            DocsLogger.error("ccm_base_homepage get settings nil")
            // nolint: magic number
            if configReloadDelay < 1800 {
                DocsLogger.info("check ccm_base_homepage config after \(configReloadDelay)")
                DispatchQueue.main.asyncAfter(deadline: .now() + configReloadDelay) { [weak self] in
                    guard let self = self else {
                        return
                    }
                    // SettingManager.shared.observe 在无配置情况下会报 settingKeyNotFound 错误，并且后续再拉下数据也不会发送更新事件，一些极小概率情况下，可能会出现首次加载无配置（例如被放在了首tab，并且是首次加载），出现概率极低，但我们仍然进行一次兜底保护，避免出现持续的内容空白
                    DocsLogger.info("check ccm_base_homepage config")
                    self.update()
                }
                configReloadDelay = configReloadDelay * 2
            }
            // enable-lint: magic number
        }
    }
}
