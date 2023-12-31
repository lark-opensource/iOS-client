//
//  CalendarDemoAssembly.swift
//  CalendarDemo
//
//  Created by zhuheng on 2021/3/2.
//

import Swinject
import LarkContainer
import AnimatedTabBar
import EENavigator
import LarkTab
import LarkNavigation
import LarkUIKit
import FLEX
import BootManager
import LarkDebug
import LarkWebViewContainer
import ECOInfra

final class LarkWebViewProtocolImpl: LarkWebViewProtocol {
    func ajaxFetchHookString() -> String? {
        return nil
    }

    func featureGeting(for key: String) -> Bool {
        return true
    }
    public func setupAjaxFetchHook(webView: LarkWebView) {
    }
    public func networkClient() -> ECONetworkClientProtocol {
        Injected<ECONetworkClientProtocol>(name: ECONetworkChannel.rust.rawValue, arguments: OperationQueue(), DefaultRequestSetting).wrappedValue
    }
}

final class CalendarDemoTab: TabRepresentable {
    var tab: Tab { return CalendarDemoTab.mockTab }

    static var mockTab: Tab {
        #if canImport(MessengerMod)
        return Tab.todo
        #else
        return Tab.feed
        #endif
    }
}
