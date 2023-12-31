//
//  AppContext.swift
//  Docs
//
//  Created by weidong fu on 3/12/2017.
//  Copyright © 2017 weidong fu. All rights reserved.
//

import Foundation
import SpaceKit
import CreationLogger
import EENavigator
import SKCommon
import SKUIKit

class AppContext: DocsSDKMediatorContext {
    weak var eventsHandler: AppContextEventHandler?
    var userCenter: UserCenter!
    var navigator: DocsNavigator!
    var vcFactory: VCFactory!
    var sdkMediator: DocsSDKMediator!
    var debugger: Debugger?
    var statistics: Statistics!
    var loggerModule: DocsLoggerModule!
    
    init() {
        self.userCenter = UserCenter()
    }

    func setup(with eventHandler: AppContextEventHandler) {
        self.eventsHandler = eventHandler
        Date.docs.cal(execTimeWith: {
            // MARK: 这几行代码 DocsAPMModule 和 DocsLoggerModule 前尽量不要加任何代码，如有需求请告知 --xurunkang
            #if !DEBUG
            DocsAPMModule.shared.startMonitoring()
            #endif

            loggerModule = DocsLoggerModule()
            loggerModule.startRecording()

            #if DEBUG || BETA
                debugger = Debugger()
            #endif
            guard let eventsHandler = self.eventsHandler else { fatalError("Must provide events handler") }

            sdkMediator = DocsSDKMediator(defaultDocsConfig(), context: self, delegate: eventsHandler)
            
            #if DEBUG || BETA
            sdkMediator.fgDelegate = debugger
            #endif

            userCenter.addObserver(self.sdkMediator)
            userCenter.addObserver(eventsHandler)

            vcFactory = VCFactory(context: VCFactoryCtxAppContextAdaptor(self))

            navigator = DocsNavigator()

            statistics = Statistics(userCenter)

        }, finish: { (cost) in
            CTLogger.default.info("AppContext launching time: \(cost) 秒")
        })
    }

    fileprivate func defaultDocsConfig() -> DocsConfig {
        let channels = [(GeckoChannleType.webInfo, GeckoPackageAppChannel.docs_channel.rawValue, "SKResource.framework/SKResource.bundle/eesz-zip", "eesz.zip")]
        let geckoConfig = GeckoInitConfig(channels: channels, deviceId: AppUtil.shared.deviceID, setUp: false)
        var docsConfig = DocsConfig(geckoConfig: geckoConfig)
        // ui的配置 https://docs.bytedance.net/doc/7jfmZdvpvaQPRVJtzhVKsb
        docsConfig.navigationConfig = {
            var config = SKNavigationBarConfig()
            config.largeHeight = 60
            config.buttonSize = 32
            config.edgeCenterDistance = 26
            config.isDocsApp = true
            return config
        }()
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String {
            docsConfig.infos[appName] = version
        }
        return docsConfig
    }
}
