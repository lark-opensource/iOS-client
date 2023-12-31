//
//  TemplateSearchViewController.swift
//  SKCommon
//
//  Created by bytedance on 2020/12/29.
//
// swiftlint:disable file_length

import UIKit
import SKUIKit
import SKFoundation
import SKResource
import EENavigator
import RxSwift
import Lottie
import LarkTraitCollection
import UniverseDesignActionPanel
// nolint: duplicated_code
final class TemplateSearchViewController: BaseViewController {
    public var trackParamter: DocsCreateDirectorV2.TrackParameters = DocsCreateDirectorV2.TrackParameters.default()
    private let source: TemplateCenterTracker.EnterTemplateSource
    private let templateSource: TemplateCenterTracker.TemplateSource?
    private let mountLocation: WorkspaceCreateLocation
    private var director: DocsCreateDirectorV2?

    private var moreHandler: TemplateCenterMoreHandler?
    
    private weak var targetPopVC: UIViewController?

    private var currentTabViewType: TemplateMainType = .gallery
    
    private let disposeBag = DisposeBag()

    // dependency
    let templateSearchVM: TemplateSearchViewModel
    
    lazy var searchBar = { () -> DocsHomeSearchBar in
        let searchBar = DocsHomeSearchBar(frame: .zero)
        searchBar.delegate = self
        searchBar.cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return searchBar
    }()
    
    lazy var typeChooseView: TemplateTypeChooseView = {
        let typeNames = tabViews.map({ $0.tabName })
        let chooseView = TemplateTypeChooseView(names: typeNames, isBlueLineAlignToText: true)
        chooseView.select(at: 0, animated: false)
        chooseView.delegate = self
        return chooseView
    }()
    
    private lazy var tabViews: [TemplateSearchResultView] = {
        return self.supportMainTypes.map { (type) -> TemplateSearchResultView in
            switch type {
            case .gallery:
                return galleryTabView
            case .custom:
                return customTabView
            case .business:
                return businessTabView
            }
        }
    }()
    private let supportMainTypes: [TemplateMainType] = {
        var types: [TemplateMainType] = [.gallery, .custom]
        if LKFeatureGating.templateV4BusinessEnable {
            types.append(.business)
        }
        return types
    }()

    private lazy var galleryTabView = TemplateSearchResultView(
        tabName: BundleI18n.SKResource.Doc_List_v4TemplateGallery(),
        hostViewSize: hostViewSize,
        templateSource: templateSource,
        mainType: .gallery
    )
    private lazy var customTabView = TemplateSearchResultView(
        tabName: BundleI18n.SKResource.Doc_List_CustomTemplate,
        hostViewSize: hostViewSize,
        templateSource: templateSource,
        mainType: .custom
    )
    private lazy var businessTabView = TemplateSearchResultView(
        tabName: BundleI18n.SKResource.Doc_List_EnterpriseTemplate,
        hostViewSize: hostViewSize,
        templateSource: templateSource,
        mainType: .business
    )
        
    lazy var recommendView = TemplateSearchRecommendView(hostViewWidth: hostViewSize.width)
    let hostViewSize: CGSize
    var hadAutoShowKeyboard = false
    var isSearchingRecommendWord = false // 搜索的是否为推荐热词
    
    init(templateSearchVM: TemplateSearchViewModel,
         hostViewSize: CGSize,
         mountLocation: WorkspaceCreateLocation,
         targetPopVC: UIViewController?,
         source: TemplateCenterTracker.EnterTemplateSource,
         templateSource: TemplateCenterTracker.TemplateSource?) {
        self.templateSearchVM = templateSearchVM
        self.hostViewSize = hostViewSize
        self.mountLocation = mountLocation
        self.targetPopVC = targetPopVC
        self.source = source
        self.templateSource = templateSource
        super.init(nibName: nil, bundle: nil)
        self.moreHandler = TemplateCenterMoreHandler(networkAPI: TemplateDataProvider(), fromPage: .searchResult)
        self.moreHandler?.templateSource = templateSource
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isViewDidAppear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bindAction()
        loadRecommendData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TemplateCellLayoutInfo.isRegularSize = self.view.isMyWindowRegularSize()
        if !isViewDidAppear {
            searchBar.searchTextField.becomeFirstResponder()
        }
        self.isViewDidAppear = true
    }

