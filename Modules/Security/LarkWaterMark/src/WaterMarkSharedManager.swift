//
//  WaterMarkSharedManager.swift
//  LarkWaterMark
//
//  Created by ByteDance on 2022/11/20.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import Reachability
import LKCommonsLogging
import LarkFoundation
import RustPB
import LarkRustClient
import SnapKit
import LarkFeatureGating
import LarkDebugExtensionPoint
import Swinject
import LarkAccountInterface
import LarkUIKit
import LarkAssembler
import LarkSetting
import LarkContainer

extension WaterMarkSharedManager: WaterMarkManagerProtocol {}

private class WaterMarkDependency {
    var userService: PassportUserService?
    var client: RustService?
    var userStateDelegate: WaterMarkPassportDelegate?
}

final class WaterMarkSharedManager {

    typealias WaterMark = (view: WaterMarkView, observation: NSKeyValueObservation?, shouldAddWaterMark: Bool)

    static let logger = Logger.log(WaterMarkSharedManager.self, category: "WaterMark")
    static let monitor = WaterMarkMonitor()

    private var client: RustService?
    private var userStateDelegate: WaterMarkPassportDelegate?
    private var userId: String = ""
    private var datasource: WaterMarkDataSource?

    private let textColor = UIColor.ud.N500
    private let darkModeTextColor = UIColor.ud.textPlaceholder
    private var waterMarkStr: String = ""
    private var obviousWaterMarkPatternConfig = ObviousWaterMarkPatternConfig()
    private var defaultWaterMarkStr: String = ""
    private var waterMarkImageURL: String?
    private var fillColor: UIColor?
    private var shouldShow: Bool = false

    private let disposeBag = DisposeBag()
    private var waterMarkMap: [UIWindow: WaterMark] = [:]

    public var imageViewIsHidden: Bool = false {
        didSet {
            obviousWaterMarkShowSubject.onNext(!imageViewIsHidden)
        }
    }

    public var imageWaterMarkIsHidden: Bool = false {
        didSet {
            imageWaterMarkShowSubject.onNext(!imageWaterMarkIsHidden)
        }
    }

    private let reach = Reachability()

    private var waterMarkUpdatedSubject = ReplaySubject<Void>.create(bufferSize: 1)
    private var obviousWaterMarkShowSubject = ReplaySubject<Bool>.create(bufferSize: 1)
    private var imageWaterMarkShowSubject = ReplaySubject<Bool>.create(bufferSize: 1)
    private var isFirstViewSubject = BehaviorRelay<(UIWindow, Bool)>(value: (UIWindow(), false))

    private var updateUserSubject = PublishSubject<Void>()
    private var defaultWatermarkUpdatedSubject = ReplaySubject<Void>.create(bufferSize: 1)

    private lazy var queue: DispatchQueue = {
        return DispatchQueue(label: "waterMark", qos: .utility)
    }()
    private lazy var queueScheduler: SchedulerType = {
        return SerialDispatchQueueScheduler(
            queue: queue,
            internalSerialQueueName: queue.label)
    }()

