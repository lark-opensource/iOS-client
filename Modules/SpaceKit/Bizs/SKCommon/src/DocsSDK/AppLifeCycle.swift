//
//  AppLifeCycle.swift
//  SpaceKit
//
//  Created by weidong fu on 2019/1/17.
//
import SKFoundation
import LarkRustHTTP
import SKInfra

public protocol LifeCycle: NSObjectProtocol {
    func appDidFinishLaunching(_ notify: NSNotification)
    func appDidBecomeActive(_ notify: NSNotification)
    func willEnterForeground(_ notify: NSNotification)
    func willResignActive(_ notify: NSNotification)
    func appDidEnterBackground(_ notify: NSNotification)
    func willTerminate(_ notify: NSNotification)
    func appDidReceiveMemoryWarning(_ notify: NSNotification)
    func significantTimeChange(_ notify: NSNotification)
    func userDidTakeScreenshot(_ notify: NSNotification)
}

extension LifeCycle {
    public func appDidFinishLaunching(_ notify: NSNotification) {}
    public func appDidBecomeActive(_ notify: NSNotification) {}
    public func willEnterForeground(_ notify: NSNotification) {}
    public func willResignActive(_ notify: NSNotification) {}
    public func appDidEnterBackground(_ notify: NSNotification) {}
    public func willTerminate(_ notify: NSNotification) {}
    public func appDidReceiveMemoryWarning(_ notify: NSNotification) {}
    public func significantTimeChange(_ notify: NSNotification) {}
    public func userDidTakeScreenshot(_ notify: NSNotification) {}
}

public final class AppLifeCycle: NSObject {
    let observers: ObserverContainer<LifeCycle> = ObserverContainer()
    var lifeCycleSels = [Selector]()

    override public init() {
        super.init()
        addLifeCycleNotification()
    }

    deinit {
        removeLifeCycleNotification()
    }

    public func add(lifeCycle: LifeCycle) {
        observers.add(lifeCycle)
    }

    private func addLifeCycleNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).appDidFinishLaunching(_:)), name: UIApplication.didFinishLaunchingNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).willEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).appDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).willResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).appDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).willTerminate(_:)), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).appDidReceiveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).significantTimeChange(_:)), name: UIApplication.significantTimeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).userDidTakeScreenshot(_:)), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }

    private func removeLifeCycleNotification() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didFinishLaunchingNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.significantTimeChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
}

extension AppLifeCycle: LifeCycle {
    @objc
    public func appDidFinishLaunching(_ notify: NSNotification) {
        DocsLogger.info("Lift Cycle", extraInfo: ["event": "\(#function)"], error: nil, component: nil)
        observers.all.forEach { (lc) in
            lc.appDidFinishLaunching(notify)
        }
    }

    @objc
    public func willEnterForeground(_ notify: NSNotification) {
        DocsLogger.info("Lift Cycle", extraInfo: ["event": "\(#function)"], error: nil, component: nil)
        observers.all.forEach { (lc) in
            lc.willEnterForeground(notify)
        }
    }

    @objc
    public func appDidBecomeActive(_ notify: NSNotification) {
        DocsLogger.info("Lift Cycle", extraInfo: ["event": "\(#function)"], error: nil, component: nil)
        let isUsingProxy = NetUtil.shared.isUsingProxyFor(OpenAPI.docs.baseUrl)
        if isUsingProxy {
            DocsTracker.shared.forbiddenTrackerReason.insert(.useSystemProxy)
        } else {
            DocsTracker.shared.forbiddenTrackerReason.remove(.useSystemProxy)
        }
        DocsLogger.info("isUsing proxy: \(isUsingProxy)")
        observers.all.forEach { (lc) in
            lc.appDidBecomeActive(notify)
        }
    }

    @objc
    public func willResignActive(_ notify: NSNotification) {
        DocsLogger.info("Lift Cycle", extraInfo: ["event": "\(#function)"], error: nil, component: nil)
        observers.all.forEach { (lc) in
            lc.willResignActive(notify)
        }
    }

    @objc
    public func appDidEnterBackground(_ notify: NSNotification) {
        DocsLogger.info("Lift Cycle", extraInfo: ["event": "\(#function)"], error: nil, component: nil)
        observers.all.forEach { (lc) in
            lc.appDidEnterBackground(notify)
        }
    }

    @objc
    public func  willTerminate(_ notify: NSNotification) {
        DocsLogger.info("Lift Cycle", extraInfo: ["event": "\(#function)"], error: nil, component: nil)
        observers.all.forEach { (lc) in
            lc.willTerminate(notify)
        }
    }

    @objc
    public func appDidReceiveMemoryWarning(_ notify: NSNotification) {
        DocsLogger.info("Lift Cycle", extraInfo: ["event": "\(#function)"], error: nil, component: nil)
        observers.all.forEach { (lc) in
            lc.appDidReceiveMemoryWarning(notify)
        }
    }

    @objc
    public func significantTimeChange(_ notify: NSNotification) {
        DocsLogger.info("Lift Cycle", extraInfo: ["event": "\(#function)"], error: nil, component: nil)
        observers.all.forEach { (lc) in
            lc.significantTimeChange(notify)
        }
    }

    @objc
    public func userDidTakeScreenshot(_ notify: NSNotification) {
        DocsLogger.info("Lift Cycle", extraInfo: ["event": "\(#function)"], error: nil, component: nil)
        observers.all.forEach { (lc) in
            lc.userDidTakeScreenshot(notify)
        }
    }
}
