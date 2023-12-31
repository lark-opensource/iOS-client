//  Created by weidong fu on 18/3/2018.
//

import Foundation
import WebKit
import RxSwift
import SwiftyJSON
import SKCommon
import SKFoundation
import LarkWebViewContainer
import SpaceInterface

///处理feed里的评论
public final class CommentFeedService: BaseJSService {

    weak var feedPanel: FeedPanelViewController?
    var commentManager: RNCommentDataManager
    var fetchMessageCallback: String   = ""
    var commentDocsInfo: DocsInfo
    var checkedShareMessage = false
    var feedMessages: [String: Any]?

    var fetched = false
    var feedCallback: APICallbackProtocol?
    typealias MessageType = (FeedEventListenerAction, [String: Any])
    
    var messageQueue: [MessageType] = []

    var notificationDispose: BrowserViewLifeCycle.NotificationDispose?
    
//    lazy var commentAdapter: WebCommentAdapter = {
//        let adapter = WebCommentAdapter(self)
//        if let commentRequest = self.fetchServiceInstance(CommentRequestNative.self) {
//            adapter.requestNativeService = commentRequest
//        }
//         return adapter
//    }()
    
    public override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        commentDocsInfo = DocsInfo(type: model.hostBrowserInfo.docsInfo?.inherentType ?? .doc,
                            objToken: model.hostBrowserInfo.docsInfo?.token ?? "")
        let type = model.hostBrowserInfo.docsInfo?.inherentType ?? .doc
        commentManager = RNCommentDataManager(fileToken: model.hostBrowserInfo.docsInfo?.token ?? "",
                                              type: type.rawValue,
                                              extraId: model.jsEngine.editorIdentity)
        commentManager.needEndSync = false
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        commentManager.delegate = self
        notificationDispose = model.browserViewLifeCycleEvent.addLifeCycleNotification(level: .high, noti: { [weak self] stage in
            DocsLogger.feedInfo("\(stage)")
            switch stage {
            case .browserViewControllerDidLoad:
                self?.checkUnreadMessage()
            case .browserDidDismiss:
                self?.feedPanel?.dismissPanel(animated: false)
            default:
                break
            }
        })
        model.permissionConfig.hostPermissionEventNotifier.addObserver(self)
    }
    
    public func checkUnreadMessage() {
        guard let browserVC = navigator?.currentBrowserVC as? BrowserViewController else {
           return
        }
        var params: [String: Any] = ["animated": true,
                                     "isFromLarkFeed": true]
        guard let feedFromInfo = browserVC.fileConfig?.feedFromInfo,
              feedFromInfo.canShowFeedAtively == true else {
            return
        }
        feedFromInfo.record(.openPanel)
        params["feedInfo"] = feedFromInfo
        //有未读消息
        let logInfo = ["isFromLarkFeed: \(feedFromInfo.isFromLarkFeed)",
                       "unreadCount: \(feedFromInfo.unreadCount)",
                       "messageType: \(feedFromInfo.messageType)",
                       "isFromPushNotification: \(feedFromInfo.isFromPushNotification)"]
            .joined(separator: ", ")
        DocsLogger.info("--------->根据标记知道文档有未读，主动弹起面板, \(logInfo)")
        handleShowFeed(params)
    }
    
    deinit {
        notificationDispose?.dispose()
    }
}

