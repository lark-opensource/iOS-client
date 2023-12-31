//
//  SKShareViewController.swift
//  SpaceKit
//
//  Created by liweiye on 2020/7/8.
//
//  swiftlint:disable file_length type_body_length

import Foundation
import SwiftyJSON
import LinkPresentation
import EENavigator
import LarkTraitCollection
import RxSwift
import RxCocoa
import SKFoundation
import SKUIKit
import LarkUIKit
import UniverseDesignToast
import SKResource
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignToast
import FigmaKit
import LarkReleaseConfig
import SKInfra
import SpaceInterface

public final class SKShareViewController: SKWidgetViewController, CollaborationAssistViewDelegate, UINavigationControllerDelegate {

    private weak var delegate: ShareViewControllerDelegate?
    private(set) weak var router: ShareRouterAbility?
    private var accessoryView: UIView?
    //申请了开启链接分享的监听，用来退出当前页面
    private let sendRequestObserver: PublishSubject<Bool> = PublishSubject<Bool>()
    private let disposeBag = DisposeBag()
    private var source: ShareSource = .list
    private let bag = DisposeBag()
    private let adjustSettingsHandler: AdjustSettingsHandler
    var viewModel: SKShareViewModel
    private var hasStatisticsOpen: Bool = false
    private var isUnlocking: Bool = false
    private var isDismissing: Bool = false
    private weak var hostViewController: UIViewController?
    public weak var followAPIDelegate: BrowserVCFollowDelegate?
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    // 用于测量页面的加载耗时
    private let timeProfiler = SKViewTimeProfiler()
    // 监听网络请求拉取数据的事件
    private let fetchDataEvent = PublishSubject<Void>()
    // 监听网络数据回来后设置数据的事件
    private let setDataEvent = PublishSubject<Void>()
    // 用于埋点的 openType
    private var openType: String {
        let openType: String
        if self.viewModel.shareEntity.isForm {
            openType = "bitable_share_form"
        } else if self.viewModel.shareEntity.isFolder {
            openType = "folder"
        } else {
            openType = "doc"
        }
        return openType
    }
    // 用于埋点的 source
    private var trackSource: Int {
        let source: Int
        switch self.source {
        case .list:
            source = 0
        case .grid:
            source = 1
        case .content:
            source = 2
        case .diyTemplate:
            source = 4
        default:
            source = 5
        }
        return source
    }

    private var fileModel: CollaboratorFileModel {
        let shareEntity = viewModel.shareEntity
        return CollaboratorFileModel(objToken: shareEntity.objToken,
                                     docsType: shareEntity.type,
                                     title: shareEntity.title,
                                     isOWner: shareEntity.isOwner,
                                     ownerID: shareEntity.ownerID,
                                     displayName: shareEntity.displayName,
                                     spaceID: shareEntity.spaceID,
                                     folderType: shareEntity.folderType,
                                     tenantID: shareEntity.tenantID,
                                     createTime: shareEntity.createTime,
                                     createDate: shareEntity.createDate,
                                     creatorID: shareEntity.creatorID,
                                     wikiV2SingleContainer: shareEntity.wikiV2SingleContainer,
                                     spaceSingleContainer: shareEntity.spaceSingleContainer,
                                     enableTransferOwner: shareEntity.enableTransferOwner,
                                     bitableShareEntity: shareEntity.bitableShareEntity,
                                     formMeta: shareEntity.formShareFormMeta)
    }

    private var blurView: SKBlurEffectView = {
        let view = SKBlurEffectView()
        view.set(cornerRadius: 12, corners: .top)
        return view
    }()

    private(set) lazy var assistView: CollaborationAssistView = {
        let view = CollaborationAssistView(viewModel.shareEntity,
                                           accessory: accessoryView,
                                           delegate: self,
                                           source: source,
                                           viewModel: self.viewModel)
        view.viewModel.isNewForm = isNewForm
        view.viewModel.isNewFormUser = isNewFormUser
        view.viewModel.formEditable = formEditable
        return view
    }()
    
    public func updateNoticeMe(value: Bool) {
        assistView.formsNotifyMeView.accessSwitch.isOn = value
    }
    
    private lazy var reporter: CollaboratorStatistics = {
        let shareEntity = viewModel.shareEntity
        let info = CollaboratorAnalyticsFileInfo(fileType: shareEntity.type.name, fileId: shareEntity.objToken)
        let obj = CollaboratorStatistics(docInfo: info, module: source.rawValue)
        return obj
    }()
    
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    public var popoverDisappearBlock: (() -> Void)?
    
    public var isNewForm = false
    public var isNewFormUser = false
    public var formEditable: Bool?
    
    public init(_ shareEntity: SKShareEntity,
                delegate: ShareViewControllerDelegate? = nil,
                router: ShareRouterAbility? = nil,
                source: ShareSource,
                bizParameter: SpaceBizParameter? = nil,
                isInVideoConference: Bool = false,
                followAPIDelegate: BrowserVCFollowDelegate? = nil) {
        self.timeProfiler.record(with: .begin)
        self.viewModel = SKShareViewModel(shareEntity: shareEntity,
                                          bizParameter: bizParameter,
                                          isInVideoConference: isInVideoConference)
        self.source = source
        self.accessoryView = delegate?.requestDisplayShareViewAccessory()
        self.delegate = delegate
        self.router = router
        self.source = source
        self.adjustSettingsHandler = AdjustSettingsHandler(token: shareEntity.objToken, type: shareEntity.type, isSpaceV2: viewModel.shareEntity.spaceSingleContainer, isWiki: viewModel.shareEntity.wikiV2SingleContainer, followAPIDelegate: followAPIDelegate)
        self.followAPIDelegate = followAPIDelegate
        super.init(contentHeight: 300)
    }
    
    deinit {
        popoverDisappearBlock?()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        updateContentViewHeight()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateContentViewHeight()
        timeProfiler.record(with: .appear)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        hostViewController = presentingViewController
        setupView()
        addObserver()
        requestDocBizMeta()
        fetchPermissionsAndCollaborators()
        addNotification()
        requestFormShareMeta()
        requestBitableShareMeta()
        timeProfiler.record(with: .didLoad)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundView.setCustomCorner(byRoundingCorners: [.topLeft, .topRight], radii: 8)
        assistView.setScrollContentSize()
    }
    