    private var willConnectNotiObject: NSObjectProtocol?
    private var didDisconnectNotiObject: NSObjectProtocol?
    private var useCustomObviousWaterMark: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "admin.security.customwatermarksdk")
    }
    
    private var shouldManuallySendWaterMarkToTop: Bool {
        return !WaterMarkSwiftFGManager.isWatermarkWindowFGOn()
    }
    
    private var forceWaterMarkLayerOnTop: Bool {
        WaterMarkSwiftFGManager.isWatermarkHitTestFGOn()
    }
    
    private var useSharedManager: Bool {
        let useSharedManager = FeatureGatingManager.shared.featureGatingValue(with: "admin.security.watermark_shared_manager_enabled")
        Self.logger.info("WaterMarkSharedManager enabled:\(useSharedManager)")
        return useSharedManager
    }
    
    static let shared = WaterMarkSharedManager()
    
    private static let waterMarkDependency = WaterMarkDependency()

    private init() {
        if let userService = WaterMarkSharedManager.waterMarkDependency.userService {
            self.userId = userService.user.userID
            self.shouldShow = !userService.user.isGuestUser
        } else {
            Self.logger.error("WaterMarkSharedManager missing userService dependency on init")
        }
        
        if let client = WaterMarkSharedManager.waterMarkDependency.client {
            self.client = client
            self.datasource = WaterMarkNewDataSource(userID: userId, client: client)
        } else {
            Self.logger.error("WaterMarkSharedManager missing rustService dependency on init")
        }
        
        if let userStateDelegate = WaterMarkSharedManager.waterMarkDependency.userStateDelegate {
            self.userStateDelegate = userStateDelegate
        } else {
            Self.logger.error("WaterMarkSharedManager missing passportDelegate dependency on init")
        }
        
        let debugItem = WaterMarkDebugItem { [weak self] (isOn: Bool) in
            self?.imageViewIsHidden = !isOn
            self?.imageWaterMarkIsHidden = !isOn
        }
        DebugRegistry.registerDebugItem(debugItem, to: .debugTool)
        Self.monitor.monitorWaterMarkManagerOnInit(isSingleton: true)
        if shouldShow, useSharedManager {
            Self.logger.info("WaterMarkSharedManager init success with uid:\(self.userId), shouldShow:\(self.shouldShow)")
            self.updateUser()
            self.observeNetwork()
            self.observeWaterMarkShow()
            self.observeImageWaterMarkShow()
        }
    }
    
    class func setupWaterMarkDependency(client: RustService?, userService: PassportUserService?, userStateDelegate: WaterMarkPassportDelegate?) {
        WaterMarkSharedManager.waterMarkDependency.client = client
        WaterMarkSharedManager.waterMarkDependency.userService = userService
        WaterMarkSharedManager.waterMarkDependency.userStateDelegate = userStateDelegate
    }
    
    func updateDependency() {
        if let userService = WaterMarkSharedManager.waterMarkDependency.userService {
            self.userId = userService.user.userID
            self.shouldShow = !userService.user.isGuestUser
        } else {
            Self.logger.error("WaterMarkSharedManager missing userService dependency on update")
        }
        
        if let client = WaterMarkSharedManager.waterMarkDependency.client {
            self.client = client
            self.datasource = WaterMarkNewDataSource(userID: userId, client: client)
        } else {
            Self.logger.error("WaterMarkSharedManager missing rustService dependency on update")
        }
        
        if let userStateDelegate = WaterMarkSharedManager.waterMarkDependency.userStateDelegate {
            self.userStateDelegate = userStateDelegate
        } else {
            Self.logger.error("WaterMarkSharedManager missing passportDelegate dependency on update")
        }
        
        if shouldShow {
            Self.logger.error("WaterMarkSharedManager update dependency success with uid:\(self.userId), shouldShow:\(self.shouldShow)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.observeUpdateUsers()
                self.setupManager()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                Self.monitor.monitorWaterMarkStatusOnSetup(extra: ["userId": self.userId])
            }
        } else {
            Self.logger.info("WaterMarkSharedManager watermark not show since guest user")
        }
    }

    deinit {
        self.clearOnUserLogoff()
        Self.logger.info("WaterMarkSharedManager deinit")
    }
    
    private func setupManager() {
        doInMainThread {
            if #available(iOS 13.0, *) {
                self.setupWaterMarkWindowByConnectScene()
                self.observeSceneNotification()
            } else {
                self.setupWaterMarkWindow()
            }
            self.observeWaterMarkContentUpdate()
        }
        self.observeDataSourceSignals()
        self.observeUserStateDelegate()
    }

    /// setup watermark view before iOS 13
    private func setupWaterMarkWindow() {
        guard let delegate = UIApplication.shared.delegate,
            let weakWindow = delegate.window,
            let rootWindow = weakWindow else {
            return
        }
        self.updateWaterMark(on: rootWindow)
    }

    /// setup watermark view after iOS 13
    @available(iOS 13.0, *)
    private func setupWaterMarkWindowByConnectScene() {
        UIApplication.shared.connectedScenes.forEach { (scene) in
            guard let windowScene = scene as? UIWindowScene,
                let rootWindow = self.rootWindowForScene(scene: windowScene) else {
                return
            }
            self.updateWaterMark(on: rootWindow)
        }
    }

    /// find UIScene rootWindow
    @available(iOS 13.0, *)
    private func rootWindowForScene(scene: UIScene) -> UIWindow? {
        guard let scene = scene as? UIWindowScene else {
            Self.logger.error("WaterMarkSharedManager find scene rootWindow failed")
            return nil
        }
        if let delegate = scene.delegate as? UIWindowSceneDelegate,
            let rootWindow = delegate.window.flatMap({ $0 }) {
            Self.logger.info("WaterMarkSharedManager find scene rootWindow \(rootWindow)")
            return rootWindow
        }
        // swiftlint:disable:next all
        Self.logger.info("WaterMarkSharedManager find scene rootWindow \(String(describing: scene.windows.first))")
        return scene.windows.first
    }

    /// create watermark view
    /// - Parameter tintColor: view tint color
    /// - Returns: new WaterMarkView
    private func createWaterMarkImageView(text: String = "",
                                          tintColor: UIColor,
                                          frame: CGRect = .zero,
                                          useDefaultConfig: Bool = false,
                                          updateOnInit: Bool = false,
                                          obviousWaterMarkShow: Bool,
                                          imageWaterMarkShow: Bool) -> WaterMarkView {
        let obviousConfig = ObviousWaterMarkConfig(text: text.isEmpty ? waterMarkStr.isEmpty ? defaultWaterMarkStr : waterMarkStr : text, textColor: textColor)
        let imageWaterMarkConfig = ImageWaterMarkConfig(url: self.waterMarkImageURL)
        let imgView: WaterMarkView
        imgView = WaterMarkView(
            obviousWaterMarkConfig: obviousConfig,
            imageWaterMarkConfig: imageWaterMarkConfig,
            obviousWaterMarkPatternConfig: useDefaultConfig ? ObviousWaterMarkPatternConfig() : self.obviousWaterMarkPatternConfig,
            fillColor: self.fillColor,
            frame: frame,
            updateOnInit: updateOnInit,
            useCustomObviousWaterMark: self.useCustomObviousWaterMark)
        imgView.obviousWaterMarkShow = obviousWaterMarkShow
        imgView.imageWaterMarkShow = imageWaterMarkShow
        imgView.tintColor = tintColor
        // swiftlint:disable all
        let logStr = """
            WaterMarkView created with userID:\(self.userId)
            textlength:\(obviousConfig.text.count)
            obviousShow:\(obviousWaterMarkShow)
            hiddenShow:\(imageWaterMarkShow)
            updateOnInit:\(updateOnInit)
            width:\(frame.size.width)
            height:\(frame.size.height)
            useDefaultConfig:\(useDefaultConfig)
            urlLength:\(imageWaterMarkConfig.url?.count)
            """
        // swiftlint:disable all
        Self.logger.info(logStr)
        return imgView
    }

    /// setup window watermark view
    /// - Parameter window: target window
    private func updateWaterMark(on window: UIWindow) {
        let waterMark = self.createWaterMarkImageView(tintColor: self.darkModeTextColor,
                                                      obviousWaterMarkShow: !self.imageViewIsHidden,
                                                      imageWaterMarkShow: !self.imageWaterMarkIsHidden)
        let observation = window.observe(\.remoteViewCount,
                                         options: .new,
                                         changeHandler: { [weak self, weak waterMark, weak window] (object, change) in
                                            guard let window = window else {
                                                return
                                            }
                                            Self.logger.info("watermark window remote view count change \(window.remoteViewCount) \(window)")
                                            if self?.waterMarkMap[window]?.shouldAddWaterMark ?? false,
                                               let waterMark = waterMark,
                                               change.newValue == 0 {
                                                object.addSubview(waterMark)
                                                waterMark.snp.remakeConstraints { (make) in
                                                    make.edges.equalToSuperview()
                                                }
                                                self?.waterMarkMap[window]?.shouldAddWaterMark = false
                                            }})

        self.isFirstViewSubject.accept((window, self.datasource?.needShowObviousWaterMark() ?? false))
        waterMark.isFirstViewCallBack = { [weak self] (isFirst) in
            guard let self else { return }
            Self.logger.info("water mark isFirst \(isFirst)")
            self.isFirstViewSubject.accept((window, isFirst))
        }
        waterMark.obviousWaterMarkShow = !self.imageViewIsHidden
        waterMark.imageWaterMarkShow = !self.imageWaterMarkIsHidden

        var shouldAddWaterMark = false
        if window.remoteViewCount > 0 {
            shouldAddWaterMark = true
        }

        if let waterMarkView = self.waterMarkMap[window]?.view {
            if waterMarkView.superview != nil {
                waterMarkView.removeFromSuperview()
            }
        }
        
        if forceWaterMarkLayerOnTop {
            WaterMarkManager.logger.info("force set WaterMarkLayer zposition to greatest")
            waterMark.layer.zPosition = .greatestFiniteMagnitude
        }

        window.addSubview(waterMark)
        waterMark.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        /// 切到失效租户的时候，水印会被放在rootvc下面，但是不知道是哪个流程导致的，只能暂时使用这种方式解决
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            window.bringSubviewToFront(waterMark)
        }

        self.waterMarkMap[window]?.observation?.invalidate()

        self.waterMarkMap[window] = (waterMark, observation, shouldAddWaterMark)
        Self.logger.info("WaterMarkSharedManager add WaterMarkView to KeyWindow:\(window), mapCount:\(waterMarkMap.count)")
    }

    // main thread util function

    private func doInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}


