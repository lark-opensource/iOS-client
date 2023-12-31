//
//  ChatViewControllerHandler.swift
//  Lark
//
//  Created by zc09v on 2018/5/15.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import LarkModel
import LarkUIKit
import RxSwift
import Swinject
import EENavigator
import CoreLocation
import LKCommonsLogging
import UniverseDesignToast
import LarkReactionDetailController
import LarkEmotion
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkSendMessage
import LarkMessageCore
import LarkMessengerInterface
import LarkOpenFeed
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkRustClient
import LarkPrivacySetting
import RustPB
import LarkCoreLocation
import LarkSetting
import LarkSensitivityControl
import LKWindowManager
import LarkNavigator

final class ChatControllerByChatIdHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    static let logger = Logger.log(ChatControllerByChatIdHandler.self, category: "Module.ChatControllerHandler")
    private var preloadUpdatedChatIDsObserver: Observable<PushPreloadUpdatedChatIds> {
        return (try? resolver.userPushCenter.observable(for: PushPreloadUpdatedChatIds.self)) ?? .empty()
    }
    private let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: ChatControllerByIdBody, req: EENavigator.Request, res: Response) throws {
        Self.logger.info("ChatControllerByChatIdHandler begin subscribeReadyDriverIfNeeded chatId: \(body.chatId) fromWhere: \(body.fromWhere.rawValue)")
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        let chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        subscribeReadyDriverIfNeeded(body: body) { chatId in
            chatAPI.fetchChats(by: [chatId], forceRemote: false)
                .flatMap({ [unowned self] (chats) -> Observable<Chat> in
                    if let chat = chats[chatId] {
                        if chat.type == .p2P, chat.chatter == nil {
                            return chatterAPI.getChatter(id: chat.chatterId).map({ (chatter) -> Chat in
                                chat.chatter = chatter
                                return chat
                            })
                        }
                        return .just(chat)
                    } else {
                        return .empty()
                    }
                }).observeOn(MainScheduler.instance)
                .subscribe(onNext: { (chat) in
                    var newBody = ChatControllerByChatBody(
                        chat: chat,
                        position: body.position,
                        messageId: body.messageId,
                        fromWhere: body.fromWhere,
                        keyboardStartupState: body.keyboardStartupState,
                        showNormalBack: body.showNormalBack)
                    newBody.controllerService = body.controllerService
                    res.redirect(body: newBody)
                }, onError: { (error) in
                    res.end(error: error)
                    ChatControllerByChatIdHandler.logger.error("根据chatId跳转chat失败", additionalData: ["chatId": chatId], error: error)
                }).disposed(by: self.disposeBag)
            res.wait()
        }
    }

    private func subscribeReadyDriverIfNeeded(body: ChatControllerByIdBody, dataReady: @escaping (String) -> Void) {
        let chatID = body.chatId
        /// 特别说明：
        /// 当fromWhere == .push的时候，是点击通知跳转，这时候需要额外接入chat变化的通知。
        /// 如果不接可能进群后没能sync到最新数据而给用户丢消息的感觉。
        /// Notice:
        /// We need to use `preloadUpdatedChatIdsObserver` when `fromWhere == .push`.
        /// Because this observer will synchronize the latest messages for the user,
        /// otherwise, the user cannot see the latest message once jumping into the chat.
        if body.fromWhere != .push {
            return dataReady(chatID)
        }
        var token: NSObjectProtocol?

        let windowHitNotiObserver = Observable<Bool>.create { (observer) -> Disposable in
            token = NotificationCenter.default.addObserver(
                forName: LKWindow.didHitNotification,
                object: nil,
                queue: OperationQueue.main,
                using: { _ in
                    Self.logger.info("apns chatRoute windowHitNotiObserver \(chatID)")
                    token.flatMap { NotificationCenter.default.removeObserver($0) }
                    observer.onNext(false)
                    observer.onCompleted()
                }
            )
            return Disposables.create()
        }
        let chatReadyObserver: Observable<Bool> = preloadUpdatedChatIDsObserver
            .filter({ $0.ids.contains(chatID) }).map({ _ in
                Self.logger.info("apns chatRoute by pushPreloadUpdatedChatIds \(chatID)")
                token.flatMap { NotificationCenter.default.removeObserver($0) }
                return true
            })

        Self.logger.info("ChatControllerByChatIdHandler begin subscribe chatId: \(body.chatId) fromWhere: \(body.fromWhere.rawValue)")
        Observable.merge([windowHitNotiObserver, chatReadyObserver])
            .take(1).filter({ $0 }).observeOn(MainScheduler.instance).subscribe(onNext: { _ in
                dataReady(chatID)
            }).disposed(by: disposeBag)
    }
}

