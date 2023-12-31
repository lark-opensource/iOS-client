//
//  ServiceProvider.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/11/1.
//

import Foundation
import LarkContainer

class ServiceProvider {
    let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    var configurationProvider: ConfigurationProxy? {
        try? resolver.resolve(assert: ConfigurationProxy.self)
    }

    var offlineResourceProvider: OfflinePackageProxy? {
        try? resolver.resolve(assert: OfflinePackageProxy.self)
    }

    var translateLanguageProvider: TranslateLanguageProxy? {
        try? resolver.resolve(assert: TranslateLanguageProxy.self)
    }

    var guideServiceProvider: GuideServiceProxy? {
        try? resolver.resolve(assert: GuideServiceProxy.self)
    }
    var myAIServiceProvider: MyAIServiceProxy? {
        try? resolver.resolve(assert: MyAIServiceProxy.self)
    }

    var contactPickerProvider: ContactPickerProxy? {
        try? resolver.resolve(assert: ContactPickerProxy.self)
    }

    var driveDownloader: DriveDownloadProxy? {
        try? resolver.resolve(assert: DriveDownloadProxy.self)
    }

    var attachmentUploader: AttachmentUploadProxy? {
        try? resolver.resolve(assert: AttachmentUploadProxy.self)
    }

    var attachmentPreview: AttachmentPreviewProxy? {
        try? resolver.resolve(assert: AttachmentPreviewProxy.self)
    }

    var routerProvider: RouterProxy? {
        try? resolver.resolve(assert: RouterProxy.self)
    }
    
    var calendarProvider: CalendarProxy? {
        try? resolver.resolve(assert: CalendarProxy.self)
    }

    var fileProvider: LocalFileProxy? {
        try? resolver.resolve(assert: LocalFileProxy.self)
    }

    var forwardProvider: MailForwardProxy? {
        try? resolver.resolve(assert: MailForwardProxy.self)
    }

    var qrCodeAnalysisProvider: QRCodeAnalysisProxy? {
        try? resolver.resolve(assert: QRCodeAnalysisProxy.self)
    }

    var featureSwitch: FeatureSwitchProxy? {
        try? resolver.resolve(assert: FeatureSwitchProxy.self)
    }

    var preloadManager: PreloadManagerProxy? {
        try? resolver.resolve(assert: PreloadManagerProxy.self)
    }

    var settingConfig: MailSettingConfigProxy? {
        try? resolver.resolve(assert: MailSettingConfigProxy.self)
    }
    
    var feedCard: FeedCardProxy? {
        try? resolver.resolve(assert: FeedCardProxy.self)
    }
}