    override public func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        super.dismiss(animated: flag, completion: completion)
        delegate?.requestExist(controller: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func resizeForIPad(realHeight: CGFloat) {
        self.navigationController?.preferredContentSize = CGSize(width: 375, height: realHeight)
        dismissButton.backgroundColor = UIColor.ud.N00
    }
    
    @objc
    func handleReceiveShareLinkEditUpdateNotification() {
        DocsLogger.info("receive share link update notify")
        if viewModel.shareEntity.bitableShareEntity?.meta?.isPublicPermissionToBeSet == true {
            DocsLogger.info("isPublicPermissionToBeSet confirm, updating meta...")
            requestBitableShareMeta() {
                DocsLogger.info("isPublicPermissionToBeSet confirm, update meta finish")
                self.fetchPermissionsAndCollaborators()
            }
            return
        }
        fetchPermissionsAndCollaborators()
    }
    
    @objc
    func handleRefreshCollaboratorsNotification() {
        fetchPermissionsAndCollaborators()
    }
    
    public func didChangeStatusBarOrientation(to newOrentation: UIInterfaceOrientation) {
        guard SKDisplay.phone, newOrentation != .unknown else { return }
        updateContentViewHeight()
        assistView.didChangeStatusBarOrientation(to: newOrentation)
    }
    
    public override func onDismissButtonClick() {
        self.isDismissing = true
        guard self.navigationController == nil else {
            animatedView(isShow: false, animate: true) { [weak self] in
                self?.isDismissing = false
            }
            return
        }
        self.dismiss(animated: true) { [weak self] in
            self?.isDismissing = false
        }
    }

    private func setupView() {
        contentView.backgroundColor = .clear
        assistView.backgroundColor = .clear
        backgroundView.backgroundColor = .clear
        assistView.updateCloseButton(isHidden: self.modalPresentationStyle == .popover)
        blurView.updateMaskColor(isPopover: self.modalPresentationStyle == .popover)
        if SKDisplay.pad, modalPresentationStyle == .popover {
            view.insertSubview(blurView, belowSubview: backgroundView)
            blurView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            backgroundView.insertSubview(blurView, belowSubview: contentView)
            blurView.snp.makeConstraints { make in
                make.top.equalTo(contentView)
                make.bottom.left.right.equalToSuperview()
            }
        }
        contentView.addSubview(assistView)
        assistView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(contentView.safeAreaLayoutGuide)
        }
        self.assistView.setupView()
        if fileModel.docsType == .docX || fileModel.docsType == .mindnote {
            self.assistView.updateUI()
        }
        updateContentViewHeight()
    }
    
