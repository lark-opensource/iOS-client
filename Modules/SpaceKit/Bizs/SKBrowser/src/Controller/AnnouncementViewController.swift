//
//  AnnouncementViewController.swift
//  SKBrowser
//
//  Created by huahuahu on 2018/12/13.
//  Description: 群公告

import UIKit
import LarkUIKit
import SwiftyJSON
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import RxSwift
import UniverseDesignColor
import SKInfra
import SpaceInterface

public final class AnnouncementViewController: BrowserViewController {
    public private(set) var chatID: String!
    public weak var announcementDelegate: AnnouncementDelegate?
    public override var canBulletinShow: Bool { return false }
    public override var titleUseDefaultHorizontalAlignment: Bool { return true }

    private var hasFinishedIntro = OnboardingManager.shared.hasFinished(.docGroupAnnouncementIntro)
    private var hasFinishedAutoSave = OnboardingManager.shared.hasFinished(.docGroupAnnouncementAutoSave)
    //权限管理
    let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    private var userPermissionRequest: DocsRequest<JSON>?
    private var publicRequest: DocsRequest<PublicPermissionMeta>?
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private var userPermissions: UserPermissionAbility?
    private var permissionService: UserPermissionService?
    private var isOwner = false
    private var hasEdited = false
    private var isLoading = true
    private var lastContentOffset: CGPoint?
    private var floatActionCallback: String?
    private var publishCallback: String?
    private var templateViewIsShow: Bool = false
    private var templateView: GroupNoticeTemplateSuggestView?
    private var animationPosition: CGPoint?
    public var templateHiddenCallback: String?
    //群公告模版中心插入模版后端需要的参数
    private var baseRev: Int = 0
    private var position: Int = 0
    // 当前群公告状态是否合规可发布，如果不合规，则禁用发布群公告的按钮和隐藏历史记录按钮
    var canAnnounce = true

    public override var isSupportedShowNewScene: Bool {
        false
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        editor.setChatID(chatID)
        setDefaultNavigationBar()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.editor.browserViewLifeCycleEvent.addObserver(self)
        getPermission()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DocsTracker.newLog(enumEvent: .announcementPageView, parameters: ["chat_id": chatID])
    }

    public override func updateConfig(_ config: FileConfig) {
        super.updateConfig(config)
        chatID = config.chatId
    }

    public override func fillOnboardingMaterials() {
        _fillAnnouncementOnboardingTypes()
        _fillAnnouncementOnboardingArrowDirections()
        _fillAnnouncementOnboardingHints()
    }

    public override func trackEnterDoc() {
        // track nothing in announcement
    }

    public override func keyboardDidChangeState(_ options: Keyboard.KeyboardOptions) {
        let event = options.event
        switch event {
        case .willShow:
            notifyFEKeyboardIsShow()
        default:
            break
        }
    }

    func setDefaultNavigationBar() {
        navigationBar.title = BundleI18n.SKResource.Doc_Lark_Announcement
        navigationBar.layoutAttributes.titleHorizontalAlignment = .leading
    }

    public func announcementPublish(callback: String) {
        publishCallback = callback
        readyToPublish()
    }

    @objc
    private func readyToPublish() {
        if let objToken = self.editor.docsInfo?.objToken {
            let changed = self.hasEdited
            self.announcementDelegate?.didEndEdit(
                self.docsURL.value.absoluteString,
                thumbnailUrl: self.editor.docsInfo!.thumbnailStr,
                chatId: self.chatID,
                changed: changed,
                from: self,
                syncThumbBlock: { [weak self] (observer) in
                    guard let `self` = self else { return }
                    let completeObserver = PublishSubject<Any>()
                    completeObserver.subscribe(onCompleted: { [weak self] in
                        guard let callback = self?.publishCallback else { return }
                        self?.editor.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: ["res": 1], completion: nil)
                    }).disposed(by: self.disposeBag)

                    /// 没有改动就不用重新生成缩略图
                    if !changed {
                        observer.onNext(completeObserver)
                        return
                    }
                    /// 有改动就需要重新生成缩略图
                    DocThumbnailSyncer.syncDocThumbnail(objToken: objToken) { error in
                        if let er = error {
                            observer.onError(er)
                            completeObserver.onCompleted()
                        } else {
                            observer.onNext(completeObserver)
                        }
                    }
                }
            )
        } else {
            spaceAssertionFailure("can not get objToken")
        }
    }
    
    public func announcementPublishAlert() {
        guard let docsInfo = self.editor.docsInfo else {
            DocsLogger.error("announcementPublishAlert can not get docsInfo")
            return
        }
        let barItems = self.navigationBar.trailingBarButtonItems
        let publishItemView = barItems.first(where: { $0.id == SKNavigationBar.ButtonIdentifier.publishAnnouncement })?.associatedButton
        var _targetView = publishItemView ?? barItems.first?.associatedButton
        
        guard let targetView = _targetView else {
            DocsLogger.error("announcementPublish button can not be find")
            return
        }
        let params = AnnouncementPublishAlertParams(chatId: self.chatID,
                                                    docUrl: self.docsURL.value.absoluteString,
                                                    thumbnailUrl: docsInfo.thumbnailStr,
                                                    objToken: docsInfo.objToken,
                                                    changed: self.hasEdited,
                                                    fromVc: self,
                                                    targetView: targetView)
        self.announcementDelegate?.showPublishAlert(params: params)
    }
    
  

    public override func editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        _announcementViewControllerEditorViewScrollViewDidScroll(editorViewScrollViewProxy)
    }
}

