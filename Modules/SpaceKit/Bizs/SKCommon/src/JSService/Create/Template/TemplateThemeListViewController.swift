//
//  TemplateThemeListViewController.swift
//  SKCommon
//
//  Created by SZEECI on 2021/1/22.
//

import SKFoundation
import SKUIKit
import Lottie
import RxSwift
import RxCocoa
import SnapKit
import SKResource

import EENavigator
import UniverseDesignColor
import UniverseDesignIcon
import SpaceInterface
import SKInfra

public final class TemplateThemeListViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    public weak var selectedDelegate: TemplateSelectedDelegate?
    public var templatePageConfig: TemplatePageConfig? {
        didSet {
            self.viewModel.templatePageConfig = self.templatePageConfig
        }
    }
    // data
    private var dataSource: [TemplateModel] = []
    private var result: TemplateThemeResult?
    private var bannerImage: UIImage?
    
    // view
    private lazy var bannerImageView: UIImageView = UIImageView()
    private lazy var navibarBottomLineView: UIView = UIView()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: leftPadding, left: leftPadding, bottom: 20, right: leftPadding)
        layout.minimumLineSpacing = 12
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = UDColor.bgBase
        return cv
    }()
    private lazy var defaultLoadingView: DocsLoadingViewProtocol = {
        DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()
    private var errorView: UIView?

    private let viewModel: TemplateThemeViewModel
    private var fromViewWidth: CGFloat
    private var filterType: FilterItem.FilterType?
    private var trackParamter: DocsCreateDirectorV2.TrackParameters = DocsCreateDirectorV2.TrackParameters.default()
    private var needReportFilterAction = false
    private let mountLocation: WorkspaceCreateLocation
    private let source: TemplateCenterTracker.EnterTemplateSource
    private let templateSource: TemplateCenterTracker.TemplateSource?
    private var director: DocsCreateDirectorV2?
    private weak var targetPopVC: UIViewController?
    private let leftPadding: CGFloat = 16
    private var bannerHeaderSize: CGSize = .zero
    private var objType: DocsType?
    
    public init(fromViewWidth: CGFloat,
                viewModel: TemplateThemeViewModel,
                filterType: FilterItem.FilterType?,
                objType: Int? = nil,
                mountLocation: WorkspaceCreateLocation,
                targetPopVC: UIViewController?,
                source: TemplateCenterTracker.EnterTemplateSource,
                templateSource: TemplateCenterTracker.TemplateSource?) {
        self.fromViewWidth = fromViewWidth
        self.viewModel = viewModel
        self.filterType = filterType
        self.mountLocation = mountLocation
        self.targetPopVC = targetPopVC
        self.source = source
        self.templateSource = templateSource
        if let type = objType {
            self.objType = DocsType(rawValue: type)
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindAction()
        loadData()
        
        if #available(iOS 13.0, *), let isModal = self.templatePageConfig?.isModalInPresentation {
            self.isModalInPresentation = isModal
        }
        reportViewShow()
    }
    
    public override func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
        super.viewDidTransition(from: oldSize, to: size)
        TemplateCellLayoutInfo.isRegularSize = self.view.isMyWindowRegularSize()
        guard size != oldSize else { return }
        updateHeaderViewSize()
        collectionView.reloadData()
    }

    public override func viewDidSplitModeChange() {
        super.viewDidSplitModeChange()
        TemplateCellLayoutInfo.isRegularSize = self.view.isMyWindowRegularSize()
        updateHeaderViewSize()
        collectionView.reloadData()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.selectedDelegate?.templateOnEvent(onEvent: .willClose(type: .select))
    }
    
    public override func logNavBarEvent(_ event: DocsTracker.EventType,
                                        click: String? = nil,
                                        target: String? = "none",
                                        extraParam: [String: String]? = nil) {
        if let clickItem = click {
            self.selectedDelegate?.templateOnEvent(onEvent: .onNavigationItemClick(item: clickItem))
        }
        super.logNavBarEvent(event, click: click, target: target, extraParam: extraParam)
    }
    
    public override var canShowBackItem: Bool {
        if self.templatePageConfig?.showCloseButton == true {
            return false
        }
        return super.canShowBackItem
    }
    
    private func setupUI() {
        title = BundleI18n.SKResource.Doc_List_AllTemplateTitle
        navibarBottomLineView.backgroundColor = UDColor.lineDividerDefault
        
        view.addSubview(collectionView)
        view.addSubview(navibarBottomLineView)
        view.addSubview(defaultLoadingView.displayContent)

        navibarBottomLineView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
            make.height.equalTo(1)
        }
        collectionView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navibarBottomLineView.snp.bottom)
        }

        defaultLoadingView.displayContent.snp.makeConstraints { (make) in
            make.edges.equalTo(collectionView)
        }
        setupLeftBarItem()
        setupUIProperties()
        setupNetworkMonitor()
    }

    private func setupUIProperties() {
        collectionView.register(TemplateThemeHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TemplateThemeHeaderView.reuseIdentifier)
        collectionView.register(TemplateCenterCell.self, forCellWithReuseIdentifier: TemplateCenterCell.reuseIdentifier)
        collectionView.register(TemplateCreateBlankDocsCell.self, forCellWithReuseIdentifier: TemplateCreateBlankDocsCell.cellID)

    }
    private func updateHeaderViewSize() {
        if self.bannerImage == nil {
            self.bannerHeaderSize = .zero
        } else {
            let width = self.view.frame.width
            let height = width * 128.0 / 343.0 + leftPadding
            self.bannerHeaderSize = CGSize(width: width, height: height)
        }
    }
    ///fromsheet模式导航栏左侧关闭按钮
    private func setupLeftBarItem() {
        if (SKDisplay.pad && self.navigationController?.viewControllers.first == self) ||
            self.templatePageConfig?.showCloseButton == true {
            navigationBar.leadingBarButtonItems = [closeButtonItem]
        }
    }
    private func bindAction() {
        viewModel.input.initTemplates.subscribe(onNext: { [weak self] in
            self?.setLoadingViewShow(true)
        }).disposed(by: disposeBag)
        
        viewModel.bannerImageRelay
            .asObservable()
            .subscribe(onNext: { [weak self] (image) in
                if let image = image, let self = self {
                    self.bannerImage = image
                    self.updateHeaderViewSize()
                    self.collectionView.reloadData()
                }
            }).disposed(by: disposeBag)
        
        viewModel.templateThemeResultUpdated
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                self.setLoadingViewShow(false)
                switch event {
                case .next(let result):
                    self.errorView?.removeFromSuperview()
                    self.errorView = nil
                    self.updateTemplateThemeRusult(result)
                    self._updateRightBarItem(self.viewModel.input.filterTemplates.value)
                    self.reportFilterActionIfNeed(hasData: { !result.templates.isEmpty })
                    DocsLogger.info("show templates:\(result.templates.count)", component: LogComponents.template)
                    if result.templates.isEmpty {
                        self.showErrorView(TemplateSpecialViewProvider.makeTemplateThemeBlankView(targetViewWidth: self.view.frame.size.width))
                    }
                case .error(let error):
                    self.reportFilterActionIfNeed(hasData: { false })
                    DocsLogger.error("get templates err", error: error, component: LogComponents.template)
                    if let error = error as? TemplateError, (error == .themeNoData || error == .filterTypeNoData) {
                        self.showErrorView(TemplateSpecialViewProvider.makeTemplateThemeBlankView(targetViewWidth: self.view.frame.size.width))
                        if error == .filterTypeNoData {
                            self._updateRightBarItem(self.viewModel.input.filterTemplates.value)
                        }
                        return
                    }
                    // show net error page
                    let errorView = TemplateSpecialViewProvider.makeNoNetworkView(handler: { [weak self] in
                        self?.viewModel.input.initTemplates.onNext(())
                    }, bag: self.disposeBag)
                    self.showErrorView(errorView)
                case .completed: break
                @unknown default:
                    break
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.showFilterView
            .subscribe(onNext: {[weak self] (items) in
                guard let self = self else { return }
                let selection = items.firstIndex(where: { $0.isSelected == true }) ?? 0
                let panelController = SpaceFilterPanelController(options: items, initialSelection: selection)
                panelController.delegate = self
                guard let rightBtn = self.navigationBar.trailingButtonBar.itemViews.first else { return }
                panelController.setupPopover(sourceView: rightBtn, direction: .up)
                self.present(panelController, animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }

    @objc
    private func showFilterView() {
        viewModel.input.showFilterView.onNext(())
    }
    
    private func _updateRightBarItem(_ filterType: FilterItem.FilterType?) {
    
        guard let filterType = filterType, !source.isFromBitableHome, !self.viewModel.isFromDocComponent else {
            navigationBar.trailingBarButtonItems = []
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
                                       bag: disposeBag)
        }
    
        navigationBar.trailingBarButtonItems = [filterItem]
    }
    
    private func showErrorView(_ view: UIView) {
        self.errorView?.removeFromSuperview()
        self.view.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(navibarBottomLineView.snp.bottom)
        }
        self.errorView = view
    }
    
    private func updateTemplateThemeRusult(_ result: TemplateThemeResult) {
        self.result = result
        self.dataSource = result.templates
        collectionView.reloadData()
    }

    private func loadData() {
        viewModel.input.initTemplates.onNext(())
        if let filterType = self.filterType {
            viewModel.input.filterTemplates.accept(filterType)
        } else {
            setFilterTypeByApplinkIfNeed()
        }
    }
    
    private func setFilterTypeByApplinkIfNeed() {
        guard let objType = self.objType else {
            return
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
        if let type = filterType {
            updateFilterValue(filterType: type)
        }
    }
    
    private func updateFilterValue(filterType: FilterItem.FilterType) {
        viewModel.input.filterTemplates.accept(filterType)
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
    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] _, _ in
            self?.collectionView.reloadData()
        }
    }
    
    private func reportTemplateDisplay(template: TemplateModel, index: Int) {
        let filterType = viewModel.input.filterTemplates.value
        var filterName: String?
        switch filterType {
        case .all:
            filterName = BundleI18n.SKResource.Doc_List_Filter_All
        case .doc:
            filterName = BundleI18n.SKResource.Doc_Facade_Document
        case .sheet:
            filterName = BundleI18n.SKResource.Doc_Facade_CreateSheet
        case .bitable:
            filterName = BundleI18n.SKResource.Doc_List_Filter_Bitable
        case .mindnote:
            filterName = BundleI18n.SKResource.Doc_Facade_MindNote
        default: return
        }
        TemplateCenterTracker.reportTemplateDisplay(template: template, from: .banner, category: filterName, templateSource: templateSource, sectionName: "", index: index)
    }
    
    private func reportViewShow() {
        TemplateCenterTracker.reportEnterTemplateCenterTracker(source: source)
    }
}