// Mark: Reset UserState
extension WaterMarkSharedManager {
    private func clearOnUserLogoff() {
        let map = self.waterMarkMap
        Self.monitor.monitorWaterMarkRemoval(extra: [
            "userId": self.userId,
            "mapCount": map.count
        ])
        if !Thread.isMainThread {
            assertionFailure("release processs should be executed on main thread")
            DispatchQueue.main.async {
                for waterMark in map.values {
                    waterMark.view.removeFromSuperview()
                    waterMark.observation?.invalidate()
                }
            }
        } else {
            for waterMark in waterMarkMap.values {
                waterMark.view.removeFromSuperview()
                waterMark.observation?.invalidate()
            }
        }
        Self.logger.info("WatermarkView removed from window with userId: \(userId)")
        self.waterMarkMap = [:]
        self.datasource = nil
        self.client = nil
        self.userStateDelegate = nil
        Self.logger.info("clear WaterMarkSharedManager on logoff with userId: \(userId) shouldShow \(shouldShow)")
    }
}


// MARK: Observe
extension WaterMarkSharedManager {
    private func observeUserStateDelegate() {
        self.userStateDelegate?.userLoginSignal
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { state in
                Self.logger.info("WaterMarkSharedManager on user login with state \(state)")
        }).disposed(by: self.disposeBag)
        
