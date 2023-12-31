//
//  CoreSceneMonitor.swift
//  LarkPreload
//
//  Created by huanglx on 2023/5/25.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging

///核心场景监听代理
protocol CoreSceneDelegate: AnyObject {
    /*
     监听核心场景状态变化
        -param: 是否是核心场景
     */
    func coreSceneDidChange(isCoreScene: Bool)
}

/*
    核心场景检测类，数值由外部注入
 */
public class CoreSceneMointor {
    
    //核心场景观察者
    private static var observes: SafeArray<CoreSceneDelegate> = [] + .readWriteLock
    
    private static var logger = Logger.log(CoreSceneMointor.self)
    
    //注册观察者
    static func registObserver(observe: CoreSceneDelegate) {
        self.observes.append(observe)
    }
    
    //feed是否滚动
    public static var feedIsScrolling: Bool = false {
        willSet {}
        didSet {
            self.callbackObserves()
        }
    }
    
    //是否正在打开会话
    public static var chatIsEnterIng: Bool = false {
        willSet {}
        didSet {
            self.callbackObserves()
        }
    }
    
    //是否在发消息-TODO
    public static var messageIsSendIng: Bool = false {
        willSet {}
        didSet {
            self.callbackObserves()
        }
    }
    
    //是否切换tab-TODO
    public static var tabIsSwitchIng: Bool = false {
        willSet {}
        didSet {
            self.callbackObserves()
        }
    }
    
    ///重置核心场景状态-添加核心场景监听一定要对应写上重置。
    static func resetCoreScene() {
        self.feedIsScrolling = false
        self.chatIsEnterIng = false
        self.messageIsSendIng = false
        self.tabIsSwitchIng = false
    }
    
    ///回调观察者
    private static func callbackObserves() {
        CoreSceneMointor.logger.info("preload_coreSceneDidChange_:\(self.isCoreScene)")
        self.observes.forEach { observe in
            observe.coreSceneDidChange(isCoreScene: self.isCoreScene)
        }
    }
    
    ///是否是核心场景
    static var isCoreScene: Bool {
        get {
            return self.feedIsScrolling || self.chatIsEnterIng || self.messageIsSendIng || self.tabIsSwitchIng
        }
    }
}