    private func addNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleReceiveShareLinkEditUpdateNotification),
                                               name: Notification.Name.Docs.publicPermissonUpdate,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRefreshCollaboratorsNotification),
                                               name: Notification.Name.Docs.refreshCollaborators,
                                               object: nil)
    }
    
    private func addObserver() {
        //监听Ask Owner开启链接共享页面的退出，用来退出本页面
        self.sendRequestObserver.subscribe { [weak self] _ in
            guard let `self` = self else { return }
            self.dismiss(animated: false, completion: nil)
        }.disposed(by: self.disposeBag)
        if SKDisplay.pad || supportedInterfaceOrientations == .portrait {
            RootTraitCollection.observer
                .observeRootTraitCollectionWillChange(for: view)
                .observeOn(MainScheduler.instance)
                .filter { change in
                    change.old.horizontalSizeClass != change.new.horizontalSizeClass ||
                    change.old.verticalSizeClass != change.new.verticalSizeClass
                }
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.dismiss(animated: false, completion: nil)
                })
                .disposed(by: disposeBag)
        }
        
        // fetchUserAndPublicPermissions、requestCollaborators和requestFormShareMeta都会发出next事件，take(3)操作符只取序列中前3个next事件
        // complete事件会伴随第3个next一同产生，只需监听complete事件就可以知道第3个next事件的发生时机
        // complete事件还可以使可观测序列不再发送next，防止埋点重复上报
        fetchDataEvent.take(3).subscribe(onNext: nil, onError: { [weak self] error in
            guard let self = self else { return }
            let isMinutes = self.fileModel.docsType == .minutes
            let errorCode = (error as NSError).code
            self.viewModel.permStatistics?.reportPermissionPerformanceShareOpenFinish(isSuccessful: false,
                                                                                      openType: self.openType,
                                                                                      isRetry: false,
                                                                                      source: self.trackSource,
                                                                                      isMinutes: isMinutes,
                                                                                      errorCode: errorCode)
        }, onCompleted: { [weak self] in
            self?.timeProfiler.record(with: .fetchData)
        }).disposed(by: disposeBag)
        // 同上
        setDataEvent.take(3).subscribe(onNext: nil, onCompleted: { [weak self] in
            guard let self = self else { return }
            self.timeProfiler.record(with: .end)
            
            let t1 = Int(self.timeProfiler.getDuration(of: .begin))
            let t2 = Int(self.timeProfiler.getDuration(of: .didLoad))
            let t3 = Int(self.timeProfiler.getDuration(of: .fetchData))
            let t4 = Int(self.timeProfiler.getDuration(of: .end))
            let firstViewTime = Int(self.timeProfiler.getDuration(of: .appear))
            let costTime = Int(self.timeProfiler.getTotalDuration())
            let openType = self.openType
            let source = self.trackSource
            let isMinutes = self.fileModel.docsType == .minutes
            let context = ReportPermissionPerformanceShareOpenTime(t1: t1,
                                                                   t2: t2,
                                                                   t3: t3,
                                                                   t4: t4,
                                                                   firstViewTime: firstViewTime,
                                                                   costTime: costTime,
                                                                   openType: openType,
                                                                   isRetry: false,
                                                                   source: source,
                                                                   isMinutes: isMinutes)
            self.viewModel.permStatistics?.reportPermissionPerformanceShareOpenTime(context: context)
            
            self.viewModel.permStatistics?.reportPermissionPerformanceShareOpenFinish(isSuccessful: true,
                                                                                      openType: openType,
                                                                                      isRetry: false,
                                                                                      source: source,
                                                                                      isMinutes: isMinutes,
                                                                                      errorCode: nil)
        }).disposed(by: disposeBag)

    }

    private func requestFormShareMeta() {
        guard viewModel.shareEntity.isFormV1 else {
            fetchDataEvent.onNext(())
            setDataEvent.onNext(())
            return
        }
        assistView.showBitableMaskView(isHidden: viewModel.shareEntity.formCanShare)
        viewModel.requestFormShareMeta { [weak self] meta, error  in
            guard let self = self, let formShareMeta = meta else {
                if let error = error {
                    self?.fetchDataEvent.onError(error)
                } else {
                    self?.fetchDataEvent.onError(SKError.unknown)
                }
                return
            }
            self.fetchDataEvent.onNext(())
            self.assistView.updateFormPanel(formShareMeta)
            self.assistView.showBitableMaskView(isHidden: formShareMeta.canShare)
            self.setDataEvent.onNext(())
        }
    }
    
    private func requestBitableShareMeta(_ completion: (() -> Void)? = nil) {
        guard viewModel.shareEntity.isBitableSubShare else {
            fetchDataEvent.onNext(())
            setDataEvent.onNext(())
            completion?()
            return
        }
        viewModel.requestBitableShareMeta(completion: { [weak self] (result, code) in
            guard let self = self else {
                completion?()
                return
            }
            switch result {
            case .success(let meta):
                self.fetchDataEvent.onNext(())
                self.assistView.updateBitablePanel(meta)
                self.updateContentViewHeight()
                self.setDataEvent.onNext(())

                var trackParams = [
                    "share_type": viewModel.shareEntity.bitableSubType?.trackString ?? "",
                    "is_opened": DocsTracker.toString(value: meta.isShareOn)
                ]
                DocsTracker.newLog(enumEvent: .bitableExternalPermissionView, parameters: trackParams)
            case .failure(let error):
                self.fetchDataEvent.onError(error)
            }
            completion?()
        })
    }
    
    private func requestDocBizMeta() {
        switch fileModel.docsType {
        case .folder, .wiki, .form, .bitableSub:
            if let url = URL(string: self.viewModel.shareEntity.shareUrl), self.viewModel.shareEntity.isFromPhoenix {
                self.viewModel.shareEntity.updateShareURL(url: WorkspaceCrossRouter.redirectPhoenixURL(spaceURL: url).absoluteString)
            }
            DocsLogger.info("no need request docs biz meata")
        default:
            viewModel.fetchDocMeta(token: fileModel.objToken, type: fileModel.docsType) { [weak self] bizMeta, _ in
                guard let self = self else { return }
                if let meta = bizMeta {
                    self.viewModel.shareEntity.updateByMeta(meta: meta)
                    if let url = URL(string: self.viewModel.shareEntity.shareUrl), self.viewModel.shareEntity.isFromPhoenix {
                        self.viewModel.shareEntity.updateShareURL(url: WorkspaceCrossRouter.redirectPhoenixURL(spaceURL: url).absoluteString)
                    }
                }
            }
        }
    }
    
    private func fetchPermissionsAndCollaborators(completion: (() -> Void)? = nil) {
        guard viewModel.shareEntity.bitableShareEntity?.isAddRecordShare != true else {
            // 快捷添加记录分享中，没有协作者面板，不需要拉取协作者
            fetchDataEvent.onNext(())
            setDataEvent.onNext(())
            completion?()
            return
        }
        // 拉取用户权限和公共权限
        viewModel.fetchUserPermissionsAndPublicPermissions { [weak self] _ in
            self?.assistView.notifyFetchUserPermCompleted()
        } allCompletion: { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                DocsLogger.error("ShareViewController fetch permissions error", error: error, component: LogComponents.permission)
                self.fetchDataEvent.onError(error)
                self.handlePermissionError(error)
            } else {
                self.fetchDataEvent.onNext(())
            }
            
            self.viewModel.permStatistics?.ccmCommonParameters.update(userPermRole: self.viewModel.userPermissions?.permRoleValue, userPermissionRawValue: self.viewModel.userPermissions?.rawValue)
            self.viewModel.permStatistics?.ccmCommonParameters.update(publicPermission: self.viewModel.publicPermissions?.rawValue)
            if !self.hasStatisticsOpen {
                self.hasStatisticsOpen = true
                self.viewModel.permStatistics?.reportPermissionShareView()
            }
            self.assistView.updateUserAndPublicPermissions(userPermissions: self.viewModel.userPermissions, publicPermissions: self.viewModel.publicPermissions)
            self.updateContentViewHeight()
            self.setDataEvent.onNext(())
            completion?()
        }
        guard viewModel.shareEntity.bitableShareEntity?.isRecordShareV2 != true else {
            // 记录分享二期中，没有协作者面板，不需要拉取协作者
            fetchDataEvent.onNext(())
            setDataEvent.onNext(())
            return
        }
        // 拉取协作者信息
        self.assistView.updateManagerEntryPanelCollaborators { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .error:
                // 在分享表单中，如果未开启表单分享，那么就无法拉取协作者信息，但这种情况不算页面失败
                if self.viewModel.shareEntity.isFormV1 && !self.viewModel.shareEntity.formCanShare {
                    self.fetchDataEvent.onNext(())
                    self.setDataEvent.onNext(())
                } else if self.viewModel.shareEntity.isBitableSubShare && self.viewModel.shareEntity.bitableShareEntity?.isShareReady != true {
                    self.fetchDataEvent.onNext(())
                    self.setDataEvent.onNext(())
                } else {
                    self.fetchDataEvent.onError(SKError.unknown)
                }
            case .fetchData:
                self.fetchDataEvent.onNext(())
            case .setData:
                self.setDataEvent.onNext(())
            }
        }
    }
    
    private func handlePermissionError(_ error: Error) {
        if let erroeCode = (error as? DocsNetworkError)?.code {
            switch erroeCode {
            case .forbidden, .entityDeleted:
                self.viewModel.noPermission = true
                showToast(text: BundleI18n.SKResource.CreationMobile_ECM_shortcut_sharing_failed_NoPermission_toast, type: .failure)
            default:
                if viewModel.shareEntity.formsShareModel != nil {
                    return // 如果是新收集表分享，不进行这个报错，和安卓及前端对齐
                }
                showToast(text: BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
            }
            return
        }
    }
    
    private func updateContentViewHeight() {
        guard isDismissing == false else {
            return
        }
        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
            if self.viewModel.isDocVersion {
                contentHeight = 200
            } else {
                contentHeight = view.frame.height - 14
            }
            contentView.snp.remakeConstraints { (make) in
                make.left.right.top.equalTo(self.backgroundView.safeAreaLayoutGuide)
                make.height.equalTo(contentHeight)
            }
            backgroundView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview().inset(view.frame.width * 0.15)
                make.bottom.equalTo(0)
                make.height.equalTo(contentHeight)
            }
            assistView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            return
        }
        assistView.snp.removeConstraints()
        let width = max(view.frame.width, 375)
        let estimatedHeight = assistView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)).height
        assistView.snp.remakeConstraints { (make) in
            make.top.left.right.bottom.equalTo(contentView.safeAreaLayoutGuide)
        }
        if SKDisplay.pad, modalPresentationStyle == .popover {
            resizeForIPad(realHeight: estimatedHeight)
        }
        self.resetHeight(estimatedHeight)
    }
    // MARK: CollaborationAssistView代理,  CollaborationAssistViewDelegate
    func sharePanelConfigInfo(view: CollaborationAssistView) -> SharePanelConfigInfoProtocol? {
        return self.delegate?.sharePanelConfigInfo()
    }
    
    func openCollaboratorEditViewController(view: CollaborationAssistView,
                                            collaborators: [Collaborator],
                                            containerCollaborators: [Collaborator],
                                            singlePageCollaborators: [Collaborator]) {
        if let noPermission = self.viewModel.noPermission, noPermission == true {
            return
        }
        let shareEntity = viewModel.shareEntity
        if shareEntity.spaceSingleContainer {
            if viewModel.userPermissions == nil {
                DocsLogger.info("open CollaborationEditController failed, userPermissions is nil", component: LogComponents.permission)
                return
            }
        } else {
            //个人文件夹无需进入
            if shareEntity.isCommonFolder {
                DocsLogger.info("common folder can not enter CollaborationEditController", component: LogComponents.permission)
                return
            }
        }
        let target: DocsTracker.EventType = fileModel.isForm ? .bitableFormPermissionCollaboratorView : .permissionManagementCollaboratorView
        if let subShare = viewModel.shareEntity.bitableSubType {
            let params = ["click": "manage_collaborator",
                          "share_type": subShare.trackString,
                          "target": "ccm_bitable_external_permission_management_collaborator_view"
            ]
            DocsTracker.newLog(enumEvent: .bitableExternalPermissionClick, parameters: params)
        }
        viewModel.permStatistics?.reportPermissionShareClick(shareType: shareEntity.type, click: .manageCollaborator, target: target)
        let userPermisson = viewModel.userPermissions
        let publicPermisson = viewModel.publicPermissions
        let vc = CollaboratorEditLynxViewController(shareEntity: shareEntity,
                                                        fileModel: fileModel,
                                                        collaborators: collaborators,
                                                        containerCollaborators: containerCollaborators,
                                                        singlePageCollaborators: singlePageCollaborators,
                                                        statistics: reporter,
                                                        permStatistics: viewModel.permStatistics,
                                                        userPermission: userPermisson,
                                                        publicPermission: publicPermisson,
                                                        delegate: self,
                                                        organizationNotifyDelegate: self,
                                                        isInVideoConference: viewModel.isInVideoConference,
                                                        followAPIDelegate: followAPIDelegate)
        vc.supportOrientations = self.supportedInterfaceOrientations
        if isMyWindowRegularSizeInPad {
            dismiss(animated: false, completion: { [weak self] in
                let navVC = LkNavigationController(rootViewController: vc)
                navVC.modalPresentationStyle = .formSheet
                self?.hostViewController?.present(navVC, animated: true, completion: nil)
            })
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func openCollaboratorSearchViewController(view: CollaborationAssistView,
                                              collaborators: [Collaborator]?,
                                              lastPageLabel: String?,
                                              needActivateKeyboard: Bool,
                                              source: CollaboratorInviteSource) {
        if let noPermission = self.viewModel.noPermission, noPermission == true {
            return
        }
        let userPermisson = viewModel.userPermissions
        let publicPermisson = viewModel.publicPermissions
        viewModel.permStatistics?.reportPermissionShareClick(shareType: fileModel.docsType, click: .inviteCollaborator, target: .permissionAddCollaboratorView)
        if let subShare = viewModel.shareEntity.bitableSubType {
            let params = ["click": "invite_collaborator",
                          "share_type": subShare.trackString,
                          "target": "ccm_permission_add_collaborator_view"
            ]
            DocsTracker.newLog(enumEvent: .bitableExternalPermissionClick, parameters: params)
        }
        let viewModel = CollaboratorSearchViewModel(existedCollaborators: collaborators ?? [],
                                                    selectedItems: [],
                                                    fileModel: fileModel,
                                                    lastPageLabel: lastPageLabel,
                                                    statistics: reporter,
                                                    userPermission: userPermisson,
                                                    publicPermisson: publicPermisson,
                                                    isInVideoConference: viewModel.isInVideoConference)
        let dependency = CollaboratorSearchVCDependency(statistics: reporter,
                                                        permStatistics: self.viewModel.permStatistics,
                                                        needShowOptionBar: false)
        let uiConfig = CollaboratorSearchVCUIConfig(needActivateKeyboard: needActivateKeyboard,
                                                    source: source)
        let vc = CollaboratorSearchViewController(viewModel: viewModel,
                                                  dependency: dependency,
                                                  uiConfig: uiConfig)
        vc.supportOrientations = self.supportedInterfaceOrientations
        vc.collaboratorSearchVCDelegate = self
        vc.organizationNotifyDelegate = self
        vc.followAPIDelegate = followAPIDelegate
        let navVC = LkNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        self.present(navVC, animated: true)
    }
    
    func onRemindNotificationViewClick() {
        delegate?.onRemindNotificationViewClick(controller: self, shareToken: viewModel.shareEntity.formsShareModel?.shareToken ?? "")
    }
    
    func requestExportSnapShot(view: CollaborationAssistView) {
        delegate?.requestExportLongImage(controller: self)
    }
    
    func requestSlideExport(view: CollaborationAssistView) {
        delegate?.requestSlideExport(controller: self)
    }
    
    func shouldDisplaySnapShotItem() -> Bool {
        return delegate?.shouldDisplaySnapShotItem() ?? false
    }
    
    func shouldDisplaySlideExport() -> Bool {
        return delegate?.shouldDisplaySlideExport() ?? false
    }

    func openShareLinkEditViewController(view: UIView,
                                         chosenType: ShareLinkChoice?) {
        if let noPermission = self.viewModel.noPermission, noPermission == true {
            return
        }
        guard self.viewModel.isLinkShareEnabled() else {
            DocsLogger.info("permission setting is disable")
            showToast(text: BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_ShareInheritSource_Tooltip
, type: .tips)
            return
        }
        reportClickLinkshareSetting()
        let action: SharePageClickAction = fileModel.isForm ? .bitableLimitSet : .shareLink
        let target: DocsTracker.EventType = fileModel.isForm ? .bitableFormLimitSetView : .permissionShareEncryptedLinkView
        viewModel.permStatistics?.reportPermissionShareClick(shareType: fileModel.docsType, click: action, target: target)
        if let subShare = viewModel.shareEntity.bitableSubType {
            let params = ["click": "limit_set",
                          "share_type": subShare.trackString,
                          "target": "ccm_bitable_external_share_limit_set_view"
            ]
            DocsTracker.newLog(enumEvent: .bitableExternalPermissionClick, parameters: params)
        }
      
        guard let publicPermissions = viewModel.publicPermissions else {
            spaceAssertionFailure("publicPermissions is nil")
            return
        }
        guard let userPermissions = viewModel.userPermissions else {
            spaceAssertionFailure("userPermissions is nil")
            return
        }
        let vc: UIViewController
        let ifNewFormBiz = isNewForm || isNewFormUser
        if UserScopeNoChangeFG.PLF.lynxLinkShareEnable {
            let linkShareLynxVC = LinkShareLynxViewController(shareEntity: viewModel.shareEntity,
                                             userPermission: userPermissions,
                                             permStatistics: viewModel.permStatistics,
                                             needCloseBarItem: isMyWindowRegularSizeInPad,
                                             openPasswordShare: false,
                                             followAPIDelegate: followAPIDelegate,
                                             isNewLarkForm: ifNewFormBiz)
            linkShareLynxVC.supportOrientations = self.supportedInterfaceOrientations
            vc = linkShareLynxVC

        } else {
            let shareLinkVC = ShareLinkEditViewController(shareEntity: viewModel.shareEntity,
                                                 userPermisson: viewModel.userPermissions,
                                                 publicPermissionMeta: publicPermissions,
                                                 chosenType: chosenType,
                                                 shareSource: source,
                                                 permStatistics: viewModel.permStatistics,
                                                 needCloseBarItem: isMyWindowRegularSizeInPad)
            shareLinkVC.isNewForm = ifNewFormBiz
            shareLinkVC.sendRequestObserver = self.sendRequestObserver
            vc = shareLinkVC
        }

        if isMyWindowRegularSizeInPad {
            dismiss(animated: false, completion: { [weak self] in
                vc.modalPresentationStyle = .formSheet
                self?.hostViewController?.present(vc, animated: true, completion: nil)
            })
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func openShareLink(enablePasswordShare: Bool) {
        if let noPermission = self.viewModel.noPermission, noPermission == true {
            return
        }
        guard let publicPermissions = viewModel.publicPermissions else {
            spaceAssertionFailure("publicPermissions is nil")
            return
        }
        guard let userPermissions = viewModel.userPermissions else {
            spaceAssertionFailure("userPermissions is nil")
            return
        }
        let vc = LinkShareLynxViewController(shareEntity: viewModel.shareEntity,
                                             userPermission: userPermissions,
                                             permStatistics: viewModel.permStatistics,
                                             needCloseBarItem: isMyWindowRegularSizeInPad,
                                             openPasswordShare: enablePasswordShare,
                                             followAPIDelegate: followAPIDelegate,
                                             isNewLarkForm: false)
        if hostViewController?.isMyWindowRegularSizeInPad == true {
            if enablePasswordShare {
                vc.modalPresentationStyle = .formSheet
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                    self.hostViewController?.present(vc, animated: true, completion: nil)
                }
            } else {
                dismiss(animated: false, completion: { [weak self] in
                    vc.modalPresentationStyle = .formSheet
                    self?.hostViewController?.present(vc, animated: true, completion: nil)
                })
            }
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func openPublicPermissionViewController(view: CollaborationAssistView) {
        if let noPermission = self.viewModel.noPermission, noPermission == true {
            return
        }
        guard self.viewModel.isPermissionSettingEnabled() else {
            DocsLogger.info("permission setting is disable")
            showToast(text: BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_PermInheritSource_Tooltip
, type: .tips)
            return
        }
        reportClickPermissionSetting()
        viewModel.permStatistics?.reportPermissionShareClick(shareType: fileModel.docsType, click: .set, target: .permissionSetView)
        //视频会视频时Navigartor from不能为nil，否则会push在下面的window上
        let shareEntity = viewModel.shareEntity
        let needCloseBarItem = isMyWindowRegularSizeInPad && !viewModel.isInVideoConference
        let fileModel = PublicPermissionFileModel(objToken: shareEntity.objToken,
                                                  wikiToken: shareEntity.wikiInfo?.wikiToken,
                                                  type: shareEntity.type,
                                                  fileType: shareEntity.fileType,
                                                  ownerID: shareEntity.ownerID,
                                                  tenantID: shareEntity.tenantID,
                                                  createTime: shareEntity.createTime,
                                                  createDate: shareEntity.createDate,
                                                  createID: shareEntity.creatorID,
                                                  wikiV2SingleContainer: shareEntity.wikiV2SingleContainer,
                                                  wikiType: shareEntity.wikiInfo?.docsType,
                                                  spaceSingleContainer: shareEntity.spaceSingleContainer)
        guard let dlpUrl = try? HelpCenterURLGenerator.generateURL(article: .dlpBannerHelpCenter).absoluteString else {
            DocsLogger.error("failed to generate helper center URL when showPublicPermissionSettingVC from dlpBannerHelpCenter")
            return
        }
        var vc: UIViewController
        //2.0文件夹支持统一管控需求
        if shareEntity.isv2Folder ||
            ShareFeatureGating.newPermissionSettingEnable(type: shareEntity.type.rawValue) {
            let permissonVC = PublicPermissionLynxController(token: fileModel.objToken,
                                                             type: fileModel.type,
                                                             isSpaceV2: fileModel.spaceSingleContainer,
                                                             isWikiV2: shareEntity.wikiV2SingleContainer,
                                                             needCloseButton: needCloseBarItem,
                                                             fileModel: fileModel,
                                                             permStatistics: viewModel.permStatistics,
                                                             dlpDialogUrl: dlpUrl,
                                                             followAPIDelegate: followAPIDelegate)
            permissonVC.supportOrientations = self.supportedInterfaceOrientations
            vc = permissonVC
        } else {
            let permissonVC = PublicPermissionViewController(fileModel: fileModel,
                                                             needCloseBarItem: needCloseBarItem,
                                                             permStatistics: viewModel.permStatistics)
            permissonVC.supportOrientations = self.supportedInterfaceOrientations
            vc = permissonVC
        }
        
        if needCloseBarItem {
            dismiss(animated: false, completion: { [weak self] in
                let navVC = LkNavigationController(rootViewController: vc)
                navVC.modalPresentationStyle = .formSheet
                self?.hostViewController?.present(navVC, animated: true, completion: nil)
            })
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func shouldDisplayCopyLinkAlertSheet(view: UIView, iphoneAlert: UIViewController, ipaAlert: UIViewController) {
        let forceNeedPopover = SKDisplay.pad
        let toViewController: UIViewController = forceNeedPopover ? ipaAlert : iphoneAlert
        if forceNeedPopover {
            toViewController.modalPresentationStyle = .popover
            toViewController.popoverPresentationController?.sourceView = view
            toViewController.popoverPresentationController?.sourceRect = view.bounds
            toViewController.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            toViewController.popoverPresentationController?.permittedArrowDirections = .down
        }
        self.present(toViewController, animated: true, completion: nil)
    }
    
    func currentPresentationStyle() -> UIModalPresentationStyle {
        return self.modalPresentationStyle
    }

    // TODO: 整改对外分享逻辑
    func didClickShareLinkToExternal(view: UIView, completion: (() -> Void)?) {
        if viewModel.shareEntity.spaceSingleContainer, viewModel.publicPermissions?.externalAccessEnable == false {
            let text = fileModel.isFolder
                ? BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_Enable_folder_toast
                : BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_Enable_toast
            showToast(text: text, type: .tips)
            return
        }
        let linkShareEntity = (ShareFeatureGating.newPermissionSettingEnable(type: viewModel.shareEntity.type.rawValue)
                                    || fileModel.isV2Folder)
            ?  LinkShareEntity.anyoneCanRead.rawValue + 1
            : LinkShareEntity.anyoneCanRead.rawValue 
        viewModel.updatePublicPermissions(linkShareEntity: linkShareEntity) { [weak self] success, _, json in
            if success == true {
                self?.fetchPermissionsAndCollaborators()
            } else {
                self?.handleError(json: json, inputText: BundleI18n.SKResource.Doc_Facade_SetFailed)
            }
            completion?()
        }
    }


    private func handleError(json: JSON?, inputText: String) {
        guard let json = json else {
            self.showToast(text: inputText, type: .failure)
            return
        }
        let code = json["code"].intValue
        if let errorCode = ExplorerErrorCode(rawValue: code) {
            let errorEntity = ErrorEntity(code: errorCode, folderName: "")
            self.showToast(text: errorEntity.wording, type: .failure)
        } else {
            self.showToast(text: inputText, type: .failure)
        }
    }


    func didClickShareToByteDanceMoments(_ url: URL) {
        if let hostViewController = hostViewController {
            Navigator.shared.open(url, from: hostViewController)
        }
    }
    
    func requestHostViewController() -> UIViewController? {
        return self.hostViewController
    }

    func requestFollowAPIDelegate() -> BrowserVCFollowDelegate? {
        return followAPIDelegate
    }

    func requestShareToLarkServiceFromViewController() -> UIViewController? {
        if let bitableSubType = viewModel.shareEntity.bitableSubType {
            let params = ["click": "share_lark",
                          "share_type": bitableSubType.trackString,
                          "target": "ccm_permission_share_lark_view"
            ]
            DocsTracker.newLog(enumEvent: .bitableExternalPermissionClick, parameters: params)
        }
        return delegate?.requestShareToLarkServiceFromViewController()
    }

    
    func requestDisplayUserProfile(userId: String, fileName: String?) {
        let params = ["type": fileModel.docsType.rawValue]
        HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: fileName, fromVC: self, params: params))
    }
    
    func didClickRecoverButton(view: CollaborationAssistView) {
        if isUnlocking {
            DocsLogger.info("unlockPermission is true")
            return
        }
        viewModel.permStatistics?.reportPermissionShareClick(shareType: fileModel.docsType, click: .restore, target: .lockRestoreView)
        showRecoverPermisionLockAlert { [weak self] in
            guard let self = self else { return }
            self.unlockPermission()
        }
    }
    func didClickBitablePanelAccessSwitch(flag: Bool, callback: @escaping () -> ()) {
        if viewModel.shareEntity.isFormV1 {
            updateFormShareMeta(flag)
            callback()
        } else if viewModel.shareEntity.isBitableSubShare {
            updateBitableShareFlag(flag, callback: callback)
            let params = ["click": flag ? "open" : "close",
                          "share_type": viewModel.shareEntity.bitableSubType?.trackString
            ]
            DocsTracker.newLog(enumEvent: .bitableExternalPermissionClick, parameters: params)
        } else {
            spaceAssertionFailure()
            DocsLogger.error("A click occurred in non-bitable mode")
            callback()
        }
        
    }
    
    func didClickBitableAdPermPanel() {
        guard let data = viewModel.shareEntity.bitableAdPermInfo, data.isPro else {
            spaceAssertionFailure()
            DocsLogger.error("ad perm should not show due to ad perm is off")
            return
        }
        guard viewModel.userPermissions?.isFA == true else {
            spaceAssertionFailure()
            DocsLogger.error("ad perm cannot enter due to not FA")
            return
        }
        DocsLogger.info("share panel request enter ad perm settings panel")
        viewModel.permStatistics?.reportPermissionShareClick(
            shareType: .bitable,
            click: .bitableAdPermSetting,
            target: .ccmBitablePremiumPermissionSettingView
        )
        delegate?.onBitableAdPermPanelClick(data)
    }
    
    public func updateBitableAdPermBridgeData(_ data: BitableBridgeData) {
        viewModel.shareEntity.bitableAdPermInfo = data
        assistView.updateBitableAdPermBridgeData(data)
    }

// MARK: form相关
    private func updateFormShareMeta(_ flag: Bool) {
        viewModel.permStatistics?.reportPermissionShareClick(shareType: fileModel.docsType, click: flag ? .openBitable : .closeBitable, target: .noneTargetView, hasCover: fileModel.formMeta?.hasCover)
        viewModel.updateFormShareMeta(flag) { [weak self] (success) in
            guard let self = self else { return }
            guard success else {
                self.showToast(text: BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                return
            }
            if UserScopeNoChangeFG.ZYS.formSupportFormula, flag, let tip = self.viewModel.shareEntity.formsCallbackBlocks.formShareSuccessTip() {
                self.showToast(text: tip, type: .tips)
            }
            guard let formMeta = self.viewModel.shareEntity.formShareFormMeta else { return }
            self.assistView.updateFormPanel(formMeta)
            self.assistView.showBitableMaskView(isHidden: formMeta.canShare)
            if formMeta.flag {
                self.fetchPermissionsAndCollaborators()
            }
        }
    }
    
    /// Bitable 分享开关 value 更新
    private func updateBitableShareFlag(_ flag: Bool, callback: @escaping () -> ()) {
        viewModel.updateBitableShareFlag(flag) { [weak self] (error) in
            callback()
            guard let self = self else {
                return
            }
            guard error == nil else {
                DocsLogger.error("updateBitableShareFlag failed", error: error)
                if UserScopeNoChangeFG.ZYS.baseRecordShareV2 {
                    if flag {
                        let params = ["click": "share_failed",
                                      "share_type": self.viewModel.shareEntity.bitableSubType?.trackString
                        ]
                        DocsTracker.newLog(enumEvent: .bitableExternalPermissionClick, parameters: params)
                    }
                }
                if let error = error as? NSError, error.code == 800004000 {
                    // 对于资源未准备好的场景，进行特定的提示
                    self.showToast(text: BundleI18n.SKResource.Bitable_Common_UnableToPerformAction_Common, type: .failure)
                } else if flag {
                    self.showToast(text: BundleI18n.SKResource.Bitable_Share_UnableToCreateSharingLink_Toast, type: .failure)
                } else {
                    self.showToast(text: BundleI18n.SKResource.Bitable_Share_UnableToCloseSharing_Toast, type: .failure)
                }
                return
            }
            let isFormShare = self.viewModel.shareEntity.isForm
            if isFormShare, UserScopeNoChangeFG.ZYS.formSupportFormula, flag, let tip = self.viewModel.shareEntity.formsCallbackBlocks.formShareSuccessTip() {
                self.showToast(text: tip, type: .tips)
            }
            guard let meta = self.viewModel.shareEntity.bitableShareEntity?.meta else {
                DocsLogger.warning("updateBitableShareFlag finish with nil meta")
                return
            }
            self.assistView.updateBitablePanel(meta)
            self.updateContentViewHeight()
            if meta.flag == .open {
                self.fetchPermissionsAndCollaborators()
            }
        }
    }

// MARK: 权限解锁相关
    // 解锁
    private func unlockPermission() {
        isUnlocking = true
        viewModel.unlockPermission { [weak self] (success) in
            guard let self = self else { return }
            if success {
                self.fetchPermissionsAndCollaborators { [weak self] in
                    self?.isUnlocking = false
                }
                self.assistView.updateManagerEntryPanelCollaborators()
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Wiki_Restored_Toast, type: .success)
            } else {
                self.isUnlocking = false
                let text = self.viewModel.shareEntity.wikiV2SingleContainer
                    ? BundleI18n.SKResource.CreationMobile_Wiki_CannotRestore_Toast
                    : BundleI18n.SKResource.CreationMobile_ECM_RestoreFailToast
                self.showToast(text: text, type: .failure)
            }
        }
    }
    
    // 解锁提示弹窗
    private func showRecoverPermisionLockAlert(completion: (() -> Void)?) {
        viewModel.permStatistics?.reportLockRestoreView()
        let content = viewModel.shareEntity.isFolder
        ? BundleI18n.SKResource.CreationMobile_ECM_PermissionChangeDesc
        : BundleI18n.SKResource.CreationMobile_Wiki_Permission_RestoreInherit_Placeholder
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_Wiki_Permission_ChangePermission_Title)
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: { [weak self] in
            self?.viewModel.permStatistics?.reportLockRestoreAlertClick(click: .cancel, target: .noneTargetView)
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
            self?.viewModel.permStatistics?.reportLockRestoreAlertClick(click: .confirm, target: .noneTargetView)
            completion?()
        })
        present(dialog, animated: true, completion: nil)
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return CustomPushAnimated()
        } else if operation == .pop {
            return CustomPopAnimated()
        }
        return nil
    }
    
    func didClickClose() {
        if SKDisplay.pad && modalPresentationStyle == .popover {
            dismiss(animated: true, completion: nil)
        } else {
            onDismissButtonClick()
        }
    }
    
    func didClicked(type: ShareAssistType) {
        if viewModel.shareEntity.isBitableSubShare {
            var shareType = ""
            switch type {
            case .weibo:
                shareType = "share_weibo"
            case .qq:
                shareType = "share_qq"
            case .wechat:
                shareType = "share_wechat"
            case .wechatMoment:
                shareType = "share_wechat_moments"
            case .qrcode:
                shareType =  viewModel.shareEntity.bitableSubType == .record ? "share_qrcode" : "click_qrcode"
            default:
                break
            }
            if !shareType.isEmpty {
                let params = ["click": shareType,
                              "share_type": viewModel.shareEntity.bitableSubType?.trackString,
                              "target": "none"
                ]
                DocsTracker.newLog(enumEvent: .bitableExternalPermissionClick, parameters: params)
            }
        }
        delegate?.didShareViewClicked(assistType: type)
    }
    
    func didClickCopyLink() {
        if SKDisplay.pad && modalPresentationStyle == .popover {
            dismiss(animated: true, completion: nil)
        } else {
            onDismissButtonClick()
        }
        if viewModel.shareEntity.isBitableSubShare {
            let params = ["click": "copy_link",
                          "share_type": viewModel.shareEntity.bitableSubType?.trackString
            ]
            DocsTracker.newLog(enumEvent: .bitableExternalPermissionClick, parameters: params)
        }
    }

    func didClickCopyPasswordLink(enablePasswordShare: Bool) {
        let topVC: UIViewController?
        if SKDisplay.pad && modalPresentationStyle == .popover {
            topVC = self.hostViewController
            dismiss(animated: true, completion: nil)
        } else {
            topVC = self
        }

        adjustSettingsHandler.toAdjustSettingsIfEnabled(sceneType: .passwordShare, topVC: topVC) { status in
            switch status {
            case .success:
                self.openShareLink(enablePasswordShare: true)
            case .disabled:
                let publicPermissions = self.viewModel.publicPermissions
                if publicPermissions?.hasLinkPassword == true {
                    self.openShareLink(enablePasswordShare: false)
                } else if publicPermissions?.linkShareEntityV2 == .anyoneCanRead || publicPermissions?.linkShareEntityV2 == .anyoneCanEdit {
                    self.openShareLink(enablePasswordShare: true)
                } else {
                    self.showToast(text: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure)
                }

            default: break
            }
        }
    }

    func didClickLearnMoreButton() {
        DocsLogger.info("didClickLearnMoreButton")
        do {
            let urlString = try HelpCenterURLGenerator.generateURL(article: .learnMoreHelpCenter).absoluteString
            if var urlComponents = URLComponents(string: urlString) {
                if let domain = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.bitableShareNoticeLearnMoreDomain) {
                    urlComponents.host = domain
                } else {
                    DocsLogger.error("get bitable_share_notice_learn_more_domain error")
                }
            } else {
                DocsLogger.error("url init error, url: \(urlString)")
            }
            if let url = URL(string: urlString) {
                Navigator.shared.open(url, from: self)
            } else {
                DocsLogger.error("url init error, url: \(urlString)")
            }
        } catch {
            DocsLogger.error("failed to generate helper center URL when didClickLearnMoreButton from coverHelpCenter", error: error)
        }
    }

    func requestShareToOtherApp(view: CollaborationAssistView, activityViewController: UIViewController?) {
        guard let activityViewController = activityViewController else { return }
        self.dismiss(animated: false, completion: nil)

        func toOtherApp(sourceView: UIView?, sourceRect: CGRect, permittedArrowDirections: UIPopoverArrowDirection) {
            let flag = self.router?.shareRouterToOtherApp(activityViewController) ?? false
            if !flag {
                // 默认
                if activityViewController.modalPresentationStyle == .popover {
                    activityViewController.popoverPresentationController?.backgroundColor = UDColor.bgFloat
                    activityViewController.popoverPresentationController?.sourceView = sourceView
                    activityViewController.popoverPresentationController?.sourceRect = sourceRect
                    activityViewController.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
                }
                self.hostViewController?.present(activityViewController, animated: true, completion: nil)
            }
        }
        let sourceView = self.popoverPresentationController?.sourceView
        let sourceRect = self.popoverPresentationController?.sourceRect ?? .zero
        let permittedArrowDirections = self.popoverPresentationController?.permittedArrowDirections ?? .any
        
        adjustSettingsHandler.toAdjustSettingsIfEnabled(sceneType: .externalShare, topVC: hostViewController) { status in
            switch status {
            case .success:
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                    toOtherApp(sourceView: sourceView, sourceRect: sourceRect, permittedArrowDirections: permittedArrowDirections)
                }
            case .disabled:
                toOtherApp(sourceView: sourceView, sourceRect: sourceRect, permittedArrowDirections: permittedArrowDirections)
            default: break
            }
        }
    }
}