        self.userStateDelegate?.userLogoutSignal
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                Self.logger.info("WaterMarkSharedManager on user logout with state \(state)")
                self?.clearOnUserLogoff()
        }).disposed(by: self.disposeBag)
    }
    
    /// observe network reachability to sent updateUserSubject signal
    private func observeNetwork() {
        reach?.whenReachable = { [weak self] _ in
            // 只有没有水印图片时，断网重连触发绘制
            // 否则弱网频繁绘制
            guard !(self?.waterMarkMap.isEmpty ?? true) else { return }
            self?.updateUser()
        }

        do {
            try reach?.startNotifier()
        } catch {
            WaterMarkManager.logger.error("StartNotifier error", error: error)
        }
    }

    /// observe updateUserSubject to update datasource
    private func observeUpdateUsers() {
        self.updateUserSubject
            .debounce(.milliseconds(300), scheduler: queueScheduler)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.datasource?.updateWatermarkInfo()
            }).disposed(by: disposeBag)
    }

    /// observe scene connect and disconnect
    @available(iOS 13.0, *)
    private func observeSceneNotification() {
        self.willConnectNotiObject = NotificationCenter.default.addObserver(
            forName: UIScene.willConnectNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                guard let `self` = self,
                    let scene = noti.object as? UIWindowScene,
                    let rootWindow = self.rootWindowForScene(scene: scene) else {
                    return
                }
                self.updateWaterMark(on: rootWindow)
                Self.logger.info("update water mark on scene connected, now mapCount:\(self.waterMarkMap.count)")
            }

        self.didDisconnectNotiObject = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                guard let scene = noti.object as? UIWindowScene,
                      let rootWindow = self?.rootWindowForScene(scene: scene) else {
                    return
                }
                self?.waterMarkMap[rootWindow] = nil
                Self.logger.info("remove water mark on scene disConnected, now mapCount:\(self?.waterMarkMap.count ?? 0)")
        }
    }

    /// observe waterMarkUpdateSubject to update watermark view
    private func observeWaterMarkContentUpdate() {
        self.waterMarkUpdatedSubject.asObserver()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let `self` = self, self.useSharedManager else { return }
                for window in self.waterMarkMap.keys {
                    if window.remoteViewCount > 0 {
                        continue
                    }
                    self.updateWaterMark(on: window)
                }
            }).disposed(by: self.disposeBag)
    }

    /// observe obvious watermark show enable
    private func observeWaterMarkShow () {
        self.obviousWaterMarkShowSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isShow) in
                guard let `self` = self else { return }
                for waterMark in self.waterMarkMap.values {
                    waterMark.view.obviousWaterMarkShow = isShow
                }
            }).disposed(by: self.disposeBag)
    }

    /// observe image watermark show enable
    private func observeImageWaterMarkShow () {
        self.imageWaterMarkShowSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isShow) in
                guard let `self` = self else { return }
                for waterMark in self.waterMarkMap.values {
                    waterMark.view.imageWaterMarkShow = isShow
                }
            }).disposed(by: self.disposeBag)
    }

    /// observe datasource signals
    private func observeDataSourceSignals() {
        self.datasource?.watermarkStrSignal
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (content) in
                guard let `self` = self else { return }
                self.waterMarkStr = content
                self.waterMarkUpdatedSubject.onNext(())
            }).disposed(by: self.disposeBag)
        
        self.datasource?.defaultWatermarkStrSignal
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (content) in
                guard let `self` = self else { return }
                self.defaultWaterMarkStr = content
                self.defaultWatermarkUpdatedSubject.onNext(())
            }).disposed(by: self.disposeBag)

        self.datasource?.watermarkURLSignal
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (content) in
                guard let `self` = self else { return }
                self.waterMarkImageURL = content
                self.waterMarkUpdatedSubject.onNext(())
            }).disposed(by: self.disposeBag)

        self.datasource?.obviousWatermarkEnableSignal
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (show) in
                guard let `self` = self else { return }
                self.imageViewIsHidden = !show
            }).disposed(by: self.disposeBag)

        self.datasource?.imageWatermarkEnableSignal
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (show) in
                guard let `self` = self else { return }
                self.imageWaterMarkIsHidden = !show
            }).disposed(by: self.disposeBag)
        
        self.datasource?.watermarkCustomPatternSignal
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (patternConfig) in
                guard let `self` = self else { return }
                self.obviousWaterMarkPatternConfig = patternConfig
                self.waterMarkUpdatedSubject.onNext(())
            }).disposed(by: self.disposeBag)
    }
}

