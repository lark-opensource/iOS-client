//
//  UtilPeformanceService.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/11/28.
//

import SKFoundation
import SKCommon
import SKInfra

final class UtilPeformanceService: BaseJSService {
    
    enum MemoryLevel: String {
        case normal  //内存处于正常水位
        case warning //内存出现紧张
        case serious //内存非常紧张，随时有OOM白屏风险
    }
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        
        //监听内存水位，通知web降级
        //https://bytedance.larkoffice.com/wiki/wikcnBptylmllRsEZDSQ0WkzcFg
        //https://bytedance.larkoffice.com/wiki/Ph6Uwe7lqi7ktGkd5XZcgyzUnph
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryLevelNotification(_:)), name: NSNotification.Name(rawValue: "KHMDMemoryMonitorMemoryWarningNotificationName"), object: nil)
    }
    
    @objc
    private func didReceiveMemoryLevelNotification(_ notification: Notification) {
        let userInfo = notification.userInfo
        guard let flag = userInfo?["type"] as? Int32 else {
            return
        }
        // 通知Flag说明
        //  | 2 | 内存从高水位降到正常水位 |
        //  | 4 | 内存上升到高水位 |
        //  | 8 | 收到内存警告 |
        //  | 16 | 收到内存压力告警MemoryPressure2 |
        //  | 32 | 收到内存压力告警MemoryPressure4，随时有可能OOM |
        //  | 128 | 收到内存压力告警MemoryPressure16，随时有可能OOM |

        var level: MemoryLevel = .normal
        if flag > 2, flag < 16 {
            level = .warning
        } else if flag >= 16 {
            level = .serious
        } else {
            level = .normal
        }
        DocsLogger.info("receive MemoryLevel change: \(flag), level: \(level)")
        self.model?.jsEngine.callFunction(.memoryWarning, params: ["level": level.rawValue], completion: nil)
    }
}

extension UtilPeformanceService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return []
    }

    public func handle(params: [String: Any], serviceName: String) {

    }
}