    public override func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
        super.viewDidTransition(from: oldSize, to: size)
        guard size != oldSize else { return }
        tabViews.forEach({ $0.refreshLayout(width: self.view.bounds.size.width) })
    }
    
    public override func viewDidSplitModeChange() {
        super.viewDidSplitModeChange()
        tabViews.forEach({ $0.refreshLayout(width: self.view.bounds.size.width) })
    }

    private func setupUI() {
        navigationBar.addSubview(searchBar)
        if SKDisplay.pad {
            navigationBar.sizeType = .formSheet
        }
        view.addSubview(typeChooseView)
        tabViews.forEach({ (tabView) in
            self.view.addSubview(tabView)
        })
        view.addSubview(recommendView)
        
        setupSubviewsConstrains()
        
        galleryTabView.delegate = self
        customTabView.delegate = self
        businessTabView.delegate = self        
        recommendView.delegate = self
        searchBar.searchTextField.placeholder = BundleI18n.SKResource.Doc_List_TemplateSearchHint
    }
    
    private func setupSubviewsConstrains() {
        searchBar.snp.makeConstraints { make in
            let leftOffset = SKDisplay.pad ? 56 : 45
            make.left.equalToSuperview().offset(leftOffset)
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalTo(navigationBar)
        }
        searchBar.cancelButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.width.equalTo(55)
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }
        searchBar.searchTextField.snp.makeConstraints { make in
            make.right.equalTo(searchBar.cancelButton.snp.left).offset(-12)
            make.left.centerY.equalToSuperview()
            make.height.equalTo(32)
        }
        
        var typeChooseViewH = 37
        if let source = self.templateSource , source.shouldUseNewForm() {
            typeChooseViewH = 0
        }
        typeChooseView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(typeChooseViewH)
        }
        tabViews.forEach({ (tabView) in
            tabView.snp.makeConstraints { make in
                make.top.equalTo(typeChooseView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        })
        recommendView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
    }
    
    private func loadMore() {
        if let keyword = templateSearchVM.keyword, !keyword.isEmpty {
            templateSearchVM.searchNextPageTemplates(docsType: source.isFromBitableHome ? .bitable : nil, tabType: currentTabViewType)
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] (event) in
                    guard let self = self else { return }
                    if case .next(let searchResult) = event {
                        self.reportSearchResult(searchResult)
                    } else if case .error = event {
                        self.reportSearchResult(nil)
                    }
                    self.updateTemplateSearchResultView(event: event, type: self.currentTabViewType)
                }.disposed(by: disposeBag)
        }
    }
    
    
    private func bindAction() {
        // 输入框文本改变
        _ = searchBar.searchTextField.rx.text.orEmpty.changed
            .takeUntil(searchBar.rx.deallocated)
            .subscribe(onNext: { [weak self] content in
                //self?.collectionView.es.resetNoMoreData()
                if let keyword = self?.templateSearchVM.keyword, keyword == content, keyword.isEmpty { return }
                self?.templateSearchVM.keyword = content
                self?.templateSearchVM.searchText.accept(content)
            }).disposed(by: disposeBag)
        
        // 文本输入
        _ = templateSearchVM.searchText.debounce(DispatchQueueConst.MilliSeconds_250, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .skip(1)
            .subscribe(onNext: { [weak self] text in
                guard let self = self else { return }
                self.isSearchingRecommendWord = false
                self.onSearch(keyword: text)
                if !text.isEmpty {
                    TemplateCenterTracker.reportSearchTemplateTracker(action: .inputSearchwords, searchWords: text)
                }
            }).disposed(by: disposeBag)
        TemplateCenterMoreHandler.didDeleteTemplateNotice.subscribe { [weak self] event in
            guard case .next(let template) = event, let self = self else {
                return
            }
            self.templateSearchVM.deleteTemplateInMemory(templateToken: template.objToken)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (result) in
                    guard let self = self else { return }
                    self.updateTemplateSearchResultView(event: .next(result), type: .custom)
                }).disposed(by: self.disposeBag)
        }
        .disposed(by: disposeBag)
    }
    
    private func loadRecommendData() {
        _ = templateSearchVM.fetchSearchTemplateRecommend()
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self](event) in
                switch event {
                case .next(let data):
                    TemplateCenterTracker.reportSearchTemplateTracker(action: .displaySearchRecommendWords, recommendword: nil)
                    self?.recommendView.updateDataSource(data)
                case .error(let error):
                    DocsLogger.error("load template search recommend key error: \(error)")
                case .completed: break
                @unknown default:
                   break
                }
            }).disposed(by: disposeBag)
    }
    private func getTabView(with tabType: TemplateMainType) -> TemplateSearchResultView {
        switch tabType {
        case .gallery:
            return galleryTabView
        case .custom:
            return customTabView
        case .business:
            return businessTabView
        }
    }
}

extension TemplateSearchViewController: SearchBarDelegate {
    public func searchBarDidActive() {
        DocsLogger.debug("searchBarDidActive")
        if hadAutoShowKeyboard {
            // 第一次搜索框成为firstresponder是代码做的，所以过滤第一次
            TemplateCenterTracker.reportSearchTemplateTracker(action: .clickSearchPlace, recommendword: nil)
        } else {
            hadAutoShowKeyboard = true
        }
    }
    public func searchBarDidClickCancel() {
        DocsLogger.debug("searchBarDidClickCancel")
        navigationController?.popViewController(animated: true)
    }

