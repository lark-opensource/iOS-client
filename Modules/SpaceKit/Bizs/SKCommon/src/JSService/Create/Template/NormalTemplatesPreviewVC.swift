//
//  NormalTemplatesPreviewVC.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/9/13.
//  

import SKUIKit
import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import SKResource
import SKFoundation
import SpaceInterface
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignActionPanel
import EENavigator

/// 普通模版预览
public final class NormalTemplatesPreviewVC: TemplatesPreviewViewController {
    private static let bottomViewContentHeight: CGFloat = 139

    private let templates: [TemplateModel]
    private var currentIndex: Int
    
    public weak var selectedDelegate: TemplateSelectedDelegate?
    public var templatePageConfig: TemplatePageConfig?
    public var autoDismiss: Bool {
        templatePageConfig?.autoDismiss ?? true
    }
    public var useTemplateType: UseTemplateType {
        templatePageConfig?.useTemplateType ?? .createAndOpen
    }
    private let bottomView = GroupNoticeTemplatePreviewBottomView(needButtonTitle: true)
    private lazy var moreButton = SKBarButtonItem(
        image: UDIcon.moreOutlined,
        style: .plain,
        target: self,
        action: #selector(moreButtonAction)
    )
    private lazy var moreHandler: TemplateCenterMoreHandler = TemplateCenterMoreHandler(
        networkAPI: TemplateDataProvider(),
        fromPage: .preview
    )
    private lazy var shareButton = SKBarButtonItem(
        image: UDIcon.shareOutlined,
        style: .plain,
        target: self,
        action: #selector(shareButtonAction)
    )
    private let disposeBag = DisposeBag()
    private let templateSource: TemplateCenterTracker.TemplateSource?
    private let templateCenterSource: TemplateCenterTracker.TemplateCenterSource?
    var docsCreateDependency: DocsCreateDependency?
    var didDeleteTemplate: ((String) -> Void)?
    var keyword: String?//从搜索页进来时，传过来的搜索关键词，用于埋点上报
    var category: String?//从模板库首页进来时，传过来的分类名，用于埋点上报
    private var filterType: FilterItem.FilterType?
    private var sectionName: String?

    public init?(templates: [TemplateModel], currentIndex: Int,
                 templateSource: TemplateCenterTracker.TemplateSource?,
                 templateCenterSource: TemplateCenterTracker.TemplateCenterSource? = nil,
                 filterType: FilterItem.FilterType? = nil,
                 sectionName: String? = nil) {
        guard !templates.isEmpty else {
            return nil
        }
        self.templates = templates
        self.currentIndex = max(min(templates.count - 1, currentIndex), 0)
        self.templateSource = templateSource
        self.templateCenterSource = templateCenterSource
        super.init(nibName: nil, bundle: nil)
        self.bottomOffset = Self.bottomViewContentHeight
        self.moreHandler.templateSource = templateSource
        self.moreHandler.templateCenterSource = templateCenterSource
        self.filterType = filterType
        self.sectionName = sectionName
    }
    
    var routerBody: TemplatePreviewBody?
    weak var customBottomView: UIView?

