//
//  LKTracker+ABTest.swift
//  LKCommonsTracker
//
//  Created by shizhengyu on 2019/11/18.
//

import Foundation

public typealias ABTestService = ExternalABTestService & InternalABTestService

/// https://bytedance.feishu.cn/space/doc/lzMidtVI4LG61sWxbvjYIh#
public extension Tracker {
    /// 外部 AB 实验协议(目前 Lark 只使用到了 `commonABExpParams` 的能力)
    
    class var aBTestTracker: ABTestService? {
        (self.tracker(key: .tea) as? TrackServiceWrapper)?
            .services
            .compactMap { $0 as? ABTestService }
            .first
    }
    
    class var abVersions: String { aBTestTracker?.abVersions ?? "" }

    class var allAbVersions: String { aBTestTracker?.allAbVersions ?? "" }
    
    class var allABTestConfigs: [AnyHashable: Any] { aBTestTracker?.allABTestConfigs ?? [:] }
    
    class var queryExposureExperiments: String? { aBTestTracker?.exposuredExperiments }
    
    class func addPullABTestConfigObserve(observer: Any, selector: Selector) {
        self.aBTestTracker?.addPullABTestConfigObserve(observer: observer, selector: selector)
    }

    class func abTestValue(key: String, defaultValue: Any) -> Any? { aBTestTracker?.abTestValue(key: key, defaultValue: defaultValue) ?? defaultValue }

    class func setABSDKVersions(versions: String?) { aBTestTracker?.setABSDKVersions(versions: versions) }

    class func commonABExpParams(appId: String) -> [AnyHashable: Any] { aBTestTracker?.commonABExpParams(appId: appId) ?? [:] }

    /// 内部 AB 实验协议(目前 Lark 使用的是内部的 AB 实验)
    class func registerABExposureExperimentsObserve(observer: Any, selector: Selector) {
        aBTestTracker?.registerABExposureExperimentsObserve(observer: observer, selector: selector)
    }

    class func registerFetchExperimentDataObserver(observer: Any, selector: Selector) {
        aBTestTracker?.registerFetchExperimentDataObserver(observer: observer, selector: selector)
    }

    class func experimentValue(key: String, shouldExposure: Bool) -> Any? {
        aBTestTracker?.experimentValue(key: key, shouldExposure: shouldExposure)
    }

    class func fetchAndSaveExperimentData(url: String,
                                          completionCallBack: @escaping (Error?, [AnyHashable: Any]?) -> Void) {
        aBTestTracker?.fetchAndSaveExperimentData(url: url, completionCallBack: completionCallBack)
    }
}