class CustomPushAnimated: NSObject {
    
}

extension CustomPushAnimated: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toViewController: UIViewController? = transitionContext.viewController(forKey: .to)
        let fromViewController: UIViewController? = transitionContext.viewController(forKey: .from)
        
        guard let toView = toViewController?.view,
              let fromView = fromViewController?.view else { return }
        transitionContext.containerView.addSubview(toView)
        let originalToFrame = toView.frame
        let originalFromFrame = fromView.frame
        toView.frame = CGRect(x: originalToFrame.width, y: originalToFrame.origin.y, width: originalToFrame.width, height: originalToFrame.height)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toView.frame = CGRect(x: 0, y: originalToFrame.origin.y, width: originalToFrame.width, height: originalToFrame.height)
            fromView.frame = CGRect(x: -originalFromFrame.width, y: originalFromFrame.origin.y, width: originalFromFrame.width, height: originalFromFrame.height)
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

class CustomPopAnimated: NSObject {
    
}

extension CustomPopAnimated: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController: UIViewController? = transitionContext.viewController(forKey: .from)
        let toViewController: UIViewController? = transitionContext.viewController(forKey: .to)
        
        guard let fromView = fromViewController?.view,
              let toView = toViewController?.view else { return }
        transitionContext.containerView.insertSubview(toView, belowSubview: fromView)
        let originalToFrame = toView.frame
        let originalFromFrame = fromView.frame
        fromView.frame = CGRect(x: 0, y: originalFromFrame.origin.y, width: originalFromFrame.width, height: originalFromFrame.height)
        toView.frame = CGRect(x: -originalToFrame.width, y: originalToFrame.origin.y, width: originalToFrame.width, height: originalToFrame.height)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromView.frame = CGRect(x: fromView.frame.width, y: originalFromFrame.origin.y, width: originalFromFrame.width, height: originalFromFrame.height)
            toView.frame = CGRect(x: 0, y: originalToFrame.origin.y, width: originalToFrame.width, height: originalToFrame.height)
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

