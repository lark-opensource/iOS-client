//
//  GadgetLarkWebViewConfigHelper.swift
//  Timor
//
//  Created by 新竹路车神 on 2020/12/30 凌晨四点.
//

import LarkWebViewContainer

/// 获取LarkWebView init的config对象，使用Swift的原因是因为build方法带有默认参数，OC没法使用“默认参数”的便利
@objcMembers
public final class GadgetLarkWebViewConfigHelper: NSObject {
    /// 获取LarkWebView init的config对象
    /// - Parameter configuration: WKWebView原生config
    /// - Returns: LarkWebView init的config对象
    public class func getLarkWebViewConfig(with configuration: WKWebViewConfiguration, bizType: LarkWebViewBizType, advancedMonitorInfoEnable: Bool) -> LarkWebViewConfig {
        LarkWebViewConfigBuilder().setWebViewConfig(configuration).build(bizType: bizType, performanceTimingEnable: true, advancedMonitorInfoEnable: advancedMonitorInfoEnable)
    }
}
