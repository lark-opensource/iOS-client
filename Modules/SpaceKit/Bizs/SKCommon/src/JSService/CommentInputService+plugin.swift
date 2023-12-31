//
//  CommentInputService+plugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/18.
//  

import SKUIKit
import SKFoundation
import UniverseDesignToast
import SpaceInterface
import SKInfra

extension CommentInputService {
    
    func initFloatCommentModuleIfNeed() {
        if commentModule != nil {
            return
        }
        if let gadgetInfo = self.gadgetInfo {
            guard let requestNativeService = delegate?.fetchServiceInstance(token: gadgetInfo.objToken, CommentRequestNative.self) else {
                DocsLogger.error("init float comment fail, request nativ service empty", component: LogComponents.comment)
                return
            }
            let apiAdaper = CommentRNAPIAdaper(rnRequest: requestNativeService, commentService: self, dependency: self)
           
            let params = CommentModuleParams(dependency: self, apiAdaper: apiAdaper)
            commentModule = DocsContainer.shared.resolve(FloatCommentModuleType.self,
                                                         argument: params)

        } else {
            let webApi = CommentWebAPIAdaper(commentService: self)
            let params = CommentModuleParams(dependency: self, apiAdaper: webApi)
            commentModule = DocsContainer.shared.resolve(FloatCommentModuleType.self,
                                                         argument: params)
            // 监听发送前的事件，弹loading。这个是业务接入方的功能，不在评论模块内部处理。
            webApi.willSendToWeb = { [weak self] action in
                guard let self = self, let model = self.showInputModel else { return [:] }
                if action == .addComment, model.needLoading == true {
                    self.loadingToast?.remove()
                    let toastView = DocsContainer.shared.resolve(AddCommentToastView.self)
                    self.loadingToast = toastView?.showLoading(on: self.hostWindow)
                }
                // 不需要补充参数
                return [:]
            }
        }
        commentModule?.canPresentingDismiss = false
    }
    
    func showFloatComment(params: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            DocsLogger.error("new input data is invalid", component: LogComponents.comment)
            return
        }
        let decoder = DocsContainer.shared.resolve(CommentShowInputDecoder.self)
        guard var inputModel = decoder?.decode(data: data) else {
            DocsLogger.error("decode error",
                            component: LogComponents.comment)
            return
        }
        if inputModel.statsExtra == nil,
        var statsExtra = self.commentStatsExtra {
            statsExtra.generateReceiveTime()
            inputModel.statsExtra = statsExtra
            let callback = DocsJSService.simulateClearCommentEntrance.rawValue
            self.model?.jsEngine.simulateJSMessage(callback, params: [:])
        }
        inputModel.statsExtra?.generateReceiveTime()
        inputModel.statsExtra?.markRecordedRender()
        if !SKDisplay.isInSplitScreen { // 分屏场景调用有问题
            ui?.uiResponder.resign()
            DocsLogger.info("resign ui responder \(self.editorIdentity)",
                            component: LogComponents.comment)
        }
        showInputModel = inputModel
        if let docsInfo = model?.browserInfo.docsInfo {
            inputModel.update(docsInfo: docsInfo)
        } else if let gadgetInfo = gadgetInfo {
            inputModel.update(docsInfo: gadgetInfo)
        }
        initFloatCommentModuleIfNeed()
        if let topViewController = dependency?.topViewController {
            // 小程序
            showCommentModule(topViewController, inputModel)
        } else {
            self.topMostOfBrowserVCWithoutDismissing { [weak self] topMost in
                guard let topMostVC = topMost,
                let self = self else {
                    DocsLogger.error("topMost is nil",
                                    component: LogComponents.comment)
                    return
                }
                DocsLogger.info("presenter by topMostVC:\(topMostVC) \(self.editorIdentity)",
                                component: LogComponents.comment)
                self.showCommentModule(topMostVC, inputModel)
            }
        }
    }
    
    func showCommentModule(_ topMost: UIViewController, _ inputModel: CommentInputModelType) {
        if commentModule?.isVisiable == false {
            commentModule?.show(with: topMost)
        }
        commentModule?.update(inputModel)
        if let minaSession = self.delegate?.minaSession {
            commentModule?.updateSession(session: minaSession)
        }
        let canCopy = model?.permissionConfig.canCopy ?? false
        commentModule?.setCaptureAllowed(canCopy)
    }
}


// MARK: - 走Web接口时
extension CommentInputService: DocsCommentDependency {
    public var businessConfig: CommentBusinessConfig {
        let style: UIModalPresentationStyle?
        if isInVideoConference, SKDisplay.phone {
            style = .custom
        } else {
            style = nil
        }
        let canShare: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            canShare = model?.permissionConfig.getPermissionService(for: .hostDocument)?.validate(operation: .manageCollaborator).allow ?? false
        } else {
            canShare = model?.permissionConfig.userPermissions?.canShare() ?? false
        }
        var config = CommentBusinessConfig(customPresentationStyle: style, canShowDarkName: canShare)
        let statisticService = model?.jsEngine.fetchServiceInstance(CommentSendStatisticService.self)
        config.sendResultReporter = statisticService?.reporter
        return config
    }

    public var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? {
        if let supportLandscape = self.model?.browserInfo.docsInfo?.inherentType.landscapeWhenEnteringVCFollow,
            supportLandscape {
            return .allButUpsideDown
        }
        return nil
    }

    public var commentDocsInfo: CommentDocsInfo {
        if let info = gadgetInfo {
            return info
        } else if let info = model?.browserInfo.docsInfo {
            return info
        } else {
            spaceAssertionFailure("docs info is nil")
            return DocsInfo(type: .docX, objToken: "")
        }
    }
    
    public func dismissCommentView() {
        commentModule?.hide()
        
    }
    
    public func keyboardChange(didTrigger event: CommentKeyboardOptions.KeyboardEvent, options: CommentKeyboardOptions, textViewHeight: CGFloat) {
        DocsLogger.info("newInput keyboardChange endFrame:\(options.endFrame), textViewHeight:\(textViewHeight) event:\(event)", component: LogComponents.comment)
        if event == .willShow, !keyboardShow { // 加上keyboardShow标记防止多次调用文档底部空白问题
            keyboardShow = true
            if let contentHeight = visibleContentHeight(with: options.endFrame) ?? webViewHeight {
                let height = contentHeight - textViewHeight
                keyboardWillShow(height: height)
            } else {
                DocsLogger.error("visibleContentHeight is nil", component: LogComponents.comment)
            }
        } else if event == .willHide {
            keyboardShow = false
            keyboardWillHide(height: webViewHeight ?? 0)
        } else if event == .didHide {
            inputViewsHeightChange(to: 0)
        }
    }
    
    public func forcePortraint(force: Bool) {
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateForceCommentPortraint.rawValue, params: ["force": force])
    }
    
    public func didCopyCommentContent() {
        PermissionStatistics.shared.reportDocsCopyClick(isSuccess: true)
    }

    public func commentWillHide() {
        
    }
}


// MARK: - 走RN接口时
extension CommentInputService: CommentRNAPIAdaperDependency {
    public var docInfo: DocsInfo? {
        return self.docsInfo
    }
    
    public func showError(msg: String) {
        let view = commentModule?.commentView.window ?? UIView()
        UDToast.showFailure(with: msg, on: view)
    }
        
}
