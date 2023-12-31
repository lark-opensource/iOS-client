//
//  VCFollowFactory.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/2.
//


import Foundation
import SpaceInterface
import RxSwift
import SKCommon
import SKFoundation
import SKUIKit
import SpaceInterface
import SKInfra

public final class DocsVCFollowFactory: FollowAPIFactory {

    private let docsSDK: DocsSDK
    public static let fromKey = "vcFollow"
    private var lastTime: Int64 = 0 //需要记住上次VCFollow调用Docs打开文档的时间，做调用频率限制

    public init(docsSDK: DocsSDK) {
        self.docsSDK = docsSDK
    }

    public func startMeeting() {
        BaseFollowAPIImpl.startMeeting()
    }

    public func stopMeeting() {
        BaseFollowAPIImpl.stopMeeting()
    }

    /// 打开Lark文档
    public func open(url urlString: String, events: [FollowEvent]) -> FollowAPI? {
        return innerOpen(url: urlString, isDocsUrl: true, events: events)
    }

    /// 打开GoogleDrive的文档
    public func openGoogleDrive(url urlString: String, events: [FollowEvent], injectScript: String?) -> FollowAPI? {
        return innerOpen(url: urlString, isDocsUrl: false, events: events, injectScript: injectScript)
    }

    private func innerOpen(url urlString: String, isDocsUrl: Bool, events: [FollowEvent], injectScript: String? = nil) -> FollowAPI? {
        let rootId = SKTracing.shared.startRootSpan(spanName: SKVCFollowTrace.openVCFollow)
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        let vcWebId = "\(currentTime)"
        let params = ["from": DocsVCFollowFactory.fromKey,
                     "coverEnabled": "false",
                     "vcwebid": vcWebId //FollowAPI打开文档时用token+vcwebid作为唯一标识，光token不能区分多个实例打开同一文档
        ]
        
        
        
        guard let url = URL(string: urlString)?.docs.addOrChangeQuery(parameters: params) else {
            SKTracing.shared.endSpan(spanName: SKVCFollowTrace.openVCFollow,
                                     rootSpanId: rootId,
                                     spanResult: .error(errMsg: "open了不是有效的url"),
                                     params: ["url": urlString.encryptToShort],
                                     component: LogComponents.vcFollow)
            return nil
        }
        
        
        let diffInterval = currentTime - lastTime
        lastTime = currentTime
        if diffInterval < 500 {
            DocsLogger.vcfError("500ms内连续打开了页面")
            //return nil  //VC上层节流了，而且VC是有可能500ms内连续收到请求的，所以不再限制
        }
        
        return openV2(url: url, isDocsUrl: isDocsUrl, events: events, vcWebId: vcWebId, tracingContext: TracingContext(rootId: rootId))
    }

    /// 新版本open
    private func openV2(url: URL, isDocsUrl: Bool, events: [FollowEvent], vcWebId: String, injectScript: String? = nil, tracingContext: TracingContext) -> FollowAPI? {

        var followableViewController: FollowableViewController?
        if isDocsUrl {
            let vc = docsSDK.open(url.absoluteString)
            followableViewController = vc as? FollowableViewController
        } else {
            // 支持google doc注入js代码 -- Start
            var finalScript = injectScript
            //判断是否开启了注入
            let useInjectJS = CCMKeyValue.globalUserDefault.bool(forKey: "UseThirdPartyJavascript")
            if useInjectJS {
                if let jsPath = CCMKeyValue.globalUserDefault.string(forKey: "JavascriptPath") {
                    do {
                        let file = SKFilePath(absPath: jsPath)
                        finalScript = try String.read(from: file)
                    } catch {
                        DocsLogger.info("read inject script failed", component: LogComponents.vcFollow, traceId: tracingContext.traceRootId)
                    }
                }
            }
            // 支持google doc注入js代码 -- End
            //所有非Docs链接都用第三方webview打开
            followableViewController = openExternalWebVC(url: url, injectScript: finalScript, tracingContext: tracingContext)
        }

        guard let followableVC = followableViewController  else {
            SKTracing.shared.endSpan(spanName: SKVCFollowTrace.openVCFollow,
                                     rootSpanId: tracingContext.traceRootId,
                                     spanResult: .error(errMsg: "不支持Follow的VC"),
                                     params: ["url": url.absoluteString.encryptToShort],
                                     component: LogComponents.vcFollow)
            
            return nil
        }

        var events = events
        var followAPI: BaseFollowAPIImpl
        let isDriveVC = docsSDK.userResolver.docs.browserDependency?.isDriveMainViewController(followableVC.followVC) ?? false
        if isDriveVC {
            followAPI = NativeFollowAPIImpl(url: url, vcWebId: vcWebId, followableVC: followableVC)
        } else {
            /// 不是走 RN 通道的，将 presenterFollowerLocation 给移除掉。
            events.filter { $0 != .presenterFollowerLocation }
            followAPI = BaseFollowAPIImpl(url: url, vcWebId: vcWebId, followableVC: followableVC)
        }
        followAPI.tracingContext = tracingContext
        followAPI.onSetup(events: events)
        let followTraceId = (followableVC as? SKTracableProtocol)?.traceRootId ?? "undefined"
        SKTracing.shared.endSpan(spanName: SKVCFollowTrace.openVCFollow,
                                 rootSpanId: tracingContext.traceRootId,
                                 params: ["isDocUrl": isDocsUrl,
                                          "isDriveVC": isDriveVC,
                                          "followTraceId": followTraceId,
                                          "url": url.absoluteString.encryptToShort],
                                 component: LogComponents.vcFollow)
        return followAPI
    }