extension TemplateThemeListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let template = self.dataSource[indexPath.item]
        
        reportTemplateDisplay(template: template, index: indexPath.item)
        let hostViewWidth = fromViewWidth > 0 ? fromViewWidth : self.view.frame.width
        return TemplateCenterCell.getCell(
            collectionView,
            indexPath: indexPath,
            template: template,
            delegate: nil,
            hostViewWidth: hostViewWidth
        )
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let hideSubTitle = self.templatePageConfig?.hideItemSubTitle ?? false
        return TemplateCellLayoutInfo.inCenter(with: self.view.frame.width, withSubTitle: !hideSubTitle)
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                           withReuseIdentifier: TemplateThemeHeaderView.reuseIdentifier,
                                                                           for: indexPath) as? TemplateThemeHeaderView else {
            return UICollectionReusableView()
        }
        
        header.imageView.image = bannerImage
        return header
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return bannerHeaderSize
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            self.dataSource.count > indexPath.item else {
                spaceAssertionFailure("did click template out of range \(indexPath)")
                return
        }
        DocsLogger.info("did click template at \(indexPath)")
        let template = self.dataSource[indexPath.item]
        didClickTemplate(at: indexPath.item)
        TemplateCenterTracker.reportUseTemplate(
            template: template,
            from: .banner,
            templateSource: templateSource,
            category: nil,
            clickType: .preview,
            index: indexPath.item,
            filterName: viewModel.input.filterTemplates.value.reportName,
            sectionName: ""
        )
    }
}