    public func searchContentDidChange(_ value: String) {
        DocsLogger.debug("searchContentDidChange:\(value)")
        changeSubviewHidden(isRecommendViewHidden: !value.isEmpty)
        if value.isEmpty {
            TemplateCenterTracker.reportClearKeywordAction()
            templateSearchVM.clearAllData()
            let empty = TemplateSearchResult.createEmptyResult()
            galleryTabView.updateSearchResult(empty, isSearchingRecommendWord: isSearchingRecommendWord)
            customTabView.updateSearchResult(empty, isSearchingRecommendWord: isSearchingRecommendWord)
            businessTabView.updateSearchResult(empty, isSearchingRecommendWord: isSearchingRecommendWord)
        } else {
            let tabView = getTabView(with: currentTabViewType)
            tabView.startLoading()
        }
        if !recommendView.isHidden {
            TemplateCenterTracker.reportSearchTemplateTracker(action: .displaySearchRecommendWords, recommendword: nil)
        }
    }

    @objc
    func onSearch(keyword: String) {
        templateSearchVM.keyword = keyword
        if keyword.isEmpty { return }
        DocsLogger.debug("ocSearch:\(keyword)")
        let tabView = getTabView(with: currentTabViewType)
        tabView.startLoading()
        templateSearchVM.searchFirstPageTemplates(searchKey: keyword, docsType: source.isFromBitableHome ? .bitable : nil, tabType: currentTabViewType)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (event) in
                guard let self = self else { return }
                self.updateTemplateSearchResultView(event: event, type: self.currentTabViewType)
                if case .next(let searchResult) = event {
                    self.reportSearchResultView(searchResult: searchResult)
                    self.reportSearchResult(searchResult)
                } else if case .error = event {
                    self.reportSearchResult(nil)
                }
                tabView.stopLoadingIfNeed()
            }.disposed(by: disposeBag)
    }
    
    private func updateTemplateSearchResultView(event: Event<TemplateSearchResult>, type: TemplateMainType) {
        let tabView = getTabView(with: type)
        tabView.stopLoadingIfNeed()
        switch event {
        case .next(let result):
            TemplateCenterTracker.reportSearchTemplateTracker(
                action: .searchResult,
                recommendword: nil,
                searchWords: nil,
                hasSearchResult: !result.templates.isEmpty
            )
            tabView.updateSearchResult(result, isSearchingRecommendWord: isSearchingRecommendWord)
        case .completed: break
        case .error(let error):
            DocsLogger.error("search template error:\(error)")
        @unknown default:
            break
        }
    }
    
    private func changeSubviewHidden(isRecommendViewHidden: Bool) {
        recommendView.isHidden = isRecommendViewHidden
        tabViews.forEach({ $0.isHidden = true })
        if let index = supportMainTypes.firstIndex(where: { $0 == currentTabViewType }),
           index < tabViews.count {
            let needHidden = !isRecommendViewHidden
            let change = (tabViews[index].isHidden != needHidden)
            tabViews[index].isHidden = needHidden
            let isEmpty = tabViews[index].dataSource.isEmpty
            if change, !needHidden, !isEmpty {
                // 防止先显示空图再显示loading
                tabViews[index].showBlankView(false)
            }
        }
    }
}