extension AnnouncementViewController: AnnouncementViewControllerBase {
    public func setAnnouncementStatus(_ canAnnounce: Bool) {
        self.canAnnounce = canAnnounce
    }
}

// MARK: - 引导
extension AnnouncementViewController {

    private func _fillAnnouncementOnboardingTypes() {
        onboardingTypes = [
            OnboardingID.docGroupAnnouncementIntro: OnboardingType.text,
            .docGroupAnnouncementAutoSave: .text
        ]
    }

    private func _fillAnnouncementOnboardingArrowDirections() {
        onboardingArrowDirections = [
            OnboardingID.docGroupAnnouncementIntro: .targetBottomEdge,
            .docGroupAnnouncementAutoSave: .targetBottomEdge
        ]
    }

    private func _fillAnnouncementOnboardingHints() {
        onboardingHints = [
            OnboardingID.docGroupAnnouncementIntro: BundleI18n.SKResource.Doc_Lark_AnnouncementSupport,
            .docGroupAnnouncementAutoSave: BundleI18n.SKResource.Doc_Lark_AnnouncementSaveGuide
        ]
    }
}



// MARK: - 提示语管理
extension AnnouncementViewController {
    private func showSupportDocIfNeeded() {
        if !hasFinishedIntro && !isInVideoConference {
            OnboardingManager.shared.showTextOnboarding(id: .docGroupAnnouncementIntro, delegate: self, dataSource: self)
            hasFinishedIntro = true
        }
    }

    private func showSupportLiveSaveIfNeeded() {
        if !hasFinishedAutoSave && !isInVideoConference {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) { [weak self] in
                guard let self = self else { return }
                OnboardingManager.shared.showTextOnboarding(id: .docGroupAnnouncementAutoSave, delegate: self, dataSource: self)
                self.hasFinishedAutoSave = true
            }
        }
    }
}

// 父控制器已经继承了 BrowserViewLifeCycleEvent
extension AnnouncementViewController {
    public func browserKeyboardDidChange(_ keyboardInfo: BrowserKeyboard) {
        if keyboardInfo.isShow == true {
            showSupportLiveSaveIfNeeded()
        }
    }

    public func browserDidHideLoading() {
        isLoading = false
        showSupportDocIfNeeded()
    }

    public func browserDidBeginEdit() {
        hasEdited = true
    }
    
}

// MARK: - 权限管理
extension AnnouncementViewController {
    private func getPermission() {
        guard let objToken = self.editor.docsInfo?.objToken, let type = editor.docsInfo?.type else { return }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let service = permissionSDK.userPermissionService(for: .document(token: objToken, type: type))
            permissionService = service
            service.updateUserPermission().subscribe().disposed(by: disposeBag)
        } else {
            permissionManager.fetchUserPermissions(token: objToken, type: type.rawValue, complete: { [weak self] (_, error) in
                guard (error as? URLError)?.errorCode != NSURLErrorCancelled else { return }
                guard error == nil, let `self` = self else {
                    DocsLogger.error("open dbvc fetch user permission error", error: error, component: LogComponents.permission)
                    return
                }
            })
        }
        
        permissionManager.fetchPublicPermissions(token: objToken, type: type.rawValue) { [weak self] (permissions, error) in
            guard let permissions = permissions else {
                DocsLogger.error("open dbvc fetch public permission error", error: error, component: LogComponents.permission)
                return
            }
            self?.isOwner = permissions.isOwner
        }
    }

    var canEdit: Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            guard let permissionService else { return false }
            return permissionService.validate(operation: .edit).allow
        } else {
            guard
                let objToken = self.editor.docsInfo?.objToken,
                let typeValue = self.editor.docsInfo?.type.rawValue
            else { return false }
            return permissionManager.isUserEditable(for: objToken, type: typeValue).editable
        }
    }

    // 添加ClassName前缀以避免报错重写父类方法。
    func _announcementViewControllerEditorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        super.editorViewScrollViewDidScroll(editorViewScrollViewProxy)
        let contentOffset = editorViewScrollViewProxy.contentOffset
        guard lastContentOffset != nil else {
            lastContentOffset = contentOffset
            return
        }
        guard lastContentOffset!.y != contentOffset.y else { return }
        let isScrollUp = contentOffset.y > lastContentOffset!.y
        lastContentOffset = contentOffset
    }
}