extension SKShareViewController: CollaboratorSearchViewControllerDelegate {
    
    public func dissmissSharePanel(animated: Bool, completion: (() -> Void)?) {
        if Display.phone {
            UIView.performWithoutAnimation {
                presentedViewController?.dismiss(animated: animated, completion: completion)
                guard self.navigationController == nil else {
                    self.animatedView(isShow: false, animate: false, compltetion: nil)
                    return
                }
                self.dismiss(animated: false, completion: nil)
            }
        } else {
            presentingViewController?.dismiss(animated: animated, completion: completion)
        }
    }
}

extension SKShareViewController: CollaboratorEditDelegate {
    public func updateManagerEntryPanelCollaborators() {
        fetchPermissionsAndCollaborators()
        assistView.updateManagerEntryPanelCollaborators()
    }
    
    public func dissmissSharePanelFromCollaboratorEdit(animated: Bool, completion: (() -> Void)?) {
        presentingViewController?.dismiss(animated: animated, completion: completion)
    }
    
    public func updateFileOwnerId(newOwnerId: String) {
        fileModel.updateOwnerID(newOwnerID: newOwnerId)
        viewModel.shareEntity.updateOwnerID(newOwnerID: newOwnerId)
    }
}

extension SKShareViewController: OrganizationInviteNotifyDelegate {
    public func dismissSharePanelAndNotify(completion: (() -> Void)?) {
        presentingViewController?.dismiss(animated: false, completion: completion)
    }
    func dismissInviteCompletion(completion: (() -> Void)?) {
        let title = BundleI18n.SKResource.LarkCCM_Workspace_InviteOrg_MuteNotice_Content_Header
        let content = BundleI18n.SKResource.LarkCCM_Workspace_InviteOrg_MuteNotice_Content_Popup
        let buttonTitle = BundleI18n.SKResource.LarkCCM_Workspace_InviteOrg_MuteNotice_GotIt_Button
        let dialog = UDDialog()
        dialog.setTitle(text: title)
        dialog.setContent(text: content)
        dialog.addPrimaryButton(text: buttonTitle, dismissCompletion: {
            dialog.dismiss(animated: false) { [weak self] in
                dialog.dismiss(animated: false)
                completion?()
            }
        })
        viewModel.permStatistics?.reportBlockNotifyAlertView()
        Navigator.shared.present(dialog, from: self)
    }
}

extension SKShareViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = (self.view.window ?? self.view) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}

extension UIView {
    func setCustomCorner(byRoundingCorners corners: UIRectCorner, radii: CGFloat) {
        let maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radii, height: radii))
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
}