extension TemplateSearchViewController: TemplateTypeChooseViewDelegate {
    func templateTypeChooseView(_ templateTypeChooseView: TemplateTypeChooseView, didClickTypeAt index: Int) {
        if supportMainTypes.count > index {
            currentTabViewType = supportMainTypes[index]
        } else {
            spaceAssertionFailure("not match main type")
            currentTabViewType = .gallery
        }
        TemplateCenterTracker.reportSearchResultViewMainTypeSwitch(to: currentTabViewType)
        changeSubviewHidden(isRecommendViewHidden: true)
        
        // 检查key，触发搜索
        guard let keyword = templateSearchVM.keyword, !keyword.isEmpty,
                keyword != templateSearchVM.getResult(with: currentTabViewType).keyword else {
            return
        }
        onSearch(keyword: keyword)
    }
}
extension TemplateSearchViewController {
    func didClickTemplate(_ template: TemplateModel, of templates: [TemplateModel]) {
        switch template.type ?? .normal {
        case .normal: clickNormalTemplate(template, of: templates)
        case .collection, .ecology: clickTemplateCollection(template)
        }
        
    }
    private func clickNormalTemplate(_ template: TemplateModel, of templates: [TemplateModel]) {
        previewTemplate(template, of: templates)
    }
    private func previewTemplate(_ template: TemplateModel, of templates: [TemplateModel]) {
        let normalTemplates = templates.filter({ $0.type == nil || $0.type == .normal })
        guard let index = normalTemplates.firstIndex(where: { $0.id == template.id }) else {
            return
        }
        guard let previewVC = NormalTemplatesPreviewVC(templates: normalTemplates, currentIndex: index, templateSource: templateSource, templateCenterSource: .searchResult, sectionName: "") else {
            return
        }
        let extra = TemplateCenterTracker.formateStatisticsInfoForCreateEvent(source: source, categoryName: nil, categoryId: nil)
        let dependency = DocsCreateDependency(
            trackParamterModule: trackParamter.module,
            trackExtraParamter: extra,
            templateCenterSource: .templatecenterSearchresult,
            mountLocation: mountLocation,
            targetPopVC: targetPopVC
        )
        previewVC.docsCreateDependency = dependency
        previewVC.keyword = keywordsForReport()
        Navigator.shared.push(previewVC, from: self)
        TemplateCenterTracker.reportSearchTemplateTracker(
            action: .clickSearchResultTemplate,
            recommendword: nil,
            searchWords: nil,
            hasSearchResult: nil
        )
    }
    private func clickTemplateCollection(_ template: TemplateModel) {
        guard let collectionId = template.extra?.colletionId else { return }
        let vc = TemplateCollectionPreviewViewController(
            collectionId: collectionId,
            networkAPI: TemplateDataProvider(),
            templateSource: templateSource,
            templateCenterSource: .searchResult,
            type: template.type ?? .collection
        )
        Navigator.shared.push(vc, from: self)
        TemplateCenterTracker.clickTemplatePreview(from: .center)
    }
}

extension TemplateSearchViewController: TemplateSearchResultViewDelegate {
    func templateSearchResultViewDidClickOrScrollListView(_ searchResultView: TemplateSearchResultView) {
        searchBar.searchTextField.resignFirstResponder()
    }
    func templateSearchResultViewBeginLoadMore(_ searchResultView: TemplateSearchResultView) {
        self.loadMore()
    }
    func templateSearchResultView(_ searchResultView: TemplateSearchResultView, didClickTemplate template: TemplateModel) {
        self.didClickTemplate(template, of: searchResultView.dataSource)
    }
    func templateSearchResultView(_ searchResultView: TemplateSearchResultView, didClickMoreButton button: UIButton, for template: TemplateModel) {
        var popSource: TemplateCenterMoreHandler.PopSource?
        if SKDisplay.pad {
            popSource = TemplateCenterMoreHandler.PopSource(sourceView: button, sourceRect: .zero, arrowDirection: .any)
        }
        self.moreHandler?.showMoreActionSheet(templateModel: template, fromVC: self, popSource: popSource, needEdit: true)
    }
}

extension TemplateSearchViewController: TemplateSearchRecommendViewDelegate {
    func didSelectRecommendCell(_ recommend: TemplateSearchRecommend) {
        isSearchingRecommendWord = true
        searchBar.searchTextField.text = recommend.name
//        onSearch(keyword: recommend.name)
        searchBar.searchTextField.sendActions(for: .valueChanged)
        changeSubviewHidden(isRecommendViewHidden: true)
        TemplateCenterTracker.reportSearchTemplateTracker(action: .clickSearchRecommendWords, recommendword: recommend.name)
    }
}
extension TemplateSearchViewController {
    private func reportSearchResult(_ searchResult: TemplateSearchResult?) {
        var hasData = false
        if let searchResult = searchResult {
            hasData = !searchResult.templates.isEmpty
        }
        TemplateCenterTracker.reportSearchAction(
            keyword: keywordsForReport(),
            type: isSearchingRecommendWord ? .recommend : .search,
            hasResult: hasData,
            templateSource: templateSource,
            templateType: self.currentTabViewType.toTemplateType()
        )
    }
    
    private func reportSearchResultView(searchResult: TemplateSearchResult) {
        var otherParams: [String: Any] = [:]
        otherParams["result"] = searchResult.templates.count > 0 ? true : false
        otherParams["keywords"] = self.keywordsForReport()
        otherParams["template_type"] = self.currentTabViewType.toTemplateType().trackValue()
        TemplateCenterTracker.reportPageViewEvent(
            page: .searchResult,
            templateSource: templateSource,
            otherParams: otherParams
        )
    }
    
    private func keywordsForReport() -> String {
        return isSearchingRecommendWord ? (templateSearchVM.keyword ?? "") : "input"
    }
}
extension TemplateMainType {
    fileprivate func toTemplateType() -> TemplateModel.Source {
        switch self {
        case .gallery: return .system
        case .business: return .business
        case .custom: return .custom
        }
    }
}