final class ChatControllerByBasicInfoBodyHandler: UserTypedRouterHandler, ChatControllerGenerator {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: ChatControllerByBasicInfoBody, req: EENavigator.Request, res: Response) throws {
        if body.chatMode == .threadV2 {
            let position: Int32?
            // 针对 thread body 兼容下position逻辑
            if let positionStrategy = body.positionStrategy, case .position(let p) = positionStrategy {
                position = p
            } else {
                position = nil
            }
            let byIDbody = ThreadChatByIDBody(chatID: body.chatId,
                                              position: position,
                                              fromWhere: body.fromWhere)
            res.redirect(body: byIDbody)
            return
        }
        let body = InnerChatControllerBody(source: .chatId(body.chatId, isCrypto: body.isCrypto, isMyAI: body.isMyAI),
                                           positionStrategy: body.positionStrategy,
                                           chatSyncStrategy: body.chatSyncStrategy,
                                           messageId: body.messageId,
                                           fromWhere: body.fromWhere,
                                           keyboardStartupState: body.keyboardStartupState,
                                           showNormalBack: body.showNormalBack,
                                           myAIChatModeConfig: body.myAIChatModeConfig,
                                           extraInfo: body.extraInfo)
        res.redirect(body: body)
    }
}

final class ChatControllerByUserIdHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    static let logger = Logger.log(ChatControllerByUserIdHandler.self, category: "Module.ChatControllerHandler")
    private let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: ChatControllerByChatterIdBody, req: EENavigator.Request, res: Response) throws {
        let chatService = try userResolver.resolve(assert: ChatService.self)
        let chatterId = body.chatterId
        let window = req.from.fromViewController?.view.window
        chatService.createP2PChat(userId: chatterId, isCrypto: body.isCrypto, isPrivateMode: body.isPrivateMode, chatSource: body.createChatSource)
            .observeOn(MainScheduler.instance)
            // SDK底层有一个>25s的超时限制，上层创群接口没有单独加超时；
            // 后端创单聊/群接口P99为2s，获取用户设备接口P99为11.65ms；
            // 密聊创单聊SDK内部会执行两个请求：获取对方设备 + 创群，所以这里超时时间设置为3s是合理的。
            .timeout(.seconds(3), scheduler: MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                let newBody = ChatControllerByChatBody(chat: chat,
                                                       position: body.position,
                                                       messageId: body.messageId,
                                                       fromWhere: body.fromWhere,
                                                       keyboardStartupState: body.keyboardStartupState,
                                                       showNormalBack: body.showNormalBack)
                /// selection jump to crypto chat from personal info card
                let context: [String: Any] = [
                    FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
                ]
                res.redirect(body: newBody, context: context)
            }, onError: { [weak window] (error) in
                res.end(error: error)
                if body.needShowErrorAlert, let window = window {
                    UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_LoadingFailed, on: window, error: error)
                }
                ChatControllerByUserIdHandler.logger.error("根据userId跳转chat失败", additionalData: ["chatterId": chatterId], error: error)
            }).disposed(by: self.disposeBag)
        res.wait()
    }
}

final class CustomServiceChatHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    static let logger = Logger.log(CustomServiceChatHandler.self, category: "Module.ChatControllerHandler")

    private let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: CustomServiceChatBody, req: EENavigator.Request, res: Response) throws {
        guard let from = req.context.from() else {
            assertionFailure()
            return
        }
        let chatService = try resolver.resolve(assert: ChatService.self)
        let sendMessageAPI = try resolver.resolve(assert: SendMessageAPI.self)

        let viewForShowingHUD = from.fromViewController?.viewIfLoaded

        let hud = viewForShowingHUD.map { UDToast.showLoading(on: $0, disableUserInteraction: true) }
        chatService.getCustomerServiceChat()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                hud?.remove()
                guard let chat = chat else {
                    CustomServiceChatHandler.logger.error("客服群获取失败")
                    return
                }
                if !body.plainMessage.isEmpty {
                    let content = RustPB.Basic_V1_RichText.text(body.plainMessage)
                    sendMessageAPI.sendText(context: nil, content: content, parentMessage: nil,
                                            chatId: chat.id, threadId: nil, stateHandler: nil)
                }
                let body = ChatControllerByChatBody(chat: chat)
                res.redirect(body: body)
            }, onError: { (error) in
                res.end(error: error)
                hud?.remove()
                CustomServiceChatHandler.logger.error("客服群获取失败", error: error)
            })
            .disposed(by: self.disposeBag)
        res.wait()
    }
}

