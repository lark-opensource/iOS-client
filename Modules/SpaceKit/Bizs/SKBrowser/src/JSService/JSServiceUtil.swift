//
//  JSServiceUtil.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/8.
//

import Foundation
import SKCommon
import SKFoundation
import SKInfra
import LarkSetting
import LarkContainer

public final class JSServiceUtil {
    
    public static func fixUnicodeCtrlCharacters(_ string: String, function: String) -> String {
        //服务端返回了特殊的unicode控制字符，如\u{e2}（很奇怪，p出来是\u{e2},但实际是\u{2029}）,需要过滤掉，否则传入js执行会出错。
        //测试文档https://bytedance.feishu.cn/docs/doccneaEmcIo5vjlksJe6N7Fm0c
        
        let evaluateJSOptEnable = config?.evaluateJSOptEnable ?? false
        if evaluateJSOptEnable == false { // 关闭时走旧逻辑
            return transformed(origin: string)
        } else {
            // 在名单中有匹配的function, 才替换
            let evaluateJSOptList = config?.evaluateJSOptList ?? []
            let hasMatchFunction = evaluateJSOptList.contains(where: { string in
                function.hasPrefix(string)
            })
            if hasMatchFunction == false {
                return string
            } else {
                return transformed(origin: string)
            }
        }
    }
}

extension JSServiceUtil {
    
    private static var config: PowerOptimizeConfigProvider? {
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let service = try? ur.resolve(assert: PowerOptimizeConfigProvider.self)
        return service
    }
    
    private static func transformed(origin: String) -> String {
        var res = origin.replacingOccurrences(of: "\u{2029}", with: "\\u{2029}")
        res = res.replacingOccurrences(of: "\u{2028}", with: "\\u{2028}")
        return res
    }
}
