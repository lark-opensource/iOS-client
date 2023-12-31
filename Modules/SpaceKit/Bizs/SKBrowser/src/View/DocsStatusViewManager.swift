//
//  DocsStatusView.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/2.
//

import SKFoundation
import Lottie
import SnapKit
import SKCommon
import SKUIKit
import SKResource
import EENavigator
import UniverseDesignLoading
import UIKit
import UniverseDesignColor
import UniverseDesignTheme
import SpaceInterface
import SKInfra
import LarkContainer

enum DocsStatusViewAction {
    case reload
}

enum LoadingViewType {
    case justBegin
    case larkLoading(url: URL)
    case success
    case overtime
    case fail(msg: String, code: String?)
}

public struct CustomStatusConfig {
    let hostView: UIView?   // 目标显示宿主view
    let onlyAcceptFailTipsView: Bool?   // 只接受 FailTipsView
    
    public init(hostView: UIView?, onlyAcceptFailTipsView: Bool?) {
        self.hostView = hostView
        self.onlyAcceptFailTipsView = onlyAcceptFailTipsView
    }
}

protocol DocsStatusViewDelegate: AnyObject {
    func statusView(_ statusView: SpaceEditorLoadingAbility, didInvoke action: DocsStatusViewAction)
    func costomStateHostConfig() -> CustomStatusConfig?
    var statusBrowserView: BrowserView? { get }
}