final class OncallChatHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    static let logger = Logger.log(OncallChatHandler.self, category: "Module.ChatControllerHandler")

    private var currentChatterId: String { return userResolver.userID }
    private let disposeBag: DisposeBag = DisposeBag()

    private lazy var oncallChatManager: OncallChatManager? = {
        let request = SingleLocationRequest(desiredAccuracy: 80.0,
                                            desiredServiceType: .aMap,
                                                    timeout: 5,
                                                    cacheTimeout: 10)
        guard let locationTask = try? resolver.resolve(assert: SingleLocationTask.self, argument: request),
            let authorization = try? resolver.resolve(assert: LocationAuthorization.self)
        else { return nil }
        let callChatManager = OncallChatManager(userResolver: userResolver, locationTask: locationTask, authorization: authorization)
        return callChatManager
    }()

    func handle(_ body: OncallChatBody, req: EENavigator.Request, res: Response) throws {
        let id = body.id
        var isExecute = true

        var additionalData = AdditionalData()
        additionalData.extra = body.extra
        if let faqId = body.faqId {
            additionalData.faqIDStr = faqId
        }

        res.wait()

        if body.reportLocation && LarkLocationAuthority.checkAuthority() {
            let deniedCallBack = { [weak self] in
                guard let self = self else { return }
                self.putOncallChat(userId: self.currentChatterId, oncallId: id, additionalData: additionalData, req: req, res: res)
            }
            let okCallback = { [weak self] (location: AdditionalData.OneOf_Location) in
                guard let `self` = self, isExecute else { return }
                isExecute = false
                additionalData.location = location
                self.putOncallChat(userId: self.currentChatterId, oncallId: id, additionalData: additionalData, req: req, res: res)
            }
            oncallChatManager?.checkPermission(okCallback: okCallback, deniedCallBack: deniedCallBack)
        } else {
            self.putOncallChat(userId: self.currentChatterId, oncallId: id, additionalData: additionalData, req: req, res: res)
        }
    }

    private func putOncallChat(userId: String, oncallId: String, additionalData: AdditionalData?, req: EENavigator.Request, res: Response) {
        guard let from = req.context.from(),
            let oncallAPI = try? resolver.resolve(assert: OncallAPI.self),
            let chatAPI = try? resolver.resolve(assert: ChatAPI.self)
        else {
            res.end(error: UserScopeError.disposed)
            return
        }

        let viewForShowingHUD = from.fromViewController?.viewIfLoaded

        let hud = viewForShowingHUD.map { UDToast.showLoading(on: $0, disableUserInteraction: true) }
        oncallAPI
            .putOncallChat(userId: userId,
                           oncallId: oncallId,
                           additionalData: additionalData)
            .flatMap { (chatId) -> Observable<[String: LarkModel.Chat]> in
                OncallChatHandler.logger.debug("putOncallChat oncallId:\(String(describing: oncallId)) 成功")
                return chatAPI.fetchChats(by: [chatId], forceRemote: false)
            }
            .map({ (chatsMap) -> LarkModel.Chat? in
                let chat = chatsMap.first?.value
                OncallChatHandler.logger.debug("fetchChat oncallId:\(String(describing: oncallId)) chatId:\(chat?.id ?? "") 成功")
                return chat
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatModel) in
                if let chatModel = chatModel {
                    hud?.remove()
                    let body = ChatControllerByChatBody(chat: chatModel)
                    res.redirect(body: body)
                } else {
                    struct NoModel: Error {}
                    res.end(error: NoModel())
                }
            }, onError: { [weak viewForShowingHUD] (error) in
                if let apiError = error.underlyingError as? APIError, let window = viewForShowingHUD?.window {
                    hud?.showFailure(with: apiError.serverMessage, on: window, error: error)
                } else {
                    hud?.remove()
                }
                OncallChatHandler.logger.debug("fetchChat oncallId:\(String(describing: oncallId)) 失败: \(error.localizedDescription)")
                res.end(error: error)
            })
            .disposed(by: self.disposeBag)
    }
}