// MARK: WaterMarkService
extension WaterMarkSharedManager: WaterMarkService {
    
    public func onWaterMarkViewCoveredWithContext(_ context: WaterMarkContext) {
        if shouldManuallySendWaterMarkToTop {
            doInMainThread {
                switch context {
                case .some(let window):
                guard let waterMark = window.subviews.first(where: { $0.isKind(of: WaterMarkView.self) }) as? WaterMarkView,
                   !window.subviews.contains(where: { $0.description.contains("_UIRemoteView") }) else { return }
                window.bringSubviewToFront(waterMark)
                waterMark.isFirstView = true
                }
            }
        }
    }

    public func updateUser() {
        Self.logger.info("WaterMarkSharedManager update user called")
        self.updateUserSubject.onNext(())
    }

    public func viewIsHidden(_ isHidden: Bool) {
        self.imageViewIsHidden = isHidden
    }

    public func getWaterMarkImageByChatId(_ chatId: String, fillColor: UIColor?) -> Observable<UIView?> {
        return self.fetchHasChatWaterMark(chatId)
            .observeOn(MainScheduler.instance)
            .flatMap({ [weak self] (hasWaterMark) -> Observable<UIView?> in
                guard let `self` = self, hasWaterMark else { return .just(nil) }
                return .just(self.createWaterMarkImageView(text: self.defaultWaterMarkStr,
                                                           tintColor: self.textColor,
                                                           obviousWaterMarkShow: true,
                                                           imageWaterMarkShow: true))
            })
    }

