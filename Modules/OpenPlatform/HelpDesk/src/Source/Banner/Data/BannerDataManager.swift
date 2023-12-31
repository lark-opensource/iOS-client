//
//  BannerDataManager.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/26.
//

import Foundation
import Swinject
import LarkRustClient
import ServerPB
import LarkAccountInterface
import RxSwift
import LarkSDKInterface
import ECOProbe
import LKCommonsLogging
import ECOProbeMeta
import LarkLocalizations

typealias BannerDataResponseCallback = (_ error: HelpDeskError?, _ response: BannerResponse?) -> Void

protocol BannerDataManagerProtocol: AnyObject {
    
    func didContainerChanged(container: BannerContainer, response: BannerResponse)
}

class BannerDataManager {
    
    weak var delegate: BannerDataManagerProtocol?
    
    private let client: RustService?
    private let chatID: String
    private let disposeBag: DisposeBag = DisposeBag()
    
    private var containerLastUpdateTime: TimeInterval = 0
    private var bannerContainer: BannerContainer? {
        didSet {
            containerLastUpdateTime = Date().timeIntervalSince1970
        }
    }
    
    init(
        resolver: Resolver,
        chatID: String
    ) {
        openBannerLogger.info("BannerDataManager.init. chatID:\(chatID)")
        self.chatID = chatID
        client = resolver.resolve(RustService.self)
        
        // 建立 Push 监听
        resolver.pushCenter
            .observable(for: BannerNotificationPullData.self)
            .subscribe(onNext: { [weak self] info in
                guard let self = self else {
                    openBannerLogger.info("BannerDataManager released")
                    return
                }
                self.pullBannerContainer()
            })
            .disposed(by: self.disposeBag)
        
        // 当网络从异常恢复时，尝试重试
        resolver.pushCenter
            .observable(for: PushDynamicNetStatus.self)
            .distinctUntilChanged({ push in
                push.dynamicNetStatus
            })
            .filter({ push in
                push.dynamicNetStatus == .excellent
            })
            .subscribe(onNext: { [weak self] push in
                guard let self = self else {
                    openBannerLogger.info("BannerDataManager released")
                    return
                }
                guard self.bannerContainer == nil else {
                    // 已经拉取过有效数据，不需要补充更新了
                    openBannerLogger.info("BannerDataManager container has been ready")
                    return
                }
                openBannerLogger.info("BannerDataManager.pullBannerContainer on net status change.")
                self.pullBannerContainer()
            })
            .disposed(by: self.disposeBag)
        
        // 当从后台返回时，执行更新操作
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else {
                    openBannerLogger.info("BannerDataManager released")
                    return
                }
                guard Date().timeIntervalSince1970 > self.containerLastUpdateTime + 5 * 60 else {
                    // 距离上一次更新数据不足 5 分钟，不需要再请求
                    openBannerLogger.info("BannerDataManager has recent updated when become active.")
                    return
                }
                openBannerLogger.info("BannerDataManager.pullBannerContainer when become active.")
                self.pullBannerContainer()
            }).disposed(by: disposeBag)
    }
    
    deinit {
        openBannerLogger.info("BannerDataManager.deinit:\(chatID)")
    }
    
    func pullBannerContainer(callback: BannerDataResponseCallback? = nil) {
        openBannerLogger.info("pullBannerContainer")
        let targetType = ServerPB_Open_banner_TargetType.chat
        let containerTag = ServerPB_Open_banner_ContainerTag.chatFooterBanner
        OPMonitor(HelpDeskMonitorEvent.open_banner_pull_start.rawValue)
            .addCategoryValue("target_id", chatID)
            .addCategoryValue("target_type", targetType.rawValue)
            .addCategoryValue("container_tag", containerTag.rawValue)
            .flush()
        let monitor = OPMonitor(HelpDeskMonitorEvent.open_banner_pull_result.rawValue).timing()
        let callback: BannerDataResponseCallback = { error, response in
            monitor
                .timing()
                .setBannerResponse(response)
                .setResultType(with: error)
                .flush()
            
            callback?(error, response)
        }
        guard let client = client else {
            openBannerLogger.error("client invalid")
            callback(HelpDeskError(.invalidClient), nil)
            return
        }
        
        var request = ServerPB_Open_banner_OpenBannerPullRequest()
        request.targetID = chatID
        request.targetType = targetType
        request.containerTag = containerTag
        request.userID = AccountServiceAdapter.shared.currentAccountInfo.userID
        request.version = "1.0"
        let language = LanguageManager.currentLanguage.languageIdentifier
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let contextDic:[String: String] = ["language" : language, "app_version": appVersion]
        request.context = dicValueString(contextDic) ?? ""
        let ob: Observable<ServerPB_Open_banner_OpenBannerResponse> =
            client.sendPassThroughAsyncRequest(request, serCommand: .openBannerPull)
        ob.subscribe(onNext: { [weak self] res in
            #if DEBUG
            openBannerLogger.debug("pullBannerContainer response:\(res.textFormatString())")
            #endif
            guard let self = self else {
                openBannerLogger.info("BannerDataManager released")
                return
            }
            guard res.code == 0 else {
                // 业务逻辑失败
                openBannerLogger.error("response code:\(res.code)")
                
                callback(HelpDeskError(.responseCodeError, message: "code:\(res.code)"), nil)
                return
            }
            do {
                let response = try BannerResponse.parse(from: res)
                openBannerLogger.info("pullBannerContainer response:\(response)")
                self.checkNewResponse(response: response)
                callback(nil, response)
                return
            } catch {
                openBannerLogger.error("BannerResponse parse failed. error:\(error)")
                callback(HelpDeskError(error), nil)
            }
        }, onError: { [weak self] error in
            openBannerLogger.error("pullBannerContainer error:\(error)")
            guard let self = self else {
                openBannerLogger.info("BannerDataManager released")
                return
            }
            callback(HelpDeskError(error), nil)
        }).disposed(by: self.disposeBag)
    }
    
    func postBannerAction(
        actionValue: String?,
        bannerResponse: BannerResponse,
        bannerResource: BannerResource,
        callback: BannerDataResponseCallback?
    ) {
        openBannerLogger.info("postBannerAction actionValue:\(safeLogValue(actionValue))")
        OPMonitor(HelpDeskMonitorEvent.open_banner_button_post_start.rawValue)
            .setBannerResource(bannerResource)
            .setBannerResponse(bannerResponse)
            .flush()
        let monitor = OPMonitor(HelpDeskMonitorEvent.open_banner_button_post_result.rawValue).timing()
        let callback: BannerDataResponseCallback = { error, response in
            monitor
                .timing()
                .setBannerResource(bannerResource)
                .setBannerResponse(bannerResponse)
                .setResultType(with: error)
                .flush()
            
            callback?(error, response)
        }
        guard let client = client else {
            openBannerLogger.error("client invalid")
            callback(HelpDeskError(.invalidClient), nil)
            return
        }
        
        var request = ServerPB_Open_banner_OpenBannerPostRequest()
        request.targetID = bannerResponse.targetID
        request.targetType = bannerResponse.targetType
        if let containerTag = bannerResponse.containerTag {
            request.containerTag = containerTag
        }
        if let context = bannerResponse.context {
            request.context = context
        }
        request.version = "1.0"
        request.userID = AccountServiceAdapter.shared.currentAccountInfo.userID
        request.resourceID = bannerResource.resourceID
        request.resourceType = bannerResource.resourceType
        if let actionValue = actionValue {
            request.value = actionValue
        }
        
        let ob: Observable<ServerPB_Open_banner_OpenBannerResponse> =
            client.sendPassThroughAsyncRequest(request, serCommand: .openBannerPost)
        ob.subscribe(onNext: { [weak self] res in
            #if DEBUG
            openBannerLogger.debug("postBannerAction response:\(res.textFormatString())")
            #endif
            guard let self = self else {
                openBannerLogger.info("BannerDataManager released")
                return
            }
            guard res.code == 0 else {
                // 业务逻辑失败
                openBannerLogger.error("response code:\(res.code)")
                callback(HelpDeskError(.responseCodeError, message: "code:\(res.code)"), nil)
                return
            }
            do {
                let response = try BannerResponse.parse(from: res)
                openBannerLogger.info("postBannerAction response:\(response)")
                self.checkNewResponse(response: response)
                callback(nil, response)
                return
            } catch {
                openBannerLogger.error("BannerResponse parse failed. error:\(error)")
                callback(HelpDeskError(error), nil)
            }
        }, onError: { [weak self] error in
            openBannerLogger.error("postBannerAction error:\(error)")
            guard let self = self else {
                openBannerLogger.info("BannerDataManager released")
                return
            }
            callback(HelpDeskError(error), nil)
        }).disposed(by: self.disposeBag)
        
    }
    
    private func dicValueString(_ dic:[String : Any]) -> String? {
        let data = try? JSONSerialization.data(withJSONObject: dic, options: [])
        if let data = data {
            let str = String(data: data, encoding: String.Encoding.utf8)
            return str
        } else {
            return nil
        }
    }
    
    private func checkNewResponse(response: BannerResponse) {
        if let container = response.container {
            let newTimestamp = container.timestamp
            let oldTimestamp = self.bannerContainer?.timestamp ?? 0
            if newTimestamp > oldTimestamp {
                self.bannerContainer = container
                openBannerLogger.info("didContainerChanged")
                self.delegate?.didContainerChanged(container: container, response: response)
            } else {
                openBannerLogger.warn("checkNewResponse timestamp not newest. newTimestamp:\(newTimestamp), oldTimestamp:\(oldTimestamp)")
            }
        } else {
            openBannerLogger.info("container is nil")
        }
    }
    
}
