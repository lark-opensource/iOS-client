//
//  TemplateCenterViewController.swift
//  SKCommon
//
//  Created by 邱沛 on 2020/9/15.
//
// swiftlint:disable file_length type_body_length
import SwiftyJSON
import Lottie
import SKFoundation
import SKUIKit
import SKResource
import RxSwift
import RxCocoa

import EENavigator
import LarkTraitCollection
import UniverseDesignColor
import UniverseDesignToast
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignActionPanel
import SpaceInterface
import SKInfra

public final class TemplateCenterViewController: BaseViewController, DocsCreateViewControllerRouter {
    
    public static let preferredContentSize = CGSize(width: 712, height: 936)
    static let dismissNotice = PublishSubject<UIViewController?>()
    // dependency
    public var trackParamter: DocsCreateDirectorV2.TrackParameters = DocsCreateDirectorV2.TrackParameters.default()
    // 用于点击链接跳转模版中心后的埋点
    private var enterSource: String?
    var mountLocation: WorkspaceCreateLocation
    private weak var targetPopVC: UIViewController?
    private var moreHandler: TemplateCenterMoreHandler?
    public weak var selectedDelegate: TemplateSelectedDelegate?
    public var templatePageConfig: TemplatePageConfig?
    // view
    lazy var typeChooseView: TemplateTypeChooseView = {
        let typeNames = tabViews.map({ $0.tabName })
        let chooseView = TemplateTypeChooseView(names: typeNames,
                                                isBlueLineAlignToText: true)
        chooseView.delegate = self
        if let selectIndex = supportMainTypes.firstIndex(where: { $0 == Self.currentTabViewType }) {
            chooseView.select(at: selectIndex, animated: false)
        } else {
            chooseView.select(at: 0, animated: false)
        }
        return chooseView
    }()