final class OncallChatManager: NSObject, CLLocationManagerDelegate {
    let userResolver: UserResolver
    let locationManager = CLLocationManager()
    private lazy var systemLocationFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: "messenger.location.force_original_system_location")
    }()
    /// 请求定位权限 PSDA管控Token
    private let locationAuthorizationToken: Token = Token("LARK-PSDA-SOS-requestLocationAuthorization", type: .location)
    /// 开始定位 PSDA管控Token
    private let startLocatingToken: Token = Token("LARK-PSDA-SOS-startUpdateLocation", type: .location)
    var okCallback: ((AdditionalData.OneOf_Location) -> Void)?
    var deniedCallBack: (() -> Void)?
    private let singleLocationTask: SingleLocationTask
    private let locationAuth: LocationAuthorization
    init(userResolver: UserResolver, locationTask: SingleLocationTask, authorization: LocationAuthorization) {
        self.userResolver = userResolver
        self.singleLocationTask = locationTask
        self.locationAuth = authorization
        super.init()

        if systemLocationFG {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = kCLLocationAccuracyKilometer
        }

        singleLocationTask.locationCompleteCallback = { [weak self] (task, result) in
            guard let `self` = self else { return }
            self.didUpdateCompleteLocations(task: task, result: result)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            OncallChatHandler.logger.info("UpdateLocation,UseSystemLocation Complete")
            var point = Coordinate()
            point.latitude = Float(currentLocation.coordinate.latitude)
            point.longitude = Float(currentLocation.coordinate.longitude)

            let location: AdditionalData.OneOf_Location = .point(point)
            let cb = self.okCallback
            cb?(location)
            self.okCallback = nil
            self.deniedCallBack = nil
            locationManager.stopUpdatingLocation()
        }
    }

    @available(iOS 14, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationManager(manager, didChangeAuthorization: manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied:
            let cb = self.deniedCallBack
            cb?()
            self.deniedCallBack = nil
            self.okCallback = nil
        case .authorizedAlways, .authorizedWhenInUse:
            self.deniedCallBack = nil
            if okCallback != nil {
                useSystemStartUpdatingLocation(manager: locationManager)
            }
        default: return
        }
    }

    func checkPermission(okCallback: ((AdditionalData.OneOf_Location) -> Void)?, deniedCallBack: (() -> Void)?) {
        self.okCallback = okCallback
        self.deniedCallBack = deniedCallBack

        func useSystemLocation() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                useSystemRequestLocationAuthorization(manager: locationManager)
            case .authorizedAlways, .authorizedWhenInUse:
                self.deniedCallBack = nil
                if okCallback != nil {
                    useSystemStartUpdatingLocation(manager: locationManager)
                }
            default:
                defaultAction()
            }
        }

        func useLocationModule() {
            switch locationAuth.authorizationStatus() {
            case .notDetermined:
                locationAuth.requestWhenInUseAuthorization(forToken: locationAuthorizationToken, complete: { [weak self] authorizationError in
                    guard let self = self else { return }
                    self.didChangeAuthorization(error: authorizationError)
                })
            case .authorizedAlways, .authorizedWhenInUse:
                self.deniedCallBack = nil
                if okCallback != nil {
                    startUpdatingLocation()
                }
            default:
                defaultAction()
            }
        }

        func defaultAction() {
            OncallChatHandler.logger.info("CheckPermission,DefaultAction")
            let cb = self.deniedCallBack
            cb?()
            self.deniedCallBack = nil
            self.okCallback = nil
        }

        if systemLocationFG {
            OncallChatHandler.logger.info("CheckPermission,UseSystemLocation")
            useSystemLocation()
        } else {
            OncallChatHandler.logger.info("CheckPermission,UseLocationModule")
            useLocationModule()
        }
    }

    private func useSystemRequestLocationAuthorization(manager: CLLocationManager) {
        do {
            try LocationEntry.requestWhenInUseAuthorization(forToken: locationAuthorizationToken, manager: manager)
        } catch let error {
            if let checkError = error as? CheckError {
                OncallChatHandler.logger.info("requestLocationAuthorization for locationEntry error \(checkError.description)")
            }
        }
    }

    private func useSystemStartUpdatingLocation(manager: CLLocationManager) {
        do {
            try LocationEntry.startUpdatingLocation(forToken: startLocatingToken, manager: manager)
        } catch let error {
            if let checkError = error as? CheckError {
                OncallChatHandler.logger.info("startUpdatingLocation for locationEntry error \(checkError.description)")
            }
        }
    }
    ///开始定位
    fileprivate func startUpdatingLocation() {
        do {
            //开启请求定位
            OncallChatHandler.logger.info("Start UseLocationModule")
            try singleLocationTask.resume(forToken: startLocatingToken)
        } catch {
            let msg = "SOS singleLocationTask taskID: \(singleLocationTask.taskID) resume failed, error is \(error)"
            OncallChatHandler.logger.info(msg)
        }
    }
}

