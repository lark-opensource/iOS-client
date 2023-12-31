//
//  TemplateCollectionPreviewViewController.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/5/26.
//  

import SKFoundation
import SKUIKit
import RxSwift
import Lottie
import LarkUIKit
import UniverseDesignColor
import EENavigator
import UniverseDesignToast
import UniverseDesignIcon
import SKResource
import SpaceInterface
import SKInfra
import LarkContainer

/// 套组模版预览
public final class TemplateCollectionPreviewViewController: TemplatesPreviewViewController {
    private static let bottomViewContentHeight: CGFloat = 236
    private let collectionId: String
    private let viewModel: TemplateCollectionViewModel
    private let moreHandler: TemplateCenterMoreHandler
    private let disposeBag = DisposeBag()
    private lazy var defaultLoadingView: DocsLoadingViewProtocol = {
        DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()
    private lazy var shareButton = SKBarButtonItem(
        image: UDIcon.shareOutlined,
        style: .plain,
        target: self,
        action: #selector(shareButtonAction)
    )
    private let bottomView = TemplatePreviewBottomView()
    private var errorView: UIView?
    private let templateSource: TemplateCenterTracker.TemplateSource?
    private let templateCenterSource: TemplateCenterTracker.TemplateCenterSource?
    private var sectionName: String? // 分组名

    weak var fromVC: UIViewController?
    
    public init(collectionId: String,
                networkAPI: TemplateCenterNetworkAPI,
                templateSource: TemplateCenterTracker.TemplateSource? = nil,
                templateCenterSource: TemplateCenterTracker.TemplateCenterSource? = nil,
                type: TemplateModel.TemplateType = .collection,
                sectionName: String? = nil,
                fromVC: UIViewController? = nil
    ) {
        self.collectionId = collectionId
        viewModel = TemplateCollectionViewModel(collectionId: collectionId,
                                                networkAPI: networkAPI,
                                                type: type)
        self.templateSource = templateSource
        self.templateCenterSource = templateCenterSource
        self.moreHandler = TemplateCenterMoreHandler(
            networkAPI: TemplateDataProvider(),
            fromPage: .setPreview
        )
        self.moreHandler.templateSource = templateSource
        super.init(nibName: nil, bundle: nil)
        self.sectionName = sectionName
        self.fromVC = fromVC
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBinding()
        loadData()
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        bottomOffset = Self.bottomViewContentHeight + view.safeAreaInsets.bottom
        bottomView.snp.updateConstraints { (make) in
            make.leading.bottom.trailing.equalTo(view)
            make.height.equalTo(bottomOffset)
        }
    }
    
    override func selectTemplate(_ template: TemplateModel) {
        super.selectTemplate(template)
        var otherParams = [String: Any]()
        if let templateSource = templateSource {
            otherParams["template_source"] = templateSource.rawValue
        }
        if let templateCenterSource = templateCenterSource {
            otherParams["templatecenter_source"] = templateCenterSource.rawValue
        }
        TemplateCenterTracker.reportTemplateCollectionPreview(
            template: template,
            collectionId: collectionId,
            templateSource: templateSource,
            templateCenterSource: templateCenterSource,
            sectionName: sectionName
        )
    }
    
    public override func viewWillBackToPreviousPage() {
        TemplateCenterTracker.reportTemplateCollectionCancelBack(
            type: viewModel.type,
            collectionId: collectionId,
            templateSource: templateSource,
            templateCenterSource: templateCenterSource,
            setName: viewModel.setName)
    }
    
    private func setupUI() {
        navigationBar.trailingBarButtonItems = [shareButton]
        
        view.addSubview(defaultLoadingView.displayContent)
        defaultLoadingView.displayContent.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.leading.bottom.trailing.equalTo(view)
            make.height.equalTo(Self.bottomViewContentHeight + view.safeAreaInsets.bottom)
        }
    }
    