    public var globalWaterMarkIsShow: Observable<Bool> {
        return obviousWaterMarkShowSubject.asObservable()
    }

    public var imageWaterMarkIsShow: Observable<Bool> {
        return imageWaterMarkShowSubject.asObservable()
    }

    public var globalWaterMarkIsFirstView: Observable<(UIWindow, Bool)> {
        return isFirstViewSubject.asObservable()
    }

    public var globalWaterMarkView: Observable<UIView> {
        return waterMarkUpdatedSubject.asObservable().map { [weak self] _ in
            guard let `self` = self else { return UIView() }
            return self.createWaterMarkImageView(tintColor: self.textColor,
                                                 obviousWaterMarkShow: true,
                                                 imageWaterMarkShow: true)
        }
    }

    public var darkModeWaterMarkView: Observable<UIView> {
        return waterMarkUpdatedSubject.asObservable().map { [weak self] _ in
            guard let `self` = self else { return UIView() }
            return self.createWaterMarkImageView(tintColor: self.darkModeTextColor,
                                                 obviousWaterMarkShow: !self.imageViewIsHidden,
                                                 imageWaterMarkShow: !self.imageWaterMarkIsHidden)
        }
    }

    private func fetchHasChatWaterMark(_ chatId: String) -> Observable<Bool> {
        guard !chatId.isEmpty else {
            return Observable.just(false)
        }

        return self.obviousWaterMarkShowSubject
            .flatMap { [weak self ] (isShowGlobal) -> Observable<Bool> in
                guard let `self` = self,
                      !isShowGlobal else { return .just(false) }
                return self.fetchChatWaterMarkInfo(chatId)
            }
    }

    private func fetchChatWaterMarkInfo(_ chatId: String) -> Observable<Bool> {
        guard let client = self.client else {
            return Observable.just(false)
        }
        var request = RustPB.Im_V1_MGetChatsRequest()
        request.chatIds = [chatId]
        request.strategy = .forceServer
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_MGetChatsResponse) -> Bool in
            if let chat = res.entity.chats[chatId],
               chat.isCrossTenant,
               chat.hasWaterMark_p {
                return true
            } else {
                return false
            }
        }
    }

    private func vcWatermarkSubject() -> Observable<Bool> {
        return Observable.combineLatest(
            self.defaultWatermarkUpdatedSubject,
            self.waterMarkUpdatedSubject,
            self.obviousWaterMarkShowSubject) { (_, _, isShowGlobal) -> Bool in
                isShowGlobal
        }
    }

    public func getVCShareZoneWatermarkView() -> Observable<UIView?> {
        return vcWatermarkSubject()
            .observeOn(MainScheduler.instance)
            .flatMap({ [weak self] (isShowGlobal) -> Observable<UIView?> in
                guard let `self` = self, !isShowGlobal else { return .just(nil) }
                return .just(
                    self.createWaterMarkImageView(
                        text: self.defaultWaterMarkStr,
                        tintColor: self.textColor,
                        obviousWaterMarkShow: true,
                        imageWaterMarkShow: true
                    )
                )
            })
    }
}