    public init(routerBody: TemplatePreviewBody) {
        self.routerBody = routerBody
        self.templates = []
        self.currentIndex = 0
        self.templateSource = TemplateCenterTracker.TemplateSource(rawValue: routerBody.templateSource)
        self.templateCenterSource = nil
        super.init(nibName: nil, bundle: nil)
        self.routerBody = routerBody
        self.usingWebviewTitle = true
        self.templatePageConfig = routerBody.templatePageConfig
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let routerBody = routerBody {
            openTemplate(routerBody.toTemplateModel())
            setupGroupGuideUI(previewBody: routerBody)
            bindBrowserTitle()
        } else {
            selectIndex(currentIndex)
        }
        TemplateCenterMoreHandler.didDeleteTemplateNotice.subscribe { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        .disposed(by: disposeBag)
        
        if #available(iOS 13.0, *), let isModal = self.templatePageConfig?.isModalInPresentation {
            self.isModalInPresentation = isModal
        }
        
        reportViewShow()
    }
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if self.customBottomView == nil {
            bottomOffset = Self.bottomViewContentHeight + view.safeAreaInsets.bottom
            bottomView.snp.updateConstraints { (make) in
                make.leading.bottom.trailing.equalTo(view)
                make.height.equalTo(bottomOffset)
            }
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let customBottomView = self.customBottomView {
            let height = customBottomView.bounds.height + view.safeAreaInsets.bottom
            if bottomOffset != height {
                bottomOffset = height
            }
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.selectedDelegate?.templateOnEvent(onEvent: .willClose(type: .preview))
    }
    
    public override func backBarButtonItemAction() {
        super.backBarButtonItemAction()
        TemplateCenterTracker.reportCustomTemplatePreviewClickBack(templateSource: self.templateSource)
    }
    
    private func setupGroupGuideUI(previewBody: TemplatePreviewBody) {
        guard let awesomeManager = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else {
            DocsLogger.error("awesomeManager not register")
            return
        }
        let groupView = awesomeManager.createGroupGuideBottomView(docToken: previewBody.objToken,
                                                   docType: "\(previewBody.objType)",
                                                   templateId: previewBody.templateId,
                                                   chatId: previewBody.chatId,
                                                   fromVC: previewBody.fromVC)
        view.addSubview(groupView)
        groupView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.greaterThanOrEqualTo(44)
        }
        customBottomView = groupView
        navigationBar.trailingBarButtonItems = []
        if SKDisplay.pad, self.navigationController?.viewControllers.first == self {
            navigationBar.leadingBarButtonItems = [closeButtonItem]
        }
    }

    private func reportViewShow() {
        var params: [String: Any] = [:]
        var template: TemplateModel
        if !templates.isEmpty, currentIndex < templates.count {
            template = templates[currentIndex]
        } else if let templateModel = routerBody?.toTemplateModel() {
            template = templateModel
            params["template_chat_id"] = routerBody?.chatId ?? ""
        } else {
            return
        }
        if let templateType = template.source?.trackValue() {
            params["template_type"] = templateType
        }
        let token = template.source == .system ? template.objToken : template.objToken.encryptToken
        params["template_token"] = token
        let name = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
        params["template_name"] = name
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        if let keyword = keyword {
            params["keywords"] = keyword
        }

        TemplateCenterTracker.reportPageViewEvent(
            page: .preview, templateSource: templateSource,
            templateCenterSource: templateCenterSource, otherParams: params
        )
    }

    private func setupUI() {
        title = BundleI18n.SKResource.CreationMobile_Operation_TemplatePreview
        navigationBar.trailingBarButtonItems = [moreButton]

        bottomView.titleLabel.isHidden = true
        bottomView.iconImageView.isHidden = true
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(bottomOffset)
        }