    private func setupBinding() {
        viewModel.bottomTitle
                 .bind(to: bottomView.rx.title)
                 .disposed(by: disposeBag)

        viewModel.loading
            .subscribe({ [weak self] (event) in
                guard let self = self else { return }
                if case .next(let isLoading) = event {
                    self.defaultLoadingView.displayContent.isHidden = !isLoading
                    isLoading ? self.defaultLoadingView.stopAnimation() : self.defaultLoadingView.stopAnimation()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.loading
            .bind(to: bottomView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.error
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] _ in
                self?.showErrorView()
            }
            .disposed(by: disposeBag)
        
        viewModel.colletionName
            .bind(to: bottomView.titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.templates
            .bind(to: bottomView.templates)
            .disposed(by: disposeBag)
        
        viewModel.templates
            .subscribe { [weak self] (event) in
                guard let self = self, case let .next(templates) = event, templates.count > 0 else { return }
                self.bottomView.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
                self.openTemplate(templates[0])
                let viewModel = self.viewModel
                // 收到数据再曝光
                TemplateCenterTracker.reportPageViewEvent(page: .setPreview,
                                                          templateSource: self.templateSource,
                                                          templateCenterSource: self.templateCenterSource,
                                                          otherParams: ["is_customized": "\(viewModel.type == .ecology)", "set_name": viewModel.setName, "set_id": self.collectionId])
            }
            .disposed(by: disposeBag)
        
        bottomView.collectionView.rx.modelSelected(TemplateModel.self)
            .subscribe(onNext: { [weak self] (template) in
                self?.selectTemplate(template)
            })
            .disposed(by: disposeBag)
        bottomView.button.rx.tap
            .subscribe(onNext: { [weak self] in self?.saveBtnAction() })
            .disposed(by: disposeBag)
    }
    
    private func loadData() {
        viewModel.requestData()
    }
    
    private func saveBtnAction() {
        viewModel.templates
            .subscribe(onNext: { [weak self] templates in
                guard let self = self else { return }
                TemplateCenterTracker.reportTemplateCollectionUseButtonClick(
                    collectionId: self.collectionId,
                    templates: templates,
                    templateSource: self.templateSource,
                    templateCenterSource: self.templateCenterSource
                )
            })
            .disposed(by: disposeBag)
        
        let appLink = viewModel.appLink
        if !appLink.isEmpty {
            if let url = URL(string: appLink) {
                if isMyWindowRegularSizeInPad {
                    let windowRootVC = view.window?.rootViewController
                    self.navigationController?.viewControllers.first?.dismiss(animated: true, completion: { [weak self] in
                        guard let self = self else { return }
                        guard let topMost = UIViewController.docs.topMost(of: windowRootVC) else {
                            spaceAssertionFailure("template: cannot get right topMostVc")
                            return
                        }
                        Navigator.shared.showDetail(url, from: self.fromVC ?? topMost)
                    })
                } else {
                    Navigator.shared.push(url, from: self)
                }
            } else {
                DocsLogger.error("appLink:\(appLink) is invalid")
            }

            TemplateCenterTracker.reportTemplateCollectionConsultClick(
                type: viewModel.type,
                collectionId: collectionId,
                templateSource: templateSource,
                templateCenterSource: templateCenterSource,
                setName: viewModel.setName)
        } else {
            let currentUserResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            guard let pickerCreator = try? currentUserResolver.resolve(assert: TemplateSpaceFolderPickerCreator.self) else {
                DocsLogger.error("can not get pickerCreator")
                return
            }
            
            
            let picker = pickerCreator.createPicker { [weak self] (token, version, controller) in
                self?.didSelectParentFolder(token: token, version: version, picker: controller)
            }
            let nav = UINavigationController(rootViewController: picker)
            nav.modalPresentationStyle = SKDisplay.pad ? .formSheet : .fullScreen
            Navigator.shared.present(nav, from: self)
        }
    }
    
    private func didSelectParentFolder(token: String, version: Int, picker: UIViewController) {
        showToast(text: BundleI18n.SKResource.CreationMobile_Operation_Saving, isLoading: true)
        viewModel.saveTemplateCollectionToFolder(parent: token, folderVersion: version) { [weak self] (result) in
            guard let self = self else { return }
            self.removeToast()
            guard let result = result, let url = URL(string: result.folderURL), let folderToken = URLValidator.getFolderPath(url: url) else {
                self.showToast(text: BundleI18n.SKResource.Doc_List_AddFailedRetry, isLoading: false)
                return
            }
            picker.dismiss(animated: false) { [weak self] in
                self?.jumpFolderVC(folderToken)
            }
            self.reportSaveResult(saveResult: result, parentToken: token)
        }
    }
    
    private func jumpFolderVC(_ folderToken: String) {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        
        guard let routerService = try? userResolver.resolve(FolderRouterService.self) else {
            DocsLogger.warning("can not get FolderRouterService")
            return
        }
        routerService.destinationController(for: folderToken, sourceController: self, completion: { [weak self] folderVC in
            self?.navigationController?.pushViewController(folderVC, animated: true, completion: {
                TemplateCenterViewController.dismissNotice.onNext(folderVC)
            })
        })
    }
    
    private func showErrorView() {
        self.errorView = TemplateSpecialViewProvider.makeNoNetworkView(handler: { [weak self] in
            self?.errorView?.removeFromSuperview()
            self?.errorView = nil
            self?.loadData()
        }, bag: disposeBag)
        view.addSubview(self.errorView!)
        self.errorView?.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }
    
    private func showToast(text: String, isLoading: Bool) {
        guard let currentWindow = UIViewController.docs.topMost(of: self)?.view.window else {
            return
        }
        var hud: UDToast
        if isLoading {
            hud = UDToast.showLoading(with: text,
                                            on: currentWindow,
                        disableUserInteraction: true)
        } else {
            hud = UDToast.showTips(with: text, on: currentWindow)
        }
        hud.setCustomBottomMargin(100)
    }
    private func removeToast() {
        guard let currentWindow = UIViewController.docs.topMost(of: self)?.view.window else {
            return
        }
        UDToast.removeToast(on: currentWindow)
    }
    
    private func reportSaveResult(saveResult: TemplateCollectionSaveResult, parentToken: String) {
        SKCreateTracker.reportCreateNewObj(
            type: .folder,
            token: saveResult.folderToken,
            parentToken: parentToken.encryptToken,
            templateCenterSource: .fromSet,
            templateInfos: ["singletemplate_source": "from_preview"]
        )
        viewModel.templates
            .map { templates -> [(TemplateModel, String)] in
                var templateAndNewTokens: [(TemplateModel, String)] = []
                for template in templates {
                    for token in saveResult.tokenList where template.objToken == token.templateToken {
                        templateAndNewTokens.append((template, token.newObjToken.encryptToken))
                        break
                    }
                }
                return templateAndNewTokens
            }
            .subscribe(onNext: { [weak self] templateAndNewTokens in
                guard let self = self else { return }
                for (template, newToken) in templateAndNewTokens {
                    var templateInfos: [String: Any] = [
                        "singletemplate_source": "from_preview",
                        "token_new": newToken
                    ]
                    templateInfos["template_token"] = template.source == .system ? template.objToken : template.objToken.encryptToken
                    templateInfos["template_name"] = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
                    if template.source == .system {
                        templateInfos[DocsTracker.Params.nonSensitiveToken] = true
                    }
                    SKCreateTracker.reportCreateNewObj(
                        type: template.docsType,
                        token: template.objToken,
                        parentToken: saveResult.folderToken.encryptToken,
                        templateCenterSource: .fromSet,
                        templateInfos: templateInfos
                    )
                    TemplateCenterTracker.createFromTemplateCenter()
                }
                TemplateCenterTracker.reportTemplateCollectionUse(
                    collectionId: self.collectionId,
                    templateAndFileTokens: templateAndNewTokens,
                    folderToken: parentToken.encryptToken,
                    templateSource: self.templateSource,
                    templateCenterSource: self.templateCenterSource)
            })
            .disposed(by: disposeBag)
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
        viewModel.templates.subscribe(onNext: { templates in
            guard let template = templates.first else { return }
            self.moreHandler.showGalleryTemplateSharePopVC(template: template, fromVC: self, popSource: popSource)
        }).disposed(by: disposeBag)
    }
}