// MARK: WaterMarkCustomService
extension WaterMarkSharedManager: WaterMarkCustomService {
    public var globalCustomWaterMarkView: Observable<UIView> {
        return waterMarkUpdatedSubject.asObservable().map { [weak self] _ in
            guard let `self` = self else { return UIView() }
            return self.createWaterMarkImageView(tintColor: self.darkModeTextColor,
                                                 obviousWaterMarkShow: !self.imageViewIsHidden,
                                                 imageWaterMarkShow: !self.imageWaterMarkIsHidden)
        }
    }
    
    public var defaultObviousWaterMarkView: Observable<UIView> {
        return waterMarkUpdatedSubject.asObservable().map { [weak self] _ in
            guard let `self` = self else { return UIView() }
            return self.createWaterMarkImageView(text: self.defaultWaterMarkStr,
                                                 tintColor: self.darkModeTextColor,
                                                 useDefaultConfig: true,
                                                 obviousWaterMarkShow: true,
                                                 imageWaterMarkShow: true)
        }
    }
    
    public var obvoiusWaterMarkConfig: [String: String] {
        return [
            "opacity": String(obviousWaterMarkPatternConfig.opacity),
            "dark_opacity": String(obviousWaterMarkPatternConfig.darkOpacity),
            "font_size": String(obviousWaterMarkPatternConfig.fontSize),
            "rotate_angle": String(obviousWaterMarkPatternConfig.rotateAngle),
            "density": String(obviousWaterMarkPatternConfig.density.rawValue),
            "content": !self.waterMarkStr.isEmpty ? self.waterMarkStr : self.defaultWaterMarkStr,
            "obvious_watermark_enabled": self.imageViewIsHidden ? "0" : "1"
        ]
    }
    
    public func observeGlobalWaterMarkViewWithFrame(_ frame: CGRect, forceShow: Bool) -> Observable<UIView> {
        return waterMarkUpdatedSubject.asObservable().map { [weak self] _ in
            guard let `self` = self else { return UIView() }
            return self.createWaterMarkImageView(tintColor: self.darkModeTextColor,
                                                 frame: frame,
                                                 obviousWaterMarkShow: forceShow ? true : !self.imageViewIsHidden,
                                                 imageWaterMarkShow: forceShow ? true : !self.imageWaterMarkIsHidden)
        }
    }
    
    public func getGlobalCustomWaterMarkViewWithFrame(_ frame: CGRect, forceShow: Bool) -> UIView {
        return self.createWaterMarkImageView(tintColor: self.darkModeTextColor,
                                             frame: frame,
                                             updateOnInit: true,
                                             obviousWaterMarkShow: forceShow ? true : !self.imageViewIsHidden,
                                             imageWaterMarkShow: forceShow ? true : !self.imageWaterMarkIsHidden)
    }
    
    public func getDefaultWaterMarkViewWithFrame(_ frame: CGRect) -> UIView {
        return self.createWaterMarkImageView(text: self.defaultWaterMarkStr,
                                             tintColor: self.darkModeTextColor,
                                             frame: frame,
                                             useDefaultConfig: true,
                                             updateOnInit: true,
                                             obviousWaterMarkShow: true,
                                             imageWaterMarkShow: true)
    }
}