class SpaceStatusViewManager: NSObject, SpaceEditorLoadingAbility {
    weak var delegate: DocsStatusViewDelegate?
    // loadingView 不能加在maskView上， 否则动画失效！
    let loadingView = UDLoading.loadingImageView()
    private lazy var maskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    weak var hostView: UIView? {
        return delegate?.costomStateHostConfig()?.hostView ?? _hostView
    }
    private weak var _hostView: UIView?
    var identity: String?
    let userResolver: UserResolver
    lazy private var whiteBlankView: UIView = {
        let view = UIView()
        if let hView = hostView {
            hView.addSubview(view)
            //系统选Dark模式，app选light模式情况下。这里UDColor适配DarkMode有个比较奇怪的情况，新创建的view有可能与父view的userInterfaceStyle不一致，底层原因目前没找到，下面的处理目前可以解决
            if #available(iOS 13.0, *), hView.traitCollection.userInterfaceStyle != view.traitCollection.userInterfaceStyle {
                view.overrideUserInterfaceStyle = UDThemeManager.getRealUserInterfaceStyle()
            }
            view.backgroundColor = UDColor.bgBody
            view.isHidden = true
            
            view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        } else {
            spaceAssertionFailure("host view is nil")
        }
        return view
    }()

    private lazy var failTipsView: EmptyListPlaceholderView = {
        let view = EmptyListPlaceholderView(frame: .zero)
        view.backgroundColor = UIColor.ud.N00
        view.isHidden = true

        view.delegate = self
        if let hView = hostView {
            hView.addSubview(view)
            view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        } else {
            spaceAssertionFailure("host view is nil")
        }
        return view
    }()

    class func statusViewMangerWith(hostView: UIView?, delegate: DocsStatusViewDelegate?, userResolver: UserResolver) -> SpaceStatusViewManager {
        return SpaceStatusViewManager(hostView, delegate: delegate, userResolver: userResolver)
    }

    fileprivate init(_ hostView: UIView?, delegate: DocsStatusViewDelegate?, userResolver: UserResolver) {
        self.userResolver = userResolver
        self._hostView = hostView
        self.delegate = delegate
        super.init()
    }

    func updateLoadStatus(_ type: LoadingViewType, oldStatus: LoadStatus?) {
        switch type {
        case .justBegin:
            showBlankView()
        case .larkLoading(let url):
            if URLValidator.isMainFrameTemplateURL(url) == false {
                showLoadingIndicator()
            }
        case .success:
            onSuccess()
        case .overtime:
            showOvertimeTip(oldStatus: oldStatus)
            //swiftlint:disable pattern_matching_keywords
        case .fail(let msg, let code):
            showFailTipsIndicator(type: .openFileWebviewFail, msg: msg, code: code)
        }
    }

    fileprivate func onSuccess() {
        hideAll()
    }
    
    private func showBlankView() {
        hideAll()
        if delegate?.costomStateHostConfig()?.onlyAcceptFailTipsView == true {
            return
        }
        whiteBlankView.isHidden = false
        if whiteBlankView.superview == nil {
            self.hostView?.addSubview(whiteBlankView)
        }
        hostView?.bringSubviewToFront(whiteBlankView)
    }

    fileprivate func hideAll() {
        whiteBlankView.isHidden = true
        whiteBlankView.removeFromSuperview()
        hideFailTipsIndicator()
        hideLoadingIndicator()
    }

    func showLoadingIndicator() {
        hideAll()
        if delegate?.costomStateHostConfig()?.onlyAcceptFailTipsView == true {
            return
        }
        if loadingView.superview == nil {
            hostView?.addSubview(maskView)
            hostView?.addSubview(loadingView)
            maskView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            loadingView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
//        if #available(iOS 13.0, *) {
//            // docs 等在线文档的内容不支持 DM，这里把 loading 也设置为 light mode，避免出现 白 - 黑 - 白 的闪烁问题
//            loadingView.overrideUserInterfaceStyle = .light
//            maskView.overrideUserInterfaceStyle = .light
//        }
        setLoadingComponent(isHidden: false)
    }

    func hideLoadingIndicator(completion: @escaping () -> Void = { }) {
        removeLoadingComponent()
        completion()
    }

    func showFailTipsIndicator(type: EmptyListPlaceholderView.EmptyType, msg: String, code: String?) {
        hideAll()
        DocsLogger.info("\(identity ?? "noid") show fail with msg \(msg) code \(code)", component: LogComponents.fileOpen)
        failTipsView.isHidden = false
        var domainAndCode: (String, String)?
        if let code = code {
            domainAndCode = ("", code)
        }
        failTipsView.config(error: ErrorInfoStruct(type: type, title: msg, domainAndCode: domainAndCode))
        hostView?.bringSubviewToFront(failTipsView)
        spaceAssert(hostView != nil)
    }

    func hideFailTipsIndicator() {
        failTipsView.isHidden = true
    }

    func showOvertimeTip(oldStatus: LoadStatus?) {
        DocsLogger.info("\(identity ?? "noid") 使用特定资源包版本？\(GeckoPackageManager.shared.isUsingSpecial(.webInfo))")
        var code = ErrorInfoStruct.documentLoadDefaultCode
        if let oldStatus = oldStatus {
            switch oldStatus {
            case .loading(let loadingStage):
                switch loadingStage {
                case .start(_, let isPreload):
                    if isPreload == false {
                        let maxContinuousFailCount = SettingConfig.docsWebViewConfig?.maxContinuousFailCount ?? 0 //0则不限制
                        let continuousFailCount = self.userResolver.docs.editorManager?.pool.continuousFailCount ?? 0
                        if maxContinuousFailCount > 0, let browserView = delegate?.statusBrowserView, !browserView.preloadStatus.value.hasLoadSomeThing, continuousFailCount > maxContinuousFailCount {
                            //针对连续预加载失败的情况，直接提示用户重启，webview已经恢复不了了
                            code = ErrorInfoStruct.nonResponsiveCode
                            DocsLogger.error("showOvertimeTip for nonResponsive:\(continuousFailCount)", component: LogComponents.fileOpen)
                            break
                        }
                    }
                    code = ErrorInfoStruct.documentLoadStartCode
                case .preloadOk:
                    code = ErrorInfoStruct.documentLoadPreloadOK
                case .renderCachStart:
                    code = ErrorInfoStruct.documentLoadaRenderCachStart
                case .renderCacheSuccess:
                    code = ErrorInfoStruct.documentLoadaRenderCacheSuccess
                case .renderCalled:
                    code = ErrorInfoStruct.documentLoadaRenderCalled
                case .afterReadLocalClientVar:
                    code = ErrorInfoStruct.documentLoadaAfterReadLocalClientVar
                case .beforeReadLocalHtmlCache:
                    code = ErrorInfoStruct.documentLoadaBeforeReadLocalHtmlCache
                }
            default:
                DocsLogger.info("just loading need show loadingStage", component: LogComponents.fileOpen)
            }
        }
        hideAll()
        failTipsView.isHidden = false
        failTipsView.config(error: code)
        hostView?.bringSubviewToFront(failTipsView)
        spaceAssert(hostView != nil)
        DocsLogger.info("\(identity ?? "noid") show fail with msg（overtime） code: \(code)", component: LogComponents.fileOpen)
    }

    @objc
    func didClickFailTips(_ gesture: UITapGestureRecognizer) {
        hideAll()
        delegate?.statusView(self, didInvoke: .reload)
    }

    func clear() {
        whiteBlankView.removeFromSuperview()
        failTipsView.removeFromSuperview()
        removeLoadingComponent()
    }
}

extension SpaceStatusViewManager: ErrorPageProtocol {
    func didClickReloadButton() {
        didClickFailTips(UITapGestureRecognizer())
    }
}

// MARK: - loading

extension SpaceStatusViewManager {
    func setLoadingComponent(isHidden: Bool) {
        maskView.isHidden = isHidden
        loadingView.isHidden = isHidden
    }
    
    func removeLoadingComponent() {
        loadingView.removeFromSuperview()
        maskView.removeFromSuperview()
    }
}