    lazy var backgroundScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = false
        return scrollView
    }()
    private lazy var defaultLoadingView: DocsLoadingViewProtocol = {
        DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()


    private lazy var searchButton: SKBarButtonItem = {
        let searchItem = SKBarButtonItem(image: UDIcon.searchOutlineOutlined,
                                         style: .plain,
                                         target: self,
                                         action: #selector(onSelectSearch))
        searchItem.id = .search
        return searchItem
    }()

    private lazy var galleryTabView: TemplateTabView = {
        let tabView = TemplateTabView(
            tabName: BundleI18n.SKResource.Doc_List_v4TemplateGallery(),
            mainType: .gallery,
            templateSource: templateSource
        )
        tabView.notifyLoadMore = { [weak self] category in
            self?.viewModel.input.loadPageForCategory.onNext((category.id, category.currentPage + 1))
        }
        return tabView
    }()
    private lazy var customTabView: TemplateTabView = {
        let tabView = TemplateTabView(
            tabName: BundleI18n.SKResource.Doc_List_CustomTemplate,
            mainType: .custom,
            templateSource: templateSource
        )
        tabView.notifyLoadMore = { [weak self] _ in
            self?.viewModel.input.loadMoreCustomTemplates.onNext(())
        }
        return tabView
    }()
    private lazy var businessTabView = TemplateTabView(
        tabName: BundleI18n.SKResource.Doc_List_EnterpriseTemplate,
        mainType: .business,
        templateSource: templateSource
    )
    private lazy var tabViews: [TemplateTabView] = {
        return self.supportMainTypes.map(self.tabView(of:))
    }()
    private let supportMainTypes: [TemplateMainType] = {
        var types: [TemplateMainType] = [.gallery, .custom]
        if LKFeatureGating.templateV4BusinessEnable {
            types.append(.business)
        }
        return types
    }()
    
    // model
    private let viewModel: TemplateCenterViewModel
    public static var currentTabViewType: TemplateMainType = .gallery
    public static var currentTemplateCategory: Int?
    private let bag = DisposeBag()
    private var isFirstLoad: Bool = true
    private var needReportFilterAction: Bool = false // 是否需要上报过滤操作
    private var magicRegister: FeelGoodRegister?
    private let source: TemplateCenterTracker.EnterTemplateSource
    private var curCategory: TemplateCenterViewModel.Category?
    private var objType: DocsType?
    private let createBlankDocs: Bool // 是否通过点击新建空白文档按钮进入模版中心
    private let templateSource: TemplateCenterTracker.TemplateSource?

    public override var commonTrackParams: [String: String] {
        [
            "module": "template",
            "sub_module": "none"
        ]
    }
    
    /// 生成一个模板中心VC
    /// - Parameters:
    ///   - initialType: 一级分类类型
    ///   - templateCategory: 二级分类类型，因为二级分类会根据运营后台配置来显示，比较动态，就不定义成枚举了
    ///   - targetPopVC: 根据模板创建成功之后，pop回哪个界面，如果不传，默认pop回rootVC
    ///   - objType: 用来设置进入界面时的默认筛选项
    ///   - createBlankDocs: 是否通过新建文档按钮进入
    public init(viewModel: TemplateCenterViewModel? = nil,
                initialType: TemplateMainType? = nil,
                templateCategory: Int? = nil,
                objType: Int? = nil,
                mountLocation: WorkspaceCreateLocation = .spaceDefault,
                targetPopVC: UIViewController? = nil,
                createBlankDocs: Bool = false,
                source: TemplateCenterTracker.EnterTemplateSource,
                enterSource: String? = nil,
                templateSource: TemplateCenterTracker.TemplateSource? = nil
    ) {
        if let vm = viewModel {
            self.viewModel = vm
        } else {
            let dataProvider = TemplateDataProvider()
            let vm = TemplateCenterViewModel(depandency: (networkAPI: dataProvider, cacheAPI: dataProvider))
            self.viewModel = vm
        }
        
        var mainType = Self.currentTabViewType
        if let initialType = initialType {
            mainType = initialType
        }
        if supportMainTypes.contains(mainType) {
            Self.currentTabViewType = mainType
        } else {
            DocsLogger.info("not support main type. jump to gallery tab")
            Self.currentTabViewType = .gallery
        }
        Self.currentTemplateCategory = templateCategory
        if let type = objType {
            self.objType = DocsType(rawValue: type)
        }
        self.mountLocation = mountLocation
        
        self.targetPopVC = targetPopVC
        self.source = source
        self.enterSource = enterSource
        self.templateSource = templateSource ?? TemplateCenterTracker.TemplateSource(enterSource: enterSource, source: source)
        self.createBlankDocs = createBlankDocs
        let networkAPI = TemplateDataProvider()
        networkAPI.templateSource = self.templateSource?.rawValue
        super.init(nibName: nil, bundle: nil)
        self.setupFeelGood()
        self.moreHandler = TemplateCenterMoreHandler(networkAPI: networkAPI, fromPage: .userCenter)
        self.moreHandler?.templateSource = templateSource
        self.viewModel.docxEnable = isDocxEnable()
        self.viewModel.createBlankDocs = createBlankDocs
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("📖📖📖TemplateCenterViewController deinit")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        bindAction()
        addClassSizeObserver()
        addCipherChangeObserver()
        
        if #available(iOS 13.0, *), let isModal = self.templatePageConfig?.isModalInPresentation {
            self.isModalInPresentation = isModal
        }
        
        addStatistics()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        setupCommonHandlerForTabViews()
        if isFirstLoad {
            isFirstLoad = false
            let hostViewWidth = self.view.frame.width
            tabViews.forEach { (view) in
                view.updateHostViewWidth(hostViewWidth)
            }
            loadData()
        }
        
        galleryTabView.resetBannerScrollViewDelegate(isClear: false)
        galleryTabView.resetBannerAnimationIfNeed(isStart: true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let viewId = "\(ObjectIdentifier(self))"
        let scene = PowerConsumptionStatisticScene.specifiedPage(page: .template, contextViewId: viewId)
        PowerConsumptionExtendedStatistic.markStart(scene: scene)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let viewId = "\(ObjectIdentifier(self))"
        let scene = PowerConsumptionStatisticScene.specifiedPage(page: .template, contextViewId: viewId)
        PowerConsumptionExtendedStatistic.markEnd(scene: scene)
        self.selectedDelegate?.templateOnEvent(onEvent: .willClose(type: .select))
    }
    
    public override func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
        guard size != oldSize else { return }
        freshLayout()
    }
    
    public override func viewDidSplitModeChange() {
        super.viewDidSplitModeChange()
        freshLayout()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTabViews()
    }
    
    private func layoutTabViews() {
        let pageWidth = self.view.bounds.width
        var totalWidth: CGFloat = 0
        let pageHeight = backgroundScrollView.bounds.height
        tabViews.forEach({ (tabView) in
            tabView.frame = CGRect(x: totalWidth, y: 0, width: pageWidth, height: pageHeight)
            tabView.updateHostViewWidth(pageWidth)
            totalWidth += pageWidth
        })
        backgroundScrollView.contentSize = CGSize(width: totalWidth, height: pageHeight)
        if let selectIndex = typeChooseView.currentSelectIndex() {
            backgroundScrollView.contentOffset = CGPoint(x: CGFloat(selectIndex) * pageWidth, y: 0)
        }
    }

    private func addClassSizeObserver() {
        // 监听sizeClass
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                guard change.new != change.old, let self = self else { return }
                self.freshLayout()
            }).disposed(by: bag)
    }
    
    private func addCipherChangeObserver() {
        NotificationCenter.default.rx
            .notification(.Docs.cipherChanged)
            .takeUntil(self.rx.deallocated)
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.input.forceRefreshCustomTemplates.onNext(())
                self?.viewModel.input.forceRefreshBusinessTemplates.onNext(())
            })
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        galleryTabView.resetBannerScrollViewDelegate(isClear: true)
        galleryTabView.resetBannerAnimationIfNeed(isStart: false)
    }
    
    private func setupUI() {
        title = BundleI18n.SKResource.Doc_List_AllTemplateTitle

        view.addSubview(typeChooseView)
        view.addSubview(backgroundScrollView)
        view.addSubview(defaultLoadingView.displayContent)

        typeChooseView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            
            if let source = self.templateSource, source.shouldUseNewForm() {
                make.height.equalTo(0)
            } else {
            make.height.equalTo(37)
            }
        }
        backgroundScrollView.snp.remakeConstraints { (make) in
            make.top.equalTo(typeChooseView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        defaultLoadingView.displayContent.snp.makeConstraints { (make) in
            make.top.equalTo(typeChooseView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        _updateLeftBarItem()
    }
    
    @objc
    func onSelectSearch() {
        TemplateCenterTracker.reportSearchButtonClick(mainType: Self.currentTabViewType, templateSource: templateSource)
        let dataProvider = TemplateDataProvider()
        dataProvider.templateSource = templateSource?.rawValue
        let vm = TemplateSearchViewModel(networkAPI: dataProvider)
        vm.templateSource = templateSource?.rawValue
        vm.docxEnable = isDocxEnable()
        let vc = TemplateSearchViewController(templateSearchVM: vm,
                                              hostViewSize: view.frame.size,
                                              mountLocation: mountLocation,
                                              targetPopVC: targetPopVC,
                                              source: source,
                                              templateSource: templateSource)
        Navigator.shared.push(vc, from: self)
    }

    @objc
    private func showFilterView() {
        viewModel.input.showFilterView.onNext(Self.currentTabViewType)
    }

    private func setupCommonHandlerForTabViews() {
        // TabView 逻辑
        tabViews.forEach({ (tabView) in
            self.backgroundScrollView.addSubview(tabView)
            tabView.notifyDelegateDidClickCellForTemplate = { [weak self] (section, template) in
                self?.notifyDelegateDidClickCellForTemplate(section, template, templateCenterSource: .templatecenterNormalcreate)
            }
            tabView.notifyClickBanner = { [weak self] (index, templateBanner) in
                guard let self = self else { return }
                // push to new VC
                self.handleBannerClickEvent(index: index, templateBanner: templateBanner)
            }
            
            tabView.notifyDidChooseACategory = { [weak self] (category) in
                guard let self = self else { return }
                self.curCategory = category
            }
            tabView.notifyClickCellsMoreButton = { [weak self] (template, moreButton) in
                guard let self = self else { return }
                var popSource: TemplateCenterMoreHandler.PopSource?
                guard .cipherDeleted != template.effectiveStatus else {
                    UDToast.showTips(with: BundleI18n.SKResource.CreationDoc_Template_KeyInvalidCanNotOperate, on: self.view)
                    return
                }
                if Display.pad {
                    popSource = TemplateCenterMoreHandler.PopSource(sourceView: moreButton, sourceRect: .zero, arrowDirection: .any)
                }
                self.moreHandler?.showMoreActionSheet(templateModel: template, fromVC: self, popSource: popSource, needEdit: true)
            }
        })
    }
    
    private func handleBannerClickEvent(index: Int, templateBanner: TemplateBanner) {
        guard let type = TemplateBanner.BannerType(rawValue: templateBanner.bannerType) else {
            spaceAssertionFailure("banner new type, you need adapt it")
            return
        }
        switch type {
        case .singleTemplate:
            // 直接创建
            let template = TemplateModel(createTime: 1,
                                         id: "\(templateBanner.templateId)",
                                         name: "",
                                         objToken: templateBanner.objToken,
                                         objType: templateBanner.objType,
                                         updateTime: 1,
                                         source: .system) // 表示系统推荐
            self.notifyDelegateDidClickCellForTemplate(nil, template, templateCenterSource: .templatecenterBanner)
        case .topicTemplates:
            let dataProvider = TemplateDataProvider()
            dataProvider.templateSource = templateSource?.rawValue
            let vm = TemplateThemeViewModel(networkAPI: dataProvider, cacheAPI: dataProvider, topID: templateBanner.topicId)
            let filterType = self.viewModel.filterType(of: .gallery)
            let vc = TemplateThemeListViewController(
                fromViewWidth: self.view.frame.width,
                viewModel: vm,
                filterType: filterType,
                objType: nil,
                mountLocation: self.mountLocation,
                targetPopVC: self.targetPopVC,
                source: self.source,
                templateSource: templateSource
            )
            Navigator.shared.push(vc, from: self)
        case .jumpLinkUrl:
            if let jumpLinkUrl = templateBanner.jumpLinkUrl, !jumpLinkUrl.isEmpty, let url = URL(string: jumpLinkUrl) {
                Navigator.shared.push(url, from: self)
            }
        case .templateCollectionPreview:
            guard let collectionId = templateBanner.collectionId else { return }
            let dataProvider = TemplateDataProvider()
            dataProvider.templateSource = templateSource?.rawValue
            let vc = TemplateCollectionPreviewViewController(
                collectionId: collectionId,
                networkAPI: dataProvider,
                templateSource: templateSource,
                templateCenterSource: .banner
            )
            Navigator.shared.push(vc, from: self)
        case .templateCollectionList: break
        }
    }

    private func checkIfNeedSetTargetCategory(tabView: TemplateTabView,
                                                 type: TemplateMainType,
                                           dataSource: Categories) {
        guard Self.currentTabViewType == type else {
            return
        }
        // 先尝试匹配init时传入的指定分类
        var taregetIndex: Int?
        if let currentTemplateCategory = Self.currentTemplateCategory {
            let categoryStr = String(currentTemplateCategory)
            taregetIndex = dataSource.index(where: { $0.id == categoryStr })
        }
        
        let categoryNames = dataSource.map({ $0.name })
        // 再尝试匹配之前选中的分类
        if taregetIndex == nil,
           let currentSelectedCategoryIndex = tabView.categoriesView.selectedIndex.value {
            taregetIndex = currentSelectedCategoryIndex
        }
        // 都不匹配则选择第一个分类
        if taregetIndex == nil, !categoryNames.isEmpty {
            taregetIndex = 0
        }
        Self.currentTemplateCategory = nil
        tabView.updateTargetCategory(index: taregetIndex)
    }
    // swiftlint:disable cyclomatic_complexity function_body_length
    private func bindAction() {
        viewModel.input.galleryFilterType.bind(to: galleryTabView.filterType).disposed(by: bag)
        viewModel.input.customFilterType.bind(to: customTabView.filterType).disposed(by: bag)
        viewModel.input.businessFilterType.bind(to: businessTabView.filterType).disposed(by: bag)
        
        Observable
            .merge(viewModel.input.galleryFilterType.asObservable(),
                   viewModel.input.customFilterType.asObservable(),
                   viewModel.input.businessFilterType.asObservable())
            .subscribe(onNext: {[weak self] filterType in
                guard let self = self else { return }
                self.setLoadingViewShow(true)
                self._updateRightBarItem(filterType, at: Self.currentTabViewType)
            }).disposed(by: bag)

        viewModel.galleryCategoryUpdated
            .subscribe(onNext: {[weak self] (event) in
                guard let self = self else { return }
                self.setLoadingViewShow(false)
                switch event {
                case .next(let dataSource):
                    self.checkIfNeedSetTargetCategory(tabView: self.galleryTabView, type: .gallery, dataSource: dataSource)
                    self.galleryTabView.updateDataSource.onNext(dataSource)
                    self.reportFilterActionIfNeed(hasData: { !self.isDataSourceEmpty(dataSource: dataSource) })
                case .error:
                    if self.viewModel.galleryCategories.isEmpty {
                        let errorView = TemplateSpecialViewProvider.makeNoNetworkView(handler: { [weak self] in
                            guard let self = self else { return }
                            let filterType = self.viewModel.input.galleryFilterType.value
                            self.viewModel.input.galleryFilterType.accept(filterType)
                        }, bag: self.bag)
                        self.galleryTabView.showErrorPage.onNext(errorView)
                    }
                    self.reportFilterActionIfNeed(hasData: { false })
                case .completed: break
                @unknown default: break
                }
            }).disposed(by: bag)
        
        viewModel.galleryCategoryTemplatesUpdate
            .subscribe(onNext: { [weak self] in
                self?.galleryTabView.appendPageData.onNext($0)
            }).disposed(by: bag)

        viewModel.customTemplatesUpdated
            .subscribe(onNext: {[weak self] (event) in
                guard let self = self else { return }
                self.setLoadingViewShow(false)
                switch event {
                case .next(let dataSource):
                    self.checkIfNeedSetTargetCategory(tabView: self.customTabView, type: .custom, dataSource: dataSource)
                    self.customTabView.updateDataSource.onNext(dataSource)
                    self.reportFilterActionIfNeed(hasData: { !self.isDataSourceEmpty(dataSource: dataSource) })
                case .error(let error):
                    if let error = error as? TemplateError, error == .customNoData {
                        let blankView = TemplateSpecialViewProvider.makeCustomBlankView(targetViewWidth: self.view.frame.width)
                        blankView.button.rx.tap.subscribe(onNext: {[weak self] () in
                            do {
                                let url = try HelpCenterURLGenerator.generateURL(article: .templateCenterHelpCenter)
                                let webVC = WebViewController(url)
                                self?.navigationController?.pushViewController(webVC, animated: true)
                            } catch {
                                DocsLogger.error("failed to generate helper center URL when openMorefrom privacy setting", error: error)
                            }
                        }).disposed(by: self.bag)

                        self.customTabView.showErrorPage
                            .onNext(blankView)
                        return
                    }

                    if self.viewModel.customDataSource.isEmpty {
                        let errorView = TemplateSpecialViewProvider.makeNoNetworkView(handler: { [weak self] in
                            self?.viewModel.input.customFilterType.accept(.all)
                        }, bag: self.bag)
                        self.customTabView.showErrorPage.onNext(errorView)
                    }
                    self.reportFilterActionIfNeed(hasData: { false })

                case .completed: break
                @unknown default: break
                }
            }).disposed(by: bag)

        viewModel.businessTemplatesUpdated
            .subscribe(onNext: {[weak self] (event) in
                guard let self = self else { return }
                self.setLoadingViewShow(false)
                switch event {
                case .next(let dataSource):
                    self.checkIfNeedSetTargetCategory(tabView: self.businessTabView, type: .business, dataSource: dataSource)
                    self.businessTabView.updateDataSource.onNext(dataSource)
                    self.reportFilterActionIfNeed(hasData: { !self.isDataSourceEmpty(dataSource: dataSource) })
                case .error(let error):
                    if let error = error as? TemplateError {
                        switch error {
                        case .parseDataError, .getCacheError, .customNoData, .themeNoData: break
                        case .businessNoData:
                            self.businessTabView.showErrorPage.onNext(TemplateSpecialViewProvider.makeBusinessBlankView(targetViewWidth: self.view.frame.width))
                            return
                        case .filterTypeNoData:
                            self.businessTabView.showErrorPage.onNext(TemplateSpecialViewProvider.makeTemplateCategoryBlankView(targetViewWidth: self.view.frame.width))
                            return
                        }
                    }

                    if self.viewModel.businessCategories.isEmpty {
                        let errorView = TemplateSpecialViewProvider.makeNoNetworkView(handler: { [weak self] in
                            self?.viewModel.input.businessFilterType.accept(.all)
                        }, bag: self.bag)
                        self.businessTabView.showErrorPage.onNext(errorView)
                    }
                    self.reportFilterActionIfNeed(hasData: { false })
                case .completed: break
                @unknown default: break
                }
            }).disposed(by: bag)
        
        viewModel.templateBannerUpdated
            .subscribe(onNext: {[weak self] (event) in
                switch event {
                case .next(let data):
                    self?.galleryTabView.updateBannerData(data: data)
                case .error(let error):
                    DocsLogger.error("load template search recommend key error: \(error)")
                case .completed: break
                @unknown default: break
                }

            }).disposed(by: bag)
        

        viewModel.showFilterView
            .subscribe(onNext: {[weak self] (items) in
                guard let self = self else { return }
                let selection = items.firstIndex(where: { $0.isSelected == true }) ?? 0
                let panelController = SpaceFilterPanelController(options: items, initialSelection: selection)
                panelController.delegate = self
                guard let rightBtn = self.navigationBar.trailingButtonBar.itemViews.first else { return }
                panelController.setupPopover(sourceView: rightBtn, direction: .up)
                self.present(panelController, animated: true, completion: nil)
            }).disposed(by: bag)
        
        Self.dismissNotice.subscribe(onNext: { [weak self] topVC in
            guard let vcs = self?.navigationController?.viewControllers else {
                return
            }
            var targetPopIndex: Int?
            if let vc = self?.targetPopVC, vcs.contains(vc) {
                targetPopIndex = vcs.firstIndex(of: vc)
            } else {
                for i in 0..<vcs.count {
                    guard vcs[i] is TemplateCenterViewController else {
                        continue
                    }
                    targetPopIndex = i - 1
                    break
                }
            }
            guard let targetPopIndex = targetPopIndex else {
                return
            }
            var finalVCs = targetPopIndex >= 0 ? Array(vcs[0...targetPopIndex]) : Array()
            if let topVC = topVC, vcs.contains(topVC), !finalVCs.contains(topVC) {
                finalVCs.append(topVC)
            }
            guard !finalVCs.isEmpty else {
                return
            }
            self?.navigationController?.viewControllers = finalVCs
        }).disposed(by: bag)
        
        TemplateCenterMoreHandler.didDeleteTemplateNotice.subscribe { [weak self] event in
            guard case .next(let template) = event, let self = self else {
                return
            }
            self.viewModel.input.deleteNoPermissionTemplate.onNext((template.templateMainType, template.objToken))
        }
        .disposed(by: bag)
    }

    private func loadData() {
        guard supportMainTypes.contains(where: { $0 == Self.currentTabViewType }) else {
            spaceAssertionFailure("load data not match main type \(supportMainTypes) : \(Self.currentTabViewType)")
            return
        }
        if let selectIndex = typeChooseView.currentSelectIndex() {
            switchToMainType(at: selectIndex)
        }
        
        if !source.isFromBitableHome {
            viewModel.input.initTemplateBanner.onNext(())
        }
    }
    
    private func getFilterTypeByApplink() -> FilterItem.FilterType? {
        guard let objType = self.objType else {
            return nil
        }
        
        var filterType: FilterItem.FilterType?
        switch objType {
        case .doc, .docX:
            filterType = .doc
        case .sheet:
            filterType = .sheet
        case .mindnote:
            filterType = .mindnote
        case .bitable:
            filterType = .bitable
        default:
            #if DEBUG
            spaceAssertionFailure("receive new filtertype in template center")
            #endif
            DocsLogger.error("receive new filtertype in template center")
        }
        return filterType
    }
    
    private func setLoadingViewShow(_ show: Bool) {
        defaultLoadingView.displayContent.isHidden = !show
        if show {
            view.bringSubviewToFront(defaultLoadingView.displayContent)
            defaultLoadingView.startAnimation()
        } else {
            defaultLoadingView.stopAnimation()
        }
    }

    ///fromsheet模式导航栏左侧关闭按钮
    private func _updateLeftBarItem() {
        if SKDisplay.pad, self.navigationController?.viewControllers.first == self {
            navigationBar.leadingBarButtonItems = [closeButtonItem]
        }
    }

    private func _updateRightBarItem(_ filterType: FilterItem.FilterType?, at mainType: TemplateMainType, isEmptyTemplate: Bool = false) {
        guard mainType == Self.currentTabViewType else {
            DocsLogger.info("update rightitems not match current tabView type")
            return
        }
        guard let filterType = filterType else {
            navigationBar.trailingBarButtonItems = [searchButton]
            return
        }
        let docsType = FilterItem.convertType(filterType: filterType).first
        let filterItem = SKBarButtonItem(image: UDIcon.filterOutlined,
                                         style: .plain,
                                         target: self,
                                         action: #selector(showFilterView))
        filterItem.id = .filter
        if let type = docsType {
            filterItem.customView = TemplateSpecialViewProvider
                .makeFilteredStateView(type: type.i18Name,
                                       handler: { [weak self] in self?.showFilterView() },
                                       bag: bag)
        }
        var items: [SKBarButtonItem] = []
        
        var addFilterItem = !source.isFromBitableHome // 原来的逻辑，不进行修改
        if let source = templateSource, source.shouldUseNewForm() { // append一个新逻辑，如果是 lark new form，不能添加 FilterItem
            addFilterItem = false
        }
        if addFilterItem {
            //bitable Home页面打开的模版中心隐藏类型筛选按钮
            items.append(filterItem)
        }
        
        items.append(searchButton)
        navigationBar.trailingBarButtonItems = items
    }
    
    private func setupFeelGood() {
        magicRegister = FeelGoodRegister(type: .templateCenter) { [weak self] in return self }
    }
    
    private func addStatistics() {
        TemplateCenterTracker.reportEnterTemplateCenterTracker(source: source)
    }
    
    private func switchToMainType(at index: Int) {
        let scrollWidth = CGFloat(index) * self.backgroundScrollView.bounds.width
        self.backgroundScrollView.setContentOffset(CGPoint(x: scrollWidth, y: 0), animated: false)
        if supportMainTypes.count > index {
            Self.currentTabViewType = supportMainTypes[index]
        } else {
            spaceAssertionFailure("not match main type")
            Self.currentTabViewType = .gallery
        }

        let isEmpty = viewModel.isDataSourceEmpty(of: Self.currentTabViewType)
        if isEmpty {
            if let filterType = getFilterTypeByApplink() {
                self.updateFilterValue(filterType: filterType)
                return
            }
            self.updateFilterValue(filterType: .all)
        } else {
            _updateRightBarItem(viewModel.filterType(of: Self.currentTabViewType), at: Self.currentTabViewType)
        }
        
        TemplateCenterTracker.reportTemplateCenterTabView(type: Self.currentTabViewType, enterSource: enterSource, templateSource: templateSource)
        // 只在第一次时上报，后面因为用户点击切换tab，造成的页面曝光不再上报enterSource
        enterSource = nil
    }
    
    private func reportFilterActionIfNeed(hasData: () -> Bool) {
        guard needReportFilterAction else { return }
        needReportFilterAction = false
        let filter = viewModel.filterType(of: Self.currentTabViewType)
        var trackerFilterType: TemplateCenterTracker.FilterType
        switch filter {
        case .all: trackerFilterType = .all
        case .doc: trackerFilterType = .doc
        case .sheet: trackerFilterType = .sheet
        case .mindnote: trackerFilterType = .mindnote
        case .bitable: trackerFilterType = .bitable
        case .slides, .wiki, .file, .document, .folder: return
        }
        let hasResult = hasData()
        TemplateCenterTracker.reportFilterAction(source: Self.currentTabViewType, filterType: trackerFilterType, hasResult: hasResult, templateSource: templateSource)
    }
    
    private func isDataSourceEmpty(dataSource: Categories) -> Bool {
        return dataSource.allSatisfy { $0.sections.allSatisfy { $0.templates.allSatisfy { $0.style == .emptyData } } }
    }
    
    private func isDocxEnable() -> Bool {
        if createBlankDocs && (objType == .doc || objType == .docX) {
            return objType == .docX
        } else {
            return LKFeatureGating.templateDocXEnable
        }
    }
    
    private func tabView(of mainType: TemplateMainType) -> TemplateTabView {
        switch mainType {
        case .gallery:
            return galleryTabView
        case .custom:
            return customTabView
        case .business:
            return businessTabView
        }
    }
}

extension TemplateCenterViewController: TemplateTypeChooseViewDelegate {
    func templateTypeChooseView(_ templateTypeChooseView: TemplateTypeChooseView, didClickTypeAt index: Int) {
        let preType = Self.currentTabViewType
        switchToMainType(at: index)
        let curType = Self.currentTabViewType
        TemplateCenterTracker.reportMainTypeSwitch(from: preType, to: curType)
    }
}

extension TemplateCenterViewController: SpaceFilterPanelDelegate {
    public func filterPanel(_ panel: SpaceFilterPanelController, didConfirmWith selection: FilterItem) {
        needReportFilterAction = true
        updateFilterValue(filterType: selection.filterType)
    }

    public func didClickResetFor(filterPanel: SpaceFilterPanelController) {
        spaceAssertionFailure("模板中心 filter 面板不支持 reset")
    }

    private func updateFilterValue(filterType: FilterItem.FilterType) {
        viewModel.inputFilterType(of: Self.currentTabViewType).accept(filterType)
    }
}

extension TemplateCenterViewController {

    func notifyDelegateDidClickCellForTemplate(_ section: TemplateCenterViewModel.Section?, _ template: TemplateModel, templateCenterSource: SKCreateTracker.TemplateCenterSource) {
        guard .cipherDeleted != template.effectiveStatus else {
            UDToast.showTips(with: BundleI18n.SKResource.CreationDoc_Template_KeyInvalidCanNotOperate, on: self.view)
            return
        }
        switch template.type ?? .normal {
        case .normal:
            if template.style == .createBlankDocs {
                clickCreateBlankDocs(template)
            } else {
                clickNormalTemplate(section, template, templateCenterSource: templateCenterSource)
            }
        case .collection, .ecology: clickTemplateCollection(section, template)
        }
    }
    
    private func clickNormalTemplate(_ section: TemplateCenterViewModel.Section?, _ template: TemplateModel, templateCenterSource: SKCreateTracker.TemplateCenterSource) {
        guard DocsNetStateMonitor.shared.isReachable else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_NoInternetClickMoreToast, on: self.view)
            return
        }
        previewByClickTemplate(section, template)
    }
    
    private func previewByClickTemplate(_ section: TemplateCenterViewModel.Section?, _ template: TemplateModel) {
        let tabView = self.tabView(of: Self.currentTabViewType)
        guard let visibleDataSource = tabView.visibleDataSource else { return }
        
        let templates: [TemplateModel] = visibleDataSource.sections
            .flatMap({ $0.templates })
            .filter({ !$0.objToken.isEmpty && ($0.type == nil || $0.type == .normal) })
        // 推荐里会有一些重复的
        let index = templates.firstIndex(where: { unsafeBitCast($0, to: Int.self) == unsafeBitCast(template, to: Int.self) }) ?? 0
        var extra: [String: Any]?
        if let category = curCategory {
            extra = TemplateCenterTracker.formateStatisticsInfoForCreateEvent(source: source, categoryName: category.name, categoryId: category.id)
        }
        guard let previewVC = NormalTemplatesPreviewVC(templates: templates,
                                                       currentIndex: index,
                                                       templateSource: self.templateSource,
                                                       filterType: tabView.filterType.value,
                                                       sectionName: section?.name) else {
            return
        }
        previewVC.category = tabView.categoriesView.selectedName
        previewVC.selectedDelegate = self.selectedDelegate
        previewVC.templatePageConfig = self.templatePageConfig
        let dependency = DocsCreateDependency(
            trackParamterModule: self.trackParamter.module,
            trackExtraParamter: extra,
            templateCenterSource: .templatecenterNormalcreate,
            mountLocation: mountLocation,
            targetPopVC: targetPopVC
        )
        previewVC.docsCreateDependency = dependency
        self.navigationController?.pushViewController(previewVC, animated: true)
    }

    private func clickCreateBlankDocs(_ template: TemplateModel) {
        let enable = DocsNetStateMonitor.shared.isReachable || template.docsType.isSupportOfflineCreate
        guard enable else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet, on: self.view.window ?? self.view)
            return
        }
        UDToast.showLoading(with: BundleI18n.SKResource.Doc_List_TemplateCreateLoading,
                            on: self.view,
                            disableUserInteraction: true)
        var trackParams = DocsCreateDirectorV2.TrackParameters.default()
        trackParams.ccmOpenSource = self.trackParamter.ccmOpenSource
        let director = WorkspaceCreateDirector(location: mountLocation,
                                               trackParameters: trackParams)
        let complection: CreateCompletion = {
            [weak self] token, vc, docsType, _, error in
            guard let self = self else { return }
            UDToast.removeToast(on: self.view)
            if let error = error {
                UDToast.showFailure(with: error.localizedDescription, on: self.view.window ?? self.view)
            }
            if let targetVC = vc {
                self.jumpTo(docsViewController: targetVC)
            }
            if let token = token {
                TemplateCenterTracker.reportSuccessCreateBlankDocs(
                    docsToken: token,
                    docsType: docsType,
                    templateSource: self.templateSource
                )
            }
        }
        if let source = templateSource, source.shouldUseNewForm() {
            director.create(template: template,
                            templateCenterSource: .templatecenterNormalcreate,
                            templateSource: templateSource,
                            completion: complection)
        } else {
            director.create(docsType: template.docsType, templateSource: templateSource, completion: complection)
        }
    }
    
    private func clickTemplateCollection(_ section: TemplateCenterViewModel.Section?, _ template: TemplateModel) {
        guard let collectionId = template.extra?.colletionId else { return }
        let dataProvider = TemplateDataProvider()
        dataProvider.templateSource = templateSource?.rawValue
        let vc = TemplateCollectionPreviewViewController(
            collectionId: collectionId,
            networkAPI: dataProvider,
            templateSource: templateSource,
            type: template.type ?? .collection,
            sectionName: section?.name,
            fromVC: self.targetPopVC
        )
        Navigator.shared.push(vc, from: self)
        TemplateCenterTracker.clickTemplatePreview(from: .center)
    }
    
    private func jumpTo(docsViewController: UIViewController) {
        if SKDisplay.pad && self.navigationController?.viewControllers.count == 1 {
            let rootVC = self.view.window?.rootViewController
            self.dismiss(animated: true, completion: { [weak self] in
                guard let self = self else { return }
                var topMost = self.targetPopVC
                if topMost == nil {
                    topMost = UIViewController.docs.topMost(of: rootVC)
                }
                guard let fromVC = topMost else {
                    spaceAssertionFailure("template: cannot get right topMostVc")
                    return
                }
                Navigator.shared.showDetail(docsViewController, wrap: LkNavigationController.self, from: fromVC)
            })
        } else {
            self.navigationController?.pushViewController(docsViewController, animated: true, completion: {
                guard var vcs = self.navigationController?.viewControllers else {
                    return
                }
                vcs.removeAll(where: { $0 == self })
                guard vcs.count > 1 else { return }
                self.navigationController?.viewControllers = vcs
            })
        }
    }

    //iPad分屏、转屏情况下刷新布局
    private func freshLayout() {
        guard SKDisplay.pad else { return }
        view.layoutIfNeeded()
        let pageWidth = self.view.bounds.width
        let pageHeight = self.backgroundScrollView.bounds.height
        guard tabViews.count > 0 else { return }
        var totalWidth: CGFloat = 0
        DocsLogger.info("模版中心 change frame pagewidth:\(pageWidth)")
        tabViews.forEach { (tabView) in
            tabView.frame = CGRect(x: totalWidth, y: 0, width: pageWidth, height: pageHeight)
            tabView.updateHostViewWidth(pageWidth)
            totalWidth += pageWidth
        }
        view.layoutIfNeeded()
        if let selectIndex = typeChooseView.currentSelectIndex() {
            let scrollWidth = CGFloat(selectIndex) * pageWidth
            self.backgroundScrollView.setContentOffset(CGPoint(x: scrollWidth, y: 0), animated: false)
        }
    }
}
