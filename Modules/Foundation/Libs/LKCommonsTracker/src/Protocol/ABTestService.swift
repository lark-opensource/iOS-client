//
//  ABTestService.swift
//  LKCommonsTracker
//
//  Created by shizhengyu on 2019/11/18.
//

import Foundation

/// 外部 AB 实验协议(目前 Lark 只使用到了通用参数的能力)
public protocol ExternalABTestService {
    var abVersions: String { get }

    var allAbVersions: String { get }
    
    var allABTestConfigs: [AnyHashable: Any] { get }
    
    func addPullABTestConfigObserve(observer: Any, selector: Selector)

    func abTestValue(key: String, defaultValue: Any) -> Any?

    func setABSDKVersions(versions: String?)

    func commonABExpParams(appId: String) -> [AnyHashable: Any]
}

/// 内部 AB 实验协议(目前 Lark 使用的是内部的 AB 实验)
public protocol InternalABTestService {
    var exposuredExperiments: String? { get }
    
    func registerABExposureExperimentsObserve(observer: Any, selector: Selector)

    func registerFetchExperimentDataObserver(observer: Any, selector: Selector)

    func experimentValue(key: String, shouldExposure: Bool) -> Any?

    func fetchAndSaveExperimentData(url: String, completionCallBack: @escaping (Error?, [AnyHashable: Any]?) -> Void)
}
