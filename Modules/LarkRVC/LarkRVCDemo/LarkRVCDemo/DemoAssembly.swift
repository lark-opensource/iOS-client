//
//  LarkRoomsWebViewAssembly.swift
//  LarkRoomsWebView
//
//  Created by zhouyongnan on 2022/7/19.
//

import LarkAssembler
import Swinject
import AppContainer
import UIKit
import LarkNavigation
import EENavigator
import LarkTab
import ByteViewNetwork
import LarkRVC
import LarkAccountInterface
import BootManager
import LarkPerf
import LKCommonsLogging
import LarkWebViewContainer
import LarkRustClient
import RustPB
import RxSwift
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface
import LarkUIKit
import LarkForward

public class DemoAssembly: LarkAssemblyInterface {

    init() {
        HttpClient.setupDependency(NetworkDependencyImpl.shared)
    }

    public func registContainer(container: Container) {
        container.register(LarkWebViewProtocol.self) { _ in
            TestWebViewProtocolHandler()
        }.inObjectScope(.user)
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute_(plainPattern: Tab.test.urlString, priority: .high) {
            TestTabHandler()
        }

        Navigator.shared.registerRoute_(type: WhiteBoardShareBody.self, cacheHandler: true) {
            return WhiteBoardShareHandler()
        }

    }

    public func registTabRegistry(container: Container) {
        (Tab.test, { (_: [URLQueryItem]?) -> TabRepresentable in
            TestTab()
        })
    }

    /// 启动任务注册 NewBootManager.regist
    public func registLaunch(container: Container) {
        NewBootManager.register(RVCSetupBootTask.self)
    }

    public func registLarkAppLink(container: Container) {
        ForwardAlertFactory.register(type: WhiteBoardShareAlertProvider.self)
    }

//    /// 用来注册AlertProvider的类型
//    @_silgen_name("Lark.LarkForward_LarkForwardMessageAssembly_regist.VCMessengerAssembly")
//    public static func providerRegister() {
//        ForwardAlertFactory.register(type: WhiteBoardShareAlertProvider.self)
//    }

}

struct SwinjectUtil {
    static func resolve<T>(_ serviceType: T.Type) -> T? {
        let userId = AccountServiceAdapter.shared.foregroundUser?.userID ?? ""
        if let resolver = try? Container.shared.getUserResolver(userID: userId),
           let service = try? resolver.resolve(assert: serviceType) {
            return service
        } else {
            return nil
        }
    }

    static let userScope: UserLifeScope = .userV2
}

class RVCSetupBootTask: FlowBootTask, Identifiable {
    static var identify: TaskIdentify = "RVCSetupTask"

    override func execute(_ context: BootContext) {
        LarkRoomWebViewManager.registerRouter()
        LarkRoomWebViewManager.setupGetDeviceIdHandler(handler: {
            AccountServiceAdapter.shared.deviceService.deviceId
        })
        LarkRoomWebViewManager.registerSettingsObserve()
        LarkRoomWebViewManager.setupGetWatermarkInfoHandler(handler: WhiteBoardShareAndSavePic.getUsernameAndPhone)
        LarkRoomWebViewManager.setupShareImageToChatHandler(handler: WhiteBoardShareAndSavePic.shareImages)
    }
}

class TestWebViewProtocolHandler: LarkWebViewProtocol {

    public func ajaxFetchHookString() -> String? {
        ""
    }
    public func setupAjaxFetchHook(webView: LarkWebView) {

    }
}

enum WhiteBoardShareAndSavePic {

    static func getUsernameAndPhone(userID: String) -> Observable<(String, String)> {
        @Provider var rustService: RustService
        var request = Contact_V1_GetChatterMobileRequest()
        let userId = AccountServiceAdapter.shared.currentAccountInfo.userID
        let userName = AccountServiceAdapter.shared.currentAccountInfo.name
        request.chatterID = userId
        return rustService.sendAsyncRequest(request, transform: {
            (response: Contact_V1_GetChatterMobileResponse) -> (String, String) in
            (userName, response.mobile)
        })
    }

    static func shareImages(userID: String, from: UIViewController, paths: [String]) {
        var body = WhiteBoardShareBody(imagePaths: paths, nav: from.navigationController)
        Navigator.shared.present(
            body: body,
            from: from,
//            prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
    }
}

public struct WhiteBoardShareBody: PlainBody {
    public static let pattern = "//client/byteview/whiteboard/share"
    public let imagePaths: [String]
    public let nav: UINavigationController?
    public init(imagePaths: [String], nav: UINavigationController? = nil) {
        self.imagePaths = imagePaths
        self.nav = nav
    }
}

public class WhiteBoardShareHandler: TypedRouterHandler<WhiteBoardShareBody> {
    @Provider private var forwardService: ForwardViewControllerService