extension OncallChatManager {
    public func didChangeAuthorization(error: LocationAuthorizationError?) {
        guard let error = error else {
            self.deniedCallBack = nil
            if okCallback != nil {
                startUpdatingLocation()
            }
            return
        }

        switch error {
        case .denied:
            let cb = self.deniedCallBack
            cb?()
            self.deniedCallBack = nil
            self.okCallback = nil
        case .notDetermined:
            // 延时0.1s 解决首次冷启动应用申请权限无法接收回调
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.locationAuth.requestWhenInUseAuthorization(forToken: self.locationAuthorizationToken, complete: { [weak self] authorizationError in
                    guard let self = self else { return }
                    self.didChangeAuthorization(error: authorizationError)
                })
            }
        default: break
        }
    }

    public func didUpdateCompleteLocations(task: SingleLocationTask, result: LocationTaskResult) {

        switch result {
        case .success(let location):
            OncallChatHandler.logger.info("UpdateCompleteLocation UseLocationModule")
            var point = Coordinate()
            point.latitude = Float(location.location.coordinate.latitude)
            point.longitude = Float(location.location.coordinate.longitude)

            let location: AdditionalData.OneOf_Location = .point(point)
            let cb = self.okCallback
            cb?(location)
            self.okCallback = nil
            self.deniedCallBack = nil
        case .failure(let error): break
        }
    }
}

final class ReactionDetailHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    typealias DetailMessage = LarkReactionDetailController.Message

    static let logger = Logger.log(ReactionDetailHandler.self, category: "Module.ReactionDetailHandler")

    private let disposeBag = DisposeBag()

    func handle(_ body: ReactionDetailBody, req: EENavigator.Request, res: Response) throws {
        let userResolver = self.userResolver
        let messageAPI = try resolver.resolve(assert: MessageAPI.self)
        let chatterAPI = try resolver.resolve(assert: ChatterAPI.self)

        let messageID = body.messageId
        messageAPI.fetchLocalMessage(id: messageID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (message) in
                let detailMessage = DetailMessage(id: messageID, channelID: message.channel.id)
                let dependency = ReactionDetailDependencyImpl(userResolver: userResolver, messageAPI: messageAPI, chatterAPI: chatterAPI)
                dependency.startReactionType = body.type
                let controller = ReactionDetailVCFactory.create(message: detailMessage, dependency: dependency)
                res.end(resource: controller)
            }, onError: { (error) in
                res.end(error: error)
            }).disposed(by: self.disposeBag)
        res.wait()
    }
}

/// 翻译效果
final class TranslateEffectHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: TranslateEffectBody, req: EENavigator.Request, res: Response) throws {
        guard userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteTranslation)) else {
            res.end(error: RouterError.notHandled)
            return
        }

        let me = userResolver.userID
        /// 跳转翻译效果界面
        let viewModel = TranslateEffectViewModel(
            userResolver: userResolver,
            chat: body.chat,
            message: body.message,
            configurationAPI: try resolver.resolve(assert: ConfigurationAPI.self),
            userGeneralSettings: try resolver.resolve(assert: UserGeneralSettings.self),
            checkIsMe: { id in me == id || body.chat.anonymousId == id }
        )
        let vc = TranslateEffectController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