extension AnnouncementViewController: GroupNoticeTemplateSuggestViewDelegate {
    public func showTemplateAnimation(animate: Bool = true) {
        guard let tView = templateView else { return }
        templateViewIsShow = true
        if tView.superview == nil {
            self.view.addSubview(tView)
            tView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(-view.safeAreaInsets.bottom)
                make.height.equalTo(171)
            }
        }
        self.view.bringSubviewToFront(tView)

        report()
        UIView.animate(withDuration: animate ? 0.3 : 0) {
            tView.alpha = 1
            tView.transform = .identity
        }
    }

    public func hideTemplateAnimation(animate: Bool = true) {
        guard let tView = templateView else { return }
        templateViewIsShow = false
        let position = self.animationPosition ?? .zero
        let currentY = tView.frame.minY
        UIView.animate(withDuration: animate ? 0.3 : 0) {
            tView.alpha = 0
            tView.transform = CGAffineTransform(a: 0.1, b: 0, c: 0, d: 0.1, tx: position.x * 0.1, ty: position.y - currentY)
        }
    }

    public func setTemplateView(params: [String: Any]) {
        guard let objToken = self.editor.docsInfo?.objToken else { return }

        let isShow = params["visible"] as? Bool ?? false
        let needAnimation = params["needAnimation"] as? Bool ?? true
        baseRev = params["baseRev"] as? Int ?? 0
        position = params["position"] as? Int ?? 0

        let x = params["x"] as? CGFloat
        let y = params["y"] as? CGFloat

        DocsLogger.info("announcement set template visible:\(isShow)")

        //将前端传过来的坐标转换为屏幕坐标
        animationPosition = self.editor.editorView.convert(CGPoint(x: x ?? 0, y: y ?? 0), to: self.view)

        guard isShow != templateViewIsShow else { return }
        if isShow {
            //显示模版中心view
            if templateView == nil {
                templateView = GroupNoticeTemplateSuggestView(objToken: objToken)
                templateView?.delegate = self
            }
            editor.bizPlugin?.editButtnAgent?.modifyEditButtonBottomOffset(height: 163 + view.safeAreaInsets.bottom)
            showTemplateAnimation(animate: needAnimation)
        } else {
            //隐藏模版中心view
            editor.bizPlugin?.editButtnAgent?.modifyEditButtonBottomOffset(height: 0)
            hideTemplateAnimation(animate: needAnimation)
        }
    }

    public func templateSuggestViewDidClickHideButton(suggestView: GroupNoticeTemplateSuggestView) {
        guard let callback = templateHiddenCallback else { return }
        editor.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: nil, completion: nil)
    }

    public func templateSuggestViewDidClickTemplate(suggestView: GroupNoticeTemplateSuggestView, atIndex: Int) {
        guard let objToken = self.editor.docsInfo?.objToken, let type = editor.docsInfo?.type, let view = templateView else { return }
        let extra = "{\"position\":\(position)}"
        let params = GroupNoticeTemplatePreviewVC.GroupNoticeParams(objType: type.rawValue, objToken: objToken, baseRev: baseRev, extra: extra)
        guard let templatePreVC = GroupNoticeTemplatePreviewVC(templates: view.templates, currentIndex: UInt(atIndex), groupNoticeDocsParams: params) else { return }
        templatePreVC.didUseTemplate = { [weak self] _ in
            guard let self = self, let url = self.editor.currentUrl else { return }
            //调用文档插入模版接口成功后，文档当前的页面并不会立刻刷新，需要reload一下
            self.editor.docsLoader?.load(url: url)
        }
        if SKDisplay.pad {
            templatePreVC.modalPresentationStyle = .formSheet
            templatePreVC.preferredContentSize = CGSize(width: 540, height: 620)
            let nav = LkNavigationController(rootViewController: templatePreVC)
            self.present(nav, animated: true, completion: nil)
        } else {
            self.navigationController?.pushViewController(templatePreVC, animated: true)
        }
    }

    ///埋点上报
    private func report() {
        guard let docsInfo = self.editor.docsInfo else { return }
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissionMask = permissionManager.getUserPermissions(for: docsInfo.objToken)
        // 文档用户权限
        let userPermission = userPermissionMask?.rawValue ?? 0
        // 文档公共权限
        let filePermission = publicPermissionMeta?.rawValue ?? ""

        var dic: [String: Any] = [:]
        dic["module"] = "none"
        dic["sub_module"] = "none"
        dic["file_id"] = DocsTracker.encrypt(id: docsInfo.objToken)
        dic["file_type"] = docsInfo.type.name
        dic["container_id"] = "none"
        dic["container_type"] = "none"
        dic["sub_file_type"] = "none"
        dic["shortcut_id"] = "none"
        dic["is_shortcut"] = "false"
        dic["app_form"] = "none"
        dic["source"] = "from_im_chat_announcement"
        dic["user_permission"] = userPermission
        dic["file_permission"] = filePermission


        DocsTracker.newLog(enumEvent: .announceTemplateViewShow, parameters: dic)
    }

    public func notifyFEKeyboardIsShow() {
        guard let callback = templateHiddenCallback else { return }
        editor.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: ["keyBoardIsShow": true], completion: nil)
    }
}