    override public func handle(_ body: WhiteBoardShareBody, req: EENavigator.Request, res: Response) {
        createForward(body: body, req: req, res: res)
    }

    func createForward(body: WhiteBoardShareBody, req: EENavigator.Request, res: Response) {
        let imagePaths = body.imagePaths
        let nav = body.nav
        let content = WhiteBoardShareContent(imagePaths: imagePaths, nav: nav)
        guard let vc = forwardService.forwardViewController(with: content) else {
            res.end(error: RouterError.invalidParameters("imagePaths"))
            return
        }
        let nvc = LkNavigationController(rootViewController: vc)
        nvc.modalPresentationStyle = .fullScreen
//        nvc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        res.end(resource: nvc)
    }
}

public struct WhiteBoardShareContent: ForwardAlertContent {
    public let imagePaths: [String]
    public let nav: UINavigationController?
    public init(imagePaths: [String], nav: UINavigationController? = nil) {
        self.imagePaths = imagePaths
        self.nav = nav
    }
}

public class WhiteBoardShareAlertProvider: ForwardAlertProvider {
    static let logger = Logger.log(WhiteBoardShareAlertProvider.self, category: "WhiteBoardShare")
    public override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? WhiteBoardShareContent != nil {
            return true
        }
        return false
    }

    public override var isSupportMultiSelectMode: Bool {
        return false
    }

    public override var shouldCreateGroup: Bool {
        return false
    }

    public override func sureAction(items: [LarkMessengerInterface.ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let whiteBoardShareContent = content as? WhiteBoardShareContent else { return .just([]) }
        let forwardService = resolver.resolve(ForwardService.self)!
        let ids = self.itemsToIds(items)
        let urls = whiteBoardShareContent.imagePaths.map{ URL.init(fileURLWithPath: $0) }
        return forwardService.share(imageUrls: urls, extraText: input, to: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .do(onNext: { _ in
                Self.logger.info("send images success")
                LarkRoomWebViewManager.showImageSentToast()
                if let nav = whiteBoardShareContent.nav {
                    nav.popViewController(animated: false)
                }
            }, onError: { (error) in
                Self.logger.error("send images fail", error: error)
                if let nav = whiteBoardShareContent.nav {
                    nav.popViewController(animated: false)
                }
            })
    }
}

import ByteViewCommon
import ByteViewNetwork
import LarkRustClient
import LarkContainer

final class NetworkDependencyImpl: NetworkDependency {
    static let shared = NetworkDependencyImpl()

    func sendRequest(request: RawRequest, completion: @escaping (RawResponse) -> Void) {
        guard let rust = rustService(for: request.userId) else {
            completion(RawResponse(contextId: request.contextId, result: .failure(NetworkError.rustNotFound)))
            return
        }

        var packet: RawRequestPacket
        switch request.command {
        case .rust(let cmd):
            packet = RawRequestPacket(command: cmd, message: request.data)
        case .server(let cmd):
            packet = RawRequestPacket(serCommand: cmd, message: request.data)
        }
        if request.keepOrder {
            packet.serialToken = Self.serialToken(for: request.command)
        }
        if let contextIdCallback = request.contextIdCallback {
            packet.contextIdGenerationCallback = contextIdCallback
        }
        rust.async(packet) { (response: ResponsePacket<Data>) in
            let contextId = response.contextID
            switch response.result {
            case .success(let data):
                completion(RawResponse(contextId: contextId, result: .success(data)))
            case .failure(let error):
                if let rcError = error as? RCError, case let .businessFailure(errorInfo: errorInfo) = rcError {
                    let bizError = RustBizError(code: Int(errorInfo.errorCode), debugMessage: errorInfo.debugMessage,
                                                displayMessage: errorInfo.displayMessage, msgInfo: errorInfo.displayMessage)
                    completion(RawResponse(contextId: contextId, result: .failure(bizError)))
                } else {
                    completion(RawResponse(contextId: contextId, result: .failure(error)))
                }
            }
        }
    }

    private func rustService(for userId: String) -> RustService? {
        if userId.isEmpty {
            assertionFailure("using global RustService")
            return Container.shared.resolve(RustService.self)
        } else {
            return SwinjectUtil.resolve(RustService.self)
        }
    }

    @RwAtomic
    private static var tokenCache: [NetworkCommand: SerialToken] = [:]
    private static func serialToken(for command: NetworkCommand) -> SerialToken {
        if let cache = tokenCache[command] {
            return cache
        } else {
            let token = RequestPacket.nextSerialToken()
            tokenCache[command] = token
            return token
        }
    }
}