        bottomView.previousControl.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                guard self.currentIndex > 0 else { return }
                self.currentIndex -= 1
                self.selectIndex(self.currentIndex)
                TemplateCenterTracker.reportTemplatePreviewClickSwitch(
                    to: self.templates[self.currentIndex],
                    isNext: false,
                    templateSource: self.templateSource
                )
            })
            .disposed(by: disposeBag)
        bottomView.nextControl.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                guard self.currentIndex < self.templates.count - 1 else { return }
                self.currentIndex += 1
                self.selectIndex(self.currentIndex)
                TemplateCenterTracker.reportTemplatePreviewClickSwitch(
                    to: self.templates[self.currentIndex],
                    isNext: true,
                    templateSource: self.templateSource
                )
            })
            .disposed(by: disposeBag)
        bottomView.useButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let index = Int(self.currentIndex)
                self.useTemplate(self.templates[index], index)
            })
            .disposed(by: disposeBag)
        
        if routerBody?.enumSource == .imGuide {
            bottomView.isHidden = true
        }
    }
    private func selectIndex(_ index: Int) {
        bottomView.previousEnabled = index != 0
        bottomView.nextEnabled = index != templates.count - 1
        let template = templates[index]

        title = template.displayTitle
        var btnItems: [SKBarButtonItem] = []
        if self.templatePageConfig == nil ||
            self.templatePageConfig?.enableShare == true {
            if template.templateMainType == .custom {
                btnItems = [moreButton]
            } else if template.templateMainType == .gallery {
                btnItems = [shareButton]
            }
        }
        navigationBar.trailingBarButtonItems = btnItems
        if let source = self.templateSource, source.shouldUseNewForm() {
            self.openTemplate(template, isNewForm: true)
        }else{
            self.openTemplate(template, isNewForm: false)
        }
    }
    
    // 根据模版创建文档
    private func useTemplate(_ template: TemplateModel, _ index: Int) {
        guard let dependency = docsCreateDependency else {
            return
        }
        
        var result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCreateCopy,
                                                           fileBizDomain: .ccm,
                                                           docType: template.docsType,
                                                           token: template.objToken)
        if let templateType = template.source, templateType == .system { // `系统模板`不管控
            result = CCMSecurityPolicyService.ValidateResult(allow: true, validateSource: .securityAudit)
        }
        if result.allow == false {
            switch result.validateSource {
            case .fileStrategy:
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCreateCopy,
                                                             fileBizDomain: .ccm,
                                                             docType: template.docsType,
                                                             token: template.objToken)
            case .securityAudit:
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: self.view)
            case .dlpDetecting, .dlpSensitive, .unknown, .ttBlock:
                DocsLogger.info("unknown type or dlp type")
            }
            return
        }
        
        var otherParams: [String: Any] = [:]
        if let keyword = keyword {
            otherParams["keywords"] = keyword
        }
        TemplateCenterTracker.reportUseTemplate(
            template: template,
            from: .preview,
            templateSource: templateSource,
            category: category,
            clickType: .use,
            templateCenterSource: templateCenterSource,
            index: index,
            filterName: filterType?.reportName ?? "",
            sectionName: sectionName ?? "",
            otherParams: otherParams
        )
        
        if self.useTemplateType == .template {
            //通知外面选择了模板
            DocsLogger.info("useTemplate:\(template.name) and notify")
            self.selectedDelegate?.templateOnItemSelected(self, item: template.toExternalItem())
            if self.autoDismiss {
                //关闭模板预览页
                self.didCreateSuccess(targetVC: nil, targetPopVC: dependency.targetPopVC)
            }
            return
        }
        
        
        guard DocsNetStateMonitor.shared.isReachable else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_NoInternetClickMoreToast, on: view)
            return
        }
        UDToast.showLoading(with: BundleI18n.SKResource.Doc_List_TemplateCreateLoading,
                            on: view,
                            disableUserInteraction: true)

        var ccmOpenSource = dependency.trackParamterModule.generateCCMOpenCreateSource()
        if dependency.templateCenterSource == .templatecenterBanner {
            ccmOpenSource = .homeBanner
        }
        let trackParams = DocsCreateDirectorV2.TrackParameters(source: .templateCenter,
                                                               module: dependency.trackParamterModule,
                                                               ccmOpenSource: ccmOpenSource)
        
        let createCompletion: CreateCompletion = { [weak self] (token, controller, docsType, url, error) in
            guard let self = self else { return }
            // 创建中...这个loading是在curVC.view上的
            UDToast.removeToast(on: self.view)
            // 这里remove的是中间其他的一些toast，以防遮挡
            UDToast.removeToast(on: self.view.window ?? self.view)
            if let error = error {
                DocsLogger.info("Create By template error: \(error)")
                let message: String
                if let docsError = error as? DocsNetworkError {
                    message = docsError.code.templateErrorMsg()
                } else {
                    message = BundleI18n.SKResource.Doc_List_TemplateGeneralErrorToast
                }
                QuotaAlertPresentor.shared.showQuotaAlertIfNeed(
                    type: .createByTemplate,
                    defaultToast: message,
                    error: error,
                    from: self,
                    token: template.objToken
                )
                return
            }
            if let token {
                TemplateCenterTracker.reportSuccessCreateDocs(
                    template: template, docsToken: token, from: .preview,
                    category: nil, templateSource: self.templateSource,
                    otherParams: otherParams
                )
            }
            if self.useTemplateType == .create {
                //通知外面创建了文档
                self.selectedDelegate?.templateOnCreateDoc(url: url, token: token, type: docsType, error: error)
            }
            
            if self.autoDismiss {
                self.didCreateSuccess(targetVC: controller, targetPopVC: dependency.targetPopVC)
            }
        }
        if let createByTemplateHandler = dependency.createByTemplateHandler {
            //使用注入的方法创建文档
            DocsLogger.info("createByTemplateHandler in dependency")
            createByTemplateHandler(template, self, createCompletion)
            return
        }
        
        let director = WorkspaceCreateDirector(location: dependency.mountLocation,
                                               trackParameters: trackParams)
        let autoOpen = self.useTemplateType == .createAndOpen
        director.create(template: template,
                        templateCenterSource: dependency.templateCenterSource,
                        templateSource: templateSource,
                        autoOpen: autoOpen,
                        completion: createCompletion)
    }

    private func didCreateSuccess(targetVC: UIViewController?, targetPopVC: UIViewController?) {
        let popToTargetVC = { [weak self] in
            guard let self = self, let vcs = self.navigationController?.viewControllers else {
                return
            }
            var finalVCs: [UIViewController] = []
            if let targetPopVC = targetPopVC, let indexOfTargetPopVC = vcs.firstIndex(where: { $0 == targetPopVC }) {
                finalVCs.append(contentsOf: vcs[0...indexOfTargetPopVC])
            } else if let navRootVC = vcs.first {
                finalVCs.append(navRootVC)
            }
            if let targetVC = targetVC {
                finalVCs.append(targetVC)
            }
            self.navigationController?.viewControllers = finalVCs
        }
        
        guard let targetVC = targetVC else {
            if SKDisplay.pad {
                navigationController?.viewControllers.first?.dismiss(animated: true, completion: nil)
            } else {
                popToTargetVC()
            }
            return
        }
        if SKDisplay.pad {
            let windowRootVC = view.window?.rootViewController
            let isRegularSize = isMyWindowRegularSizeInPad
            navigationController?.viewControllers.first?.dismiss(animated: true, completion: {
                guard let topMost = UIViewController.docs.topMost(of: windowRootVC) else {
                    spaceAssertionFailure("template: cannot get right topMostVc")
                    return
                }
                if !isRegularSize {
                    Navigator.shared.push(targetVC, from: topMost)
                } else {
                    Navigator.shared.showDetail(targetVC, wrap: LkNavigationController.self, from: targetPopVC ?? topMost)
                }
            })
        } else {
            navigationController?.pushViewController(targetVC, animated: true, completion: {
                popToTargetVC()
            })
        }
    }

    @objc
    private func moreButtonAction() {
        var popSource: TemplateCenterMoreHandler.PopSource?
        if SKDisplay.pad, let moreBtn = navigationBar.trailingButtons.last {
            popSource = TemplateCenterMoreHandler.PopSource(sourceView: moreBtn, sourceRect: CGRect(x: 0, y: moreBtn.frame.maxY, width: 0, height: 0), arrowDirection: .any)
        }
        if !templates.isEmpty, currentIndex < templates.count {
            self.moreHandler.showMoreActionSheet(templateModel: templates[currentIndex], fromVC: self, popSource: popSource)
        } else if let templateModel = routerBody?.toTemplateModel() {
            self.moreHandler.showMoreActionSheet(templateModel: templateModel, fromVC: self, popSource: popSource)
        }
        
        TemplateCenterTracker.reportCustomTemplatePreviewClickMore()
    }
    @objc
    private func shareButtonAction() {
        guard let rightBtn = shareButton.associatedButton else {
            return
        }
        var popSource: TemplateCenterMoreHandler.PopSource?
        if Display.pad {
            popSource = TemplateCenterMoreHandler.PopSource(sourceView: rightBtn, sourceRect: rightBtn.bounds, arrowDirection: .any)
        }
        if !templates.isEmpty, currentIndex < templates.count {
            self.moreHandler.showGalleryTemplateSharePopVC(template: templates[currentIndex], fromVC: self, popSource: popSource)
        } else if let templateModel = routerBody?.toTemplateModel() {
            self.moreHandler.showGalleryTemplateSharePopVC(template: templateModel, fromVC: self, popSource: popSource)
        }
    }

    func bindBrowserTitle() {
        if let baseVC = browserInfo?.browser as? BaseViewController {
           let navigationBar = baseVC.navigationBar
           navigationBar.titleView.titleLabel
                        .rx.observe(String.self, "text")
                        .subscribe { [weak self, weak navigationBar] title in
                             if let title = title, !title.isEmpty {
                                 self?.title = title
                             } else if let docName = navigationBar?.titleInfo?.docName {
                                 self?.title = docName
                             }
                        }.disposed(by: disposeBag)
        }
    }
}
