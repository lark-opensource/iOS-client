//
//  XYZDiversionHelper.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/10/29.
//

import Foundation
import SKFoundation
import SKCommon
import SKInfra

public enum TabLoadFrom: String {
    case cache
    case network
    case timeout
    case timeout_cache
}

final public class XYZDiversionHelper {
    public static func doXYZDiversion(with result: @escaping ((BitableTabSwitchView.Event, TabLoadFrom) -> Void)) {
        var excutedCallBack = false

        // 读取缓存
        let tabConfig = loadUserDiversion()
        if let tabConfig = tabConfig {
            // 判断缓存是否过期,有效期内使用缓存
            let curTimeStamp = Date().timeIntervalSince1970
            if curTimeStamp < tabConfig.expireTimeStamp {
                switch tabConfig.defaultSelect {
                case .my:
                    result(.baseHomeVC, .cache)
                case .recommend:
                    result(.recommendVC, .cache)
                }
                excutedCallBack = true
            }
        }

        if excutedCallBack == false {
            // 无缓存
            RecommendRequest.requestHomeDiversion { diversionResp, error in
                if let diversionResp = diversionResp, error == nil {
                    self.saveUserDiversion(diversionResp.tab)
                    if excutedCallBack == false {
                        switch diversionResp.tab.defaultSelect {
                        case .my:
                            result(.baseHomeVC, .network)
                        case .recommend:
                            result(.recommendVC, .network)
                        }
                        excutedCallBack = true
                    }
                } else {
                    if excutedCallBack == false {
                        result(.recommendVC, .network)
                        excutedCallBack = true
                    }
                    DocsLogger.info("Load diversion request failed")
                }
            }
            let interval = TimeInterval( Float(RecommendConfig.shared.homeDiversionTimout) / 1000.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                DocsLogger.info("Load tab by timeout")
                if excutedCallBack == false {
                    if let tabConfig = tabConfig {
                        switch tabConfig.defaultSelect {
                        case .my:
                            result(.baseHomeVC, .timeout_cache)
                        case .recommend:
                            result(.recommendVC, .timeout_cache)
                        }
                    } else {
                        result(.recommendVC, .timeout)
                    }
                    excutedCallBack = true
                }
            }
        }
    }
    
    public static func loadUserDiversion() -> DiversionTab? {
        guard let userId = User.current.info?.userID as? String, !userId.isEmpty else {
            return nil
        }

        if let tabConfig: DiversionTab = CCMKeyValue.userDefault(userId).value(forKey: UserDefaultKeys.baseRecommendCache) {
            return tabConfig
        }

        return nil
    }

    public static func saveUserDiversion(_ diversion: DiversionTab) {
        guard let userId = User.current.info?.userID as? String, !userId.isEmpty else {
            return
        }
        CCMKeyValue.userDefault(userId).set(diversion, forKey: UserDefaultKeys.baseRecommendCache)
    }
}