extension CommentFeedService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        // commentNotifyMessageChange
        return [.feedShowMessage,
                .feedCloseMessage,
                .commentGetMessageStatus,
                .commentResultNotify,
                .addFeedEventListener,
                .fetchMessage,
                .feedClosePanel,
                .readMessages,
                .commentNotifyMessageChange]
    }

    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        switch DocsJSService(rawValue: serviceName) {
        case .addFeedEventListener:
            self.feedCallback = callback
        default:
            break
        }
        self.handle(params: params, serviceName: serviceName)
    }

    // swiftlint:disable cyclomatic_complexity
    public func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(rawValue: serviceName)

        switch service {
        case .fetchMessage: // 前端调用RN接口获取数据
            DocsLogger.feedInfo("fetchMessage")
            guard let docInfo = hostDocsInfo/*,
            let callback = params["callback"] as? String */ else {
                DocsLogger.info("--------->docInfo为空")
                return
            }
            // 离线转在线会换token，这时需要重新实例
            if commentDocsInfo.token != docInfo.token {
                commentManager = RNCommentDataManager(fileToken: docInfo.token,
                                                      type: docInfo.inherentType.rawValue,
                                                      extraId: model?.jsEngine.editorIdentity)
                commentManager.delegate = self
                commentManager.needEndSync = false
                commentDocsInfo = DocsInfo(type: docInfo.inherentType, objToken: docInfo.token)
            }
            if !fetched {
                self.fetched = true
                DocsLogger.feedInfo("webview begin fetchFeedData")
                commentManager.fetchFeedData(docInfo: docInfo) { [weak self] (msg) in
                    guard let `self` = self,
                          let res = msg as? [String: Any] else {
                        return
                    }
                    DocsLogger.feedInfo("webview fetchFeedData success")
                    DispatchQueue.global().async {
                        self.notifyFeedBadge(data: JSON(res))
                    }
                }
            }
        case .addFeedEventListener:
            DocsLogger.feedInfo("addFeedEventListener")
            callIfNeed()
            
        case .feedShowMessage: // 弹出面板
            DocsLogger.feedInfo("feedShowMessage")
            handleShowFeed(params)

        case .commentGetMessageStatus: //获取面板展开状态
            DocsLogger.feedInfo("commentGetMessageStatus")
            guard let callback = params["callback"] as? String else { return }
            var isShowFeed = false
            if let panel = feedPanel, panel.from.isFromLarkFeed {
                isShowFeed = true
            }
            DocsLogger.feedInfo("----<>前端获取isShowPanel, need=\(isShowFeed), present=\(feedPanel != nil)")
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["show": isShowFeed], completion: nil)
        case .commentNotifyMessageChange: //通知刷新
            DocsLogger.feedInfo("receive frontend message")
            self.feedMessages = params
            feedPanel?.udpate(param: params)

        case .commentResultNotify: // 不知道干嘛的，可能没用了
            _handleSendCommendResult(params: params)
        case .feedCloseMessage: // native 自主关闭面板
            feedPanel?.dismissPanel(animated: false)
        case .feedClosePanel: // 前端主动调用关闭面板
            DocsLogger.feedInfo("feedClosePanel")
            feedPanel?.dismissPanel(animated: true)
        case .readMessages: // 全文评论红点
            DocsLogger.feedInfo("readMessages")
            _handlReadMessage(params: params)
        default:
            spaceAssertionFailure()
        }
    }

    private func _handlReadMessage(params: [String: Any]) {
        guard let docInfo = hostDocsInfo else {
            DocsLogger.info("handlReadMessage docInfo没有准备好")
            return
        }
        guard let messageIds = params["messageIds"] as? [String] else {
            DocsLogger.info("handlReadMessage 前端返回数据格式不对")
            return
        }
        DocsLogger.info("handlReadMessage 清除全文评论红点")
        clearBadge(params: [DocsSDK.Keys.readFeedMessageIDs: messageIds,
                            "doc_type": docInfo.inherentType,
                            "isFromFeed": true,
                            "obj_token": docInfo.token])
    }
    
    private func _handleSendCommendResult(params: [String: Any]) {

        guard let code = params["code"] as? Int,
            let action = params["action"] as? String,
            params["token"] as? String != nil else {
                return
        }

        let msg = params["msg"] as? String

        if code != 0 {
            DocsLogger.info("commentSendFail msg=\(String(describing: msg)),code=\(code),action=\(action)")
        }
//        currentFeedVC?.commentService?.handleSendCommentCallBack(errorCode: code, msg: msg)

    }

    private func _trackEvent(_ params: [String: Any]) {
        guard let isUserAction = params["isUserAction"] as? Int,
            let docsInfo = hostDocsInfo,
            isUserAction == 1 else {
            return
        }

        let unReadCount = (params["unReadCount"] as? Int) ?? 0

        let params = [
            "file_id": DocsTracker.encrypt(id: docsInfo.token),
            "file_type": docsInfo.inherentType.name,
            "network_status": DocsNetStateMonitor.shared.isReachable ? "1": "0",
            "unread_badge_count": "\(unReadCount)",
            "is_user_action": "\(isUserAction)"
            ] as [String: Any]

        DocsLogger.info("--------->打点了，点击铃铛打点上报\(params)")
        DocsTracker.log(enumEvent: .clickNotificationIcon, parameters: params)
    }
    
    private func handleShowFeed(_ params: [String: Any]) {
        openNewPanel(params)
    }
    
    func openNewPanel(_ params: [String: Any]) {
        
        guard let hostViewController = navigator?.currentBrowserVC as? BaseViewController else {
            DocsLogger.info("navigator currentBrowserVC is nil")
            spaceAssertionFailure()
            return
        }
        
        guard feedPanel == nil else {
            feedPanel?.repeatShow()
            DocsLogger.feedInfo("feedPanel repeatShow")
            return
        }
        // 获取必要参数
        guard let docInfo = hostDocsInfo else {
            DocsLogger.feedError("openNewPanel docInfo is nil")
            return
        }
        let isInVCFollow = docInfo.isInVideoConference ?? false
        
        var from = FeedFromInfo()
        if let fromInfo = params["feedInfo"] as? FeedFromInfo {
            from = fromInfo
        }
        
        // 展示UI
        let vc = FeedPanelViewController(api: self, from: from, docsInfo: docInfo, param: self.feedMessages)
        vc.modalPresentationStyle = isInVCFollow ? .overFullScreen : .overCurrentContext
        if docInfo.inherentType.supportLandscapeShow {
            vc.supportOrientations = hostViewController.supportedInterfaceOrientations
        }
        navigator?.presentViewController(vc, animated: true, completion: nil)
        let allowCopy = model?.permissionConfig.hostCanCopy ?? false
        vc.setCaptureAllowed(allowCopy)
        // 设置feedPanel的dataSource
        vc.permissionDataSource = self
        feedPanel = vc
        DocsLogger.feedInfo("openNewPanel isFromLarkFeed:\(from.isFromLarkFeed)")
        if !from.isFromLarkFeed {
            _trackEvent(params)
        }
    }
}


