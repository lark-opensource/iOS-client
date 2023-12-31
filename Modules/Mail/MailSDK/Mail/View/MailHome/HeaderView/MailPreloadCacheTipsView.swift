//
//  MailPreloadCacheTipsView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/4/13.
//

import Foundation
import UniverseDesignNotice
import UniverseDesignIcon
import RustPB

class MailPreloadCacheTipsView: UDNotice {

    var preloadProgress: MailPreloadProgressPushChange {
        didSet {
            updateConfigAndRefreshUI(makeUDConfig(preloadProgress))
        }
    }

    init(preloadProgress: MailPreloadProgressPushChange) {
        self.preloadProgress = preloadProgress
        super.init(config: UDNoticeUIConfig(type: .info, attributedText: NSAttributedString()))
    }

    func makeUDConfig(_ preloadProgress: MailPreloadProgressPushChange) -> UDNoticeUIConfig {
        guard preloadProgress.needPush == true else { // 静默拉取,直接展示完成状态
            var config = UDNoticeUIConfig(backgroundColor: UIColor.ud.functionSuccess100, attributedText: NSAttributedString(string: BundleI18n.MailSDK.Mail_EmailCache_cacheDone_Banner("\(preloadProgress.preloadTs.cacheCapacity())")))
            config.leadingIcon = UDIcon.succeedColorful
            config.trailingButtonIcon = UDIcon.closeOutlined
            return config
        }
    
        switch preloadProgress.status {
        case .preloadStatusUnspecified, .noTask:
            return UDNoticeUIConfig(type: .info, attributedText: NSAttributedString())
        case .preparing:
            return UDNoticeUIConfig(type: .info, attributedText: NSAttributedString(string: preloadProgress.status.title()))
        case .running:
            return UDNoticeUIConfig(type: .info, attributedText: NSAttributedString(string: preloadProgress.status.title(preloadProgress.progress)))
        case .stopped:
            if preloadProgress.progress == 100 && preloadProgress.errorCode == .pushErrorUnspecified { // 与rust的协议
                var config = UDNoticeUIConfig(backgroundColor: UIColor.ud.functionSuccess100, attributedText: NSAttributedString(string: BundleI18n.MailSDK.Mail_EmailCache_cacheDone_Banner("\(preloadProgress.preloadTs.cacheCapacity())")))
                config.leadingIcon = UDIcon.succeedColorful
                config.trailingButtonIcon = UDIcon.closeOutlined
                return config
            } else if preloadProgress.errorCode == .mobileTrafficSuspend {
                var warningConfig = UDNoticeUIConfig(type: .warning, attributedText: NSAttributedString(string: preloadProgress.errorCode.errorMsg()))
                warningConfig.leadingButtonText = BundleI18n.MailSDK.Mail_EmailCache_CachingInterupted_GoSetting_Button
                return warningConfig
            } else {
                var errorConfig = UDNoticeUIConfig(type: .error, attributedText: NSAttributedString(string: preloadProgress.errorCode.errorMsg()))
                if preloadProgress.errorCode == .diskFullError {
                    errorConfig.leadingButtonText = BundleI18n.MailSDK.Mail_EmailCache_NotEnoughSpace_adjust_Button
                }
                return errorConfig
            }
        @unknown default:
            fatalError()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Email_Client_V1_MailPreloadStatus {
    func title(_ percentage: Int64 = 0) -> String {
        switch self {
        case .preloadStatusUnspecified, .noTask, .stopped:
            return ""
        case .preparing:
            return BundleI18n.MailSDK.Mail_EmailCache_PrepareToCache_Banner
        case .running:
            return BundleI18n.MailSDK.Mail_EmailCache_Caching_Banner(percentage) + "%"
        @unknown default:
            fatalError()
        }
    }
}

extension Email_Client_V1_MailPreloadError {
    func errorMsg() -> String {
        switch self {
        case .diskFullError:
            return BundleI18n.MailSDK.Mail_EmailCache_NotEnoughSpace_Banner(BundleI18n.MailSDK.Mail_EmailCache_NotEnoughSpace_adjust_Button)
        case .networkError:
            return BundleI18n.MailSDK.Mail_EmailCache_NoInternet_Banner
        case .serverError:
            return BundleI18n.MailSDK.Mail_EmailCache_InternetError_Banner
        case .mobileTrafficSuspend:
            return BundleI18n.MailSDK.Mail_EmailCache_CachingInterupted_GoSetting_Toast
        case .externalAbort, .userAbort, .pushErrorUnspecified, .unknownError:
            return BundleI18n.MailSDK.Mail_EmailCache_CacheInterrupted_Banner
        @unknown default:
            fatalError()
        }
    }
}