    private func openExternalWebVC(url: URL, injectScript: String?, tracingContext: TracingContext) -> FollowableViewController {
        DocsLogger.info("openExternalWebVC", extraInfo: ["url": url], component: LogComponents.vcFollow, traceId: tracingContext.traceRootId)
        let followVC = SupportThirdPartyFollowViewController()
        followVC.openUrl(url.absoluteString)
        if let injectScript = injectScript {
            followVC.injectJavascript(injectScript)
        }
        return followVC
    }

    public static func isDocsURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return URLValidator.isDocsURL(url)
    }

    public static func getThumbnail(url: String,
                                    thumbnailInfo: [String: Any],
                                    imageSize: CGSize?) -> Observable<UIImage> {
        // VC 提供的 url 是加密的 URL，thumbnailInfo 中存储了加密的类型和参数
        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!
        let extraInfo = SpaceThumbnailInfo.ExtraInfo(urlString: url, encryptInfo: thumbnailInfo)
        guard let info = SpaceThumbnailInfo(unencryptURL: nil, extraInfo: extraInfo) else {
            return .error(SpaceThumbnailDownloader.DownloadError.parseDataFailed)
        }

        let processor = getAProcessorForDocThumbnailInVC(imageSize: imageSize)
        let request = SpaceThumbnailManager.Request(token: "vc-follow-thumbnail-token",
                                                    info: info,
                                                    source: .vcfollow,
                                                    fileType: .unknownDefaultType,
                                                    placeholderImage: nil,
                                                    failureImage: nil,
                                                    forceCheckForUpdate: true,
                                                    processer: processor)

        return manager.getThumbnail(request: request)
    }

    private static func getAProcessorForDocThumbnailInVC(imageSize: CGSize? = nil) -> SpaceThumbnailProcesser {
        guard let newSize = imageSize else {
            return SpaceDefaultProcesser()
        }
        /*
         vcFollow sharedoc 的布局见：DocsContent.swift，
         func configRowPresentable(_ presentable: RowPresentable, isPortrait: Bool, isRegular: Bool)
         */
        let offset: CGFloat = 5
        let insets: UIEdgeInsets = UIEdgeInsets(top: 15, left: 12, bottom: 15 + offset, right: 12)
        var processor = SpaceCropWhenReadProcesser(cropSize: newSize)
        processor.resizeInfo = SpaceThumbnailProcesserResizeInfo(targetSize: newSize,
                                                                 imageInsets: insets)
        return processor
    }
}


extension DocsLogger {
    class func vcfDebug(_ str: String, extraInfo: [String: Any]? = nil, error: Error? = nil) {
        DocsLogger.debug(str, extraInfo: extraInfo, error: error, component: LogComponents.vcFollow)
    }

    class func vcfInfo(_ str: String, extraInfo: [String: Any]? = nil, error: Error? = nil) {
        DocsLogger.info(str, extraInfo: extraInfo, error: error, component: LogComponents.vcFollow)
    }

    class func vcfError(_ str: String, extraInfo: [String: Any]? = nil, error: Error? = nil) {
        DocsLogger.error(str, extraInfo: extraInfo, error: error, component: LogComponents.vcFollow)
    }
}