extension CommentFeedService: CommentDataDelegate {
    
    public func didReceiveCommentData(response: RNCommentData, eventType: RNCommentDataManager.CommentReceiveOperation) {

    }

    public func didReceiveUpdateFeedData(response: Any) {
        guard let res = response as? [String: Any] else {
            DocsLogger.error("didReceiveUpdateFeedData format is incorrect")
            return
        }
        let jsonData = JSON(response)
        let messageCount = jsonData["data"]["message"].arrayValue.count
        DocsLogger.feedInfo("receive RN Feed data count: \(messageCount)")
        if let data = res["data"] as? [String: Any] {
            self.feedPanel?.udpate(param: data)
            self.feedMessages = data
        }
        callFunction(for: .change, params: res)
    }

    func clearBadge(params: [String: Any]) {
        guard let awesomeManager = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else {
            DocsLogger.info("DocsFeedViewController----消除badge manager失败")
            return
        }
        awesomeManager.sendReadMessageIDs(params, in: nil, callback: { _ in })
        DocsLogger.info("DocsFeedViewController----消除badge\(params["readFeedMessageIDs"])")
    }
}

extension CommentFeedService {
    
    func notifyFeedBadge(data: JSON) {
           let messages = data["data"]["messages"].arrayValue
           DocsLogger.feedInfo("notifyFeedBadge messages:\(messages)")
           // 兜底逻辑
           if let ver = data["data"]["badge"]["ver"].int32,
               let count = data["data"]["badge"]["count"].int32,
               let token = hostDocsInfo?.token {
               DocsFeedService.clearBadge(ver, count, token)
           }
       }
}


// 提供给其他service的接口
extension CommentFeedService {
    
    public func closePanel() {
        guard let feedPanel = feedPanel else {
            return
        }
        if feedPanel.isShowing {
            feedPanel.dismissPanel(animated: false)
        } else {
            DocsLogger.feedInfo("feed panel had closed")
        }
    }
    
}

extension CommentFeedService: BrowserViewLifeCycleEvent {
    
    public func browserWillClear() {
        // 兜底逻辑，清理feedPanel
        feedPanel?.dismissPanel(animated: true)
    }
}

extension CommentFeedService: DocsPermissionEventObserver {

    public func onCopyPermissionUpdated(canCopy: Bool) {
        feedPanel?.setCaptureAllowed(canCopy)
        feedPanel?.reloadTableViewData()
    }

    public func onViewPermissionUpdated(oldCanView: Bool, newCanView: Bool) {
        if oldCanView, !newCanView { // 由'可阅读'变为'不可阅读',需要关掉通知
            feedPanel?.dismissPanel(animated: true)
        }
    }
}

extension CommentFeedService: CCMCopyPermissionDataSource {
    public func ownerAllowCopy() -> Bool {
        model?.permissionConfig.hostCanCopy ?? false
    }

    public func canPreview() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let permissionService = getCopyPermissionService() else { return false }
            return permissionService.validate(operation: .preview).allow
        } else {
            return model?.permissionConfig.hostUserPermissions?.canPreview() ?? false
        }
    }

    public func getCopyPermissionService() -> UserPermissionService? {
        model?.permissionConfig.getPermissionService(for: .hostDocument)
    }
}