extension TemplateThemeListViewController: SpaceFilterPanelDelegate {
    public func filterPanel(_ panel: SpaceFilterPanelController, didConfirmWith selection: FilterItem) {
        needReportFilterAction = true
        viewModel.input.filterTemplates.accept(selection.filterType)
    }

    public func didClickResetFor(filterPanel: SpaceFilterPanelController) {
        spaceAssertionFailure("模板中心 filter 面板不支持 reset")
    }
}

extension TemplateThemeListViewController {
    private func didClickTemplate(at index: Int) {
        let template = dataSource[index]
        if template.id.isEmpty || self.templatePageConfig?.clickTemplateItemType == .select {
            self.selectedDelegate?.templateOnItemSelected(self, item: template.toExternalItem())
            return
        }
        previewTemplate(at: index)
    }
    
    private func previewTemplate(at index: Int) {
        var newIndex = index
        if let blankIndex = dataSource.firstIndex(where: { $0.id.isEmpty }), index >= blankIndex, index > 0 {
            newIndex -= 1 //修正index
        }
        let previewTemplates = dataSource.filter { !$0.id.isEmpty }
        guard let previewVC = NormalTemplatesPreviewVC(templates: previewTemplates,
                                                       currentIndex: newIndex,
                                                       templateSource: templateSource,
                                                       templateCenterSource: .banner,
                                                       filterType: filterType) else {
            return
        }
        previewVC.selectedDelegate = self.selectedDelegate
        previewVC.templatePageConfig = self.templatePageConfig
        let extra = TemplateCenterTracker.formateStatisticsInfoForCreateEvent(source: source, categoryName: nil, categoryId: nil)
        let dependency = DocsCreateDependency(
            trackParamterModule: trackParamter.module,
            trackExtraParamter: extra,
            templateCenterSource: .templatecenterBanner,
            mountLocation: mountLocation,
            targetPopVC: targetPopVC
        )
        previewVC.docsCreateDependency = dependency
        Navigator.shared.push(previewVC, from: self)
    }
}

extension TemplateThemeListViewController {
    private func reportFilterActionIfNeed(hasData: () -> Bool) {
        guard needReportFilterAction else { return }
        needReportFilterAction = false
        var filterType: TemplateCenterTracker.FilterType
        switch viewModel.input.filterTemplates.value {
        case .all: filterType = .all
        case .doc: filterType = .doc
        case .sheet: filterType = .sheet
        case .mindnote: filterType = .mindnote
        case .bitable: filterType = .bitable
        case .slides, .wiki, .file, .document, .folder: return
        }
        let hasResult = hasData()
        TemplateCenterTracker.reportBannerFilterAction(filterType: filterType, hasResult: hasResult)
    }
}
