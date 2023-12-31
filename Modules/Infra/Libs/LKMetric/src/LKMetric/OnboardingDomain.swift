//
//  OnboardingDomain.swift
//  LKMetric
//
//  Created by Meng on 2020/1/7.
//

import Foundation

// MARK: - Onboarding Level 2
public enum Onboarding: Int32, MetricDomainEnum {
    case unknown = 0
    case video = 1
    case tour = 2
    case dynamic = 3
}

// MARK: - Onboarding Level 3
public enum OnboardingVideo: Int32, MetricDomainEnum {
    case unknown = 0
    /// 加载
    case load = 1
    /// 播放
    case play = 2
    /// 封面
    case cover = 3
}

public enum Tour: Int32, MetricDomainEnum {
    case unknown = 0
    /// 编辑团队名称
    case editTeam = 1
    /// 可信邮箱
    case trustMail = 2
    /// 拉取onboarding接口失败
    case pullStatusFail = 3
    /// 拉取onboarding接口成功
    case pullStatusSuccess = 4
    /// 上报onboarding状态失败
    case putStatusFail = 5
    /// 上报onboarding状态成功
    case putStatusSucces = 6
    /// 拉取破冰接口耗时
    case pullStatusTime = 7
    /// 上报破冰状态耗时
    case putStatusTime = 8
    /// 安卓专用
    case spotlightMoreBtnNotAttachedAndroid = 9
    /// 拉取spotlight引导状态失败
    case pullProductGuideFail = 10
    /// 拉取spotlight引导状态成功
    case pullProductGuideSuccess = 11
    /// 拉取spotlight引导状态耗时
    case pullProductGuideTime = 12
}

public enum DynamicResource: Int32, MetricDomainEnum {
    case unknown = 0
    /// 使用spotlight下发引导数据
    case spotlightDataDynamic = 1
    /// 使用video下发引导数据
    case videoDataDynamic = 2
    /// 使用spotlight兜底引导数据
    case spotlightDataFallback = 3
    /// 使用video兜底引导数据
    case videoDataFallback = 4
}

// MARK: - Onboarding Level 3
public enum VideoLoad: Int32, MetricDomainEnum {
    case unknown = 0
    /// 视频首次加载完成
    case readyToPlay = 1
    /// 视频地址错误(url 为空 or 格式错误)
    case invalidURL = 2
    /// 视频加载网络错误
    case loadNetworkError = 3
    /// 播放器解码错误
    case parseError = 4
    /// 其他错误
    case loadOtherError = 5
}

public enum VideoPlay: Int32, MetricDomainEnum {
    case unknown = 0
    /// 视频播放完成
    case finish = 1
    /// 视频播放网络错误
    case networkError = 2
    /// 视频播放其他错误
    case otherError = 3
    /// 退出视频页面
    case quit = 4
}

public enum VideoCover: Int32, MetricDomainEnum {
    case unknown = 0
    /// 视频封面为空
    case empty = 1
    /// 视频封面加载失败
    case loadFail = 2
    /// 视频封面加载成功
    case loadSuccess = 3
}

public enum TourEditTeam: Int32, MetricDomainEnum {
    case unknown = 0
    /// 设置团队名称成功
    case putNameSuccess = 1
    /// 设置团队名称业务失败
    case putNameFail = 2
    /// 接口失败
    case putNameAPIFail = 3
    /// 设置团队名称耗时
    case putNameTime = 4
}

public enum TourTrustMail: Int32, MetricDomainEnum {
    case unknown = 0
    /// 设置可信邮箱成功
    case setTrustMailSuccess = 1
    /// 设置可信邮箱失败
    case setTrustMailFailed = 2
    /// 设置可信邮箱耗时
    case setTrustMailTime = 3
    /// 拉取可信邮箱成功
    case pullTrustMailSuccess = 4
    /// 拉取可信邮箱失败
    case pullTrustMailFailed = 5
}
