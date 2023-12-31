//
//  TemplateTabView.swift
//  SKCommon
//
//  Created by 邱沛 on 2020/9/16.
//
// swiftlint:disable file_length

import RxSwift
import SKFoundation
import SKUIKit
import SKResource
import SnapKit
import UniverseDesignColor
import UIKit
import UniverseDesignActionPanel
import RxCocoa

class TemplateTabView: UIView {

    // interface
    var notifyDelegateDidClickCellForTemplate: ((TemplateCenterViewModel.Section, TemplateModel) -> Void)?
    var notifyLoadMore: ((TemplateCenterViewModel.Category) -> Void)?
    var notifyClickBanner: ((Int, TemplateBanner) -> Void)?
    var notifyClickCellsMoreButton: ((TemplateModel, UIButton) -> Void)?
    var notifyDidChooseACategory: ((TemplateCenterViewModel.Category) -> Void)?
    let updateDataSource = PublishSubject<Categories>()
    let showErrorPage = PublishSubject<UIView>()
    let appendPageData = PublishSubject<TemplateCenterViewModel.CategoryPageInfo>()
    // model
    private let mainType: TemplateMainType
    private var categoryFilterNames: [String]
    private var categories: Categories
    private var curSelName: String?
    let tabName: String
    private(set) var visibleDataSource: TemplateCenterViewModel.Category?
    private var templateBanner: [TemplateBanner] = []
    //每行最多的item个数
    private let maxLineNum: CGFloat = 6
    private let leftSpacing: CGFloat = 16
    private let minimumInteritemSpacing: CGFloat = 4
    
    private var bannerHeight: CGFloat = 128 + 16 + 5 //这是默认值，runtime会根据当前VC的width动态计算

    let filterType = BehaviorRelay<FilterItem.FilterType>(value: .all)
    
    // UI
    lazy var categoriesView: TemplateCategoriesView = {
        let categoriesView = TemplateCategoriesView(categoryNames: categoryFilterNames, tabName: tabName) { [weak self] (categoryName) in
            guard let self = self else { return }
            guard let category = self.categories.first(where: { $0.name == categoryName }) else { return }
            TemplateCenterTracker.reportCategoryClick(mainType: self.mainType,
                                                      category: category,
                                                      templateSource: self.templateSource,
                                                      filterName: self.filterType.value.reportName)
        }
        return categoriesView
    }()

    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16.0
        layout.minimumInteritemSpacing = minimumInteritemSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: leftSpacing, bottom: 0, right: leftSpacing)
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UDColor.bgBase
        collectionView.register(TemplateCenterCell.self, forCellWithReuseIdentifier: TemplateCenterCell.reuseIdentifier)
        collectionView.register(TemplateCreateBlankDocsCell.self, forCellWithReuseIdentifier: TemplateCreateBlankDocsCell.cellID)
        collectionView.register(TemplateEmptyDataCell.self, forCellWithReuseIdentifier: TemplateEmptyDataCell.cellID)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell") // 以防万一
        collectionView.register(TemplateNameHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TemplateNameHeaderView.reuseIdentifier)
        

        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        collectionView.delegate = self
        collectionView.dataSource = self

        return collectionView
    }()
    
    private lazy var bannerView: TemplateBannerView = {
        let view = TemplateBannerView()
        view.delegate = self
        return view
    }()

    private weak var errorView: UIView?

    private let bag = DisposeBag()
    private var hostViewWidth: CGFloat = 0
    private let templateSource: TemplateCenterTracker.TemplateSource?

    init(categories: Categories = [],
         categoryFilterNames: [String] = [],
         tabName: String,
         mainType: TemplateMainType,
         templateSource: TemplateCenterTracker.TemplateSource?) {
        self.mainType = mainType
        self.categories = categories
        self.visibleDataSource = categories.first
        self.categoryFilterNames = categoryFilterNames
        self.tabName = tabName
        self.templateSource = templateSource
        super.init(frame: .zero)
        setupUI()
        setupNetworkMonitor()
        bindAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(categoriesView)
        categoriesView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(categoriesView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        collectionView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let self = self, let visibleDataSource = self.visibleDataSource else { return }
            self.notifyLoadMore?(visibleDataSource)
        }
    }

    private func bindAction() {
        categoriesView.selectedIndex
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] (index) in
                guard let self = self, let categoryName = self.categoriesView.selectedName else { return }
                self.errorView?.removeFromSuperview()
                self.visibleDataSource = self.dataSource(at: index)
                self.addStatistics(for: categoryName)
                self.notifyDidChooseACategory(for: categoryName)
                self.handleBanner(for: categoryName)
                self.collectionView.reloadData()
                self.updateFooter()
                self.autoLoadMoreIfNeed()
            }).disposed(by: bag)

        updateDataSource
            .subscribe(onNext: {[weak self] dataSource in
                guard let self = self else { return }
                TemplateCellLayoutInfo.isRegularSize = self.isMyWindowRegularSize()
                self.errorView?.removeFromSuperview()
                self.categories = dataSource
                self.updateCategoryView(with: dataSource.map({ $0.name }))
                if let curSelName = self.curSelName {
                    self.notifyDidChooseACategory(for: curSelName)
                }
                self.visibleDataSource = self.dataSource(at: self.categoriesView.selectedIndex.value)

                UIView.performWithoutAnimation {
                    self.collectionView.reloadData()
                }
                
                self.collectionView.es.stopLoadingMore()
                self.collectionView.footer?.noMoreData = !(self.visibleDataSource?.hasMore ?? false)
                self.collectionView.footer?.isHidden = !(self.visibleDataSource?.hasMore ?? false)
                self.autoLoadMoreIfNeed()
            }).disposed(by: bag)

        appendPageData
            .subscribe(onNext: {[weak self] (pageInfo) in
                guard let self = self, let category = self.categories.first(where: { $0.id == pageInfo.categoryId }) else { return }
                category.hasMore = pageInfo.hasMore
                category.currentPage = pageInfo.pageIndex
                category.sections.first?.appendNewTemplates(pageInfo.templates)
                if self.visibleDataSource?.id == category.id {
                    self.updateFooter()
                    self.collectionView.reloadData()
                }
            }).disposed(by: bag)
        
        showErrorPage
            .subscribe(onNext: {[weak self] (view) in
                guard let self = self else { return }
                self.showErrorView(view, with: { make in
                    make.edges.equalToSuperview()
                })
            }).disposed(by: bag)
    }

    private func dataSource(at index: Int?) -> TemplateCenterViewModel.Category? {
        guard let index = index else { return nil }
        guard index >= 0, index < categories.count else { return nil }
        return categories[index]
    }
    
    private func handleBanner(for filterName: String) {
        if tabName == BundleI18n.SKResource.Doc_List_v4TemplateGallery() {
            if templateBanner.isEmpty {
                resetBanner(isHidden: true)
            } else {
                resetBanner(isHidden: filterName != BundleI18n.SKResource.Doc_List_All)
            }
        } else {
            resetBanner(isHidden: true)
        }
    }

    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] _, _ in
            self?.collectionView.reloadData()
        }
    }

    private func showErrorView(_ view: UIView,
                               with layout: ((ConstraintMaker) -> Void)) {
        self.errorView?.removeFromSuperview()
        self.addSubview(view)
        view.snp.makeConstraints { (make) in
            layout(make)
        }
        self.errorView = view
    }
    // 因为每个分类初始模板个数最多4个，太少了，这里自动拉取更多数据
    private func autoLoadMoreIfNeed() {
        guard let visibleDataSource = visibleDataSource,
              visibleDataSource.name != BundleI18n.SKResource.Doc_List_All,
              let section = visibleDataSource.sections.first,
              section.templates.count < TemplateDataProvider.pageSize,
              visibleDataSource.hasMore else {
            return
        }
        self.notifyLoadMore?(visibleDataSource)
    }

    func updateTargetCategory(index: Int?) {
        categoriesView.updateTargetCategory(index: index)
    }
    
    func updateHostViewWidth(_ width: CGFloat) {
        guard abs(self.hostViewWidth - width) > .ulpOfOne else { return }
        self.hostViewWidth = width
        TemplateCellLayoutInfo.isRegularSize = self.isMyWindowRegularSize()
        if !templateBanner.isEmpty/*!bannerView.isHidden*/ {
            updateBannerViewFrame(width)
            DocsLogger.debug("bannerView height debug: \(bannerHeight), from updateHostViewWidth: \(width)")
        }
        // 重新计算cellSize，将宽度信息传给cell，进行重新布局
        bannerView.updateHostViewWidth(width)
        collectionView.reloadData()
        layoutIfNeeded()
    }
    
    private func updateFooter() {
        var hasMore = false
        if let category = self.visibleDataSource, category.hasMore {
            hasMore = true
        }
        self.collectionView.es.stopLoadingMore()
        self.collectionView.footer?.noMoreData = !hasMore
        self.collectionView.footer?.isHidden = !hasMore
    }
    
    func updateBannerData(data: [TemplateBanner]) {
        templateBanner = data
        if data.isEmpty {
            resetBanner(isHidden: true)
            collectionView.reloadData()
            return
        }
        
        if bannerView.superview == nil {
            collectionView.addSubview(bannerView)
        }
        updateBannerViewFrame(hostViewWidth)
        bannerView.updateTemplateBanner(data)
        DocsLogger.debug("bannerView height debug: \(bannerHeight), from updateBannerData")
        if let curSelName = self.curSelName {
            handleBanner(for: curSelName)
        } else {
            resetBanner(isHidden: false)
        }
    }
    private func updateBannerViewFrame(_ width: CGFloat) {
        let contentWidth = width - 2 * leftSpacing
        bannerHeight = SKDisplay.pad ?
            contentWidth * 110.0 / 680.0 + leftSpacing :
            contentWidth * 128.0 / 343.0 + 2 * leftSpacing
        DocsLogger.debug("bannerView height debug bannerHeight: \(bannerHeight), templateTabView.frame.width: \(self.frame.width)")
        collectionView.contentInset.top = bannerHeight
        collectionView.setContentOffset(CGPoint(x: 0, y: -bannerHeight), animated: false)
        bannerView.frame = CGRect(x: 0, y: -bannerHeight, width: width, height: bannerHeight)
    }
    private func resetBanner(isHidden: Bool) {
        bannerView.isHidden = isHidden
        if isHidden {
            collectionView.contentInset.top = 0
            collectionView.setContentOffset(.zero, animated: false)

        } else {
            collectionView.contentInset.top = bannerHeight
            collectionView.setContentOffset(CGPoint(x: 0, y: -bannerHeight), animated: false)
            bannerView.isHidden = false
        }
    }
    
    func resetBannerAnimationIfNeed(isStart: Bool) {
        bannerView.resetBannerAnimationIfNeed(isStart: isStart)
    }
    
    func resetBannerScrollViewDelegate(isClear: Bool) {
        bannerView.resetScrollViewDelegate(isClear: isClear)
    }
    
    private func addStatistics(for filterName: String) {
        if let curCate = categories.first(where: { $0.name == filterName }) {
            SKCreateTracker.reportClickTemplateSecondaryFilter(primaryType: self.tabName, categoryId: curCate.id)
        }
    }
    
    private func notifyDidChooseACategory(for filterName: String) {
        
        guard let curCate = categories.first(where: { $0.name == filterName }) else {
            return
        }
        curSelName = filterName
        notifyDidChooseACategory?(curCate)
    }
    
    private func getTemplateOfCell(_ cell: UICollectionViewCell) -> TemplateModel? {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            DocsLogger.warning("can not find correct template indexpath")
            return nil
        }
        guard let visibleDataSource = self.visibleDataSource,
              visibleDataSource.sections.count > indexPath.section,
              visibleDataSource.sections[indexPath.section].templates.count > indexPath.item else {
                spaceAssertionFailure("did click template out of range \(indexPath)")
                return nil
        }
        DocsLogger.info("did click template at \(indexPath)")
        let template = visibleDataSource.sections[indexPath.section].templates[indexPath.item]
        return template
    }
    private func updateCategoryView(with categoryNames: [String]) {
        categoriesView.categoryNames = categoryNames
        categoriesView.snp.updateConstraints { (make) in
            make.height.equalTo(categoryNames.count > 1 ? 56 : 0)
        }
    }
}

extension TemplateTabView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.visibleDataSource?.sections.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let visibleDataSource = self.visibleDataSource,
              visibleDataSource.sections.count > section else {
            spaceAssertionFailure("numberOfItemsInSection for template out of range \(section)")
            return 0
        }
        return visibleDataSource.sections[section].templates.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if SKDisplay.pad {
            //适配iPad lift样式
            return UIEdgeInsets(top: 4, left: leftSpacing, bottom: 0, right: leftSpacing)
        } else {
            return UIEdgeInsets(top: 0, left: leftSpacing, bottom: 0, right: leftSpacing)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let visibleDataSource = self.visibleDataSource,
              visibleDataSource.sections.count > indexPath.section,
              visibleDataSource.sections[indexPath.section].templates.count > indexPath.item else {
                spaceAssertionFailure("cell for template out of range \(indexPath)")
                return collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
        }
        let section = visibleDataSource.sections[indexPath.section]
        let template = section.templates[indexPath.item]
        reportTemplateDisplay(template, sectionName: section.name, indexPath.item)
        return TemplateCenterCell.getCell(
            collectionView,
            indexPath: indexPath,
            template: template,
            delegate: self,
            hostViewWidth: hostViewWidth,
            mainTabType: mainType
        )
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let visibleDataSource = self.visibleDataSource,
              visibleDataSource.sections.count > indexPath.section,
              visibleDataSource.sections[indexPath.section].templates.count > indexPath.item else {
                spaceAssertionFailure("layout for template out of range \(indexPath)")
                return .zero
        }
        let template = visibleDataSource.sections[indexPath.section].templates[indexPath.item]
        let superViewWidth = hostViewWidth

        if template.style == .emptyData {
            return CGSize(width: superViewWidth, height: 248)
        }
        return TemplateCellLayoutInfo.inCenter(with: hostViewWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let superViewWidth = hostViewWidth
        let cellWidth = TemplateCellLayoutInfo.inCenter(with: superViewWidth).width
        var count = floor((superViewWidth - leftSpacing * 2 + minimumInteritemSpacing / 2) / (cellWidth + minimumInteritemSpacing))
        count = count > maxLineNum ? maxLineNum : count
        guard count > 1 else {
            return minimumInteritemSpacing
        }
        let miniSpacing = floor((superViewWidth - (count * cellWidth) - leftSpacing * 2) / (count - 1))
        return miniSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headerSupplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                               withReuseIdentifier: TemplateNameHeaderView.reuseIdentifier,
                                                                               for: indexPath)
            if let header = headerSupplementaryView as? TemplateNameHeaderView {
                guard let visibleDataSource = self.visibleDataSource,
                      visibleDataSource.sections.count > indexPath.section else {
                    spaceAssertionFailure("SupplementaryView for template out of range \(indexPath)")
                    return UICollectionReusableView()
                }
                header.tipLabel.text = visibleDataSource.sections[indexPath.section].name
                header.tipLabel.backgroundColor = .clear // 为了让cell的阴影不会被挡住
                header.backgroundColor = .clear
                return header
            }
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: hostViewWidth, height: 44)
        } else {
            return CGSize(width: hostViewWidth, height: 48)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let visibleDataSource = self.visibleDataSource,
              visibleDataSource.sections.count > indexPath.section,
              visibleDataSource.sections[indexPath.section].templates.count > indexPath.item else {
                spaceAssertionFailure("did click template out of range \(indexPath)")
                return
        }
        let section = visibleDataSource.sections[indexPath.section]
        let template = section.templates[indexPath.item]
        notifyDelegateDidClickCellForTemplate?(section, template)
        reportUseTemplate(template, section.name, indexPath.item)
    }
    
    private func reportUseTemplate(_ template: TemplateModel, _ sectionName: String, _ index: Int) {
        guard template.source != .createBlankDocs && template.source != .emptyData else {
            return
        }
        let from = mainType.toPageType()
        TemplateCenterTracker.reportUseTemplate(
            template: template,
            from: from,
            templateSource: templateSource,
            category: categoriesView.selectedName ?? "",
            clickType: .preview,
            index: index,
            filterName: filterType.value.reportName,
            sectionName: sectionName)
    }
    
    private func reportTemplateDisplay(_ template: TemplateModel, sectionName: String, _ index: Int) {
        let from = mainType.toPageType()
        TemplateCenterTracker.reportTemplateDisplay(template: template,
                                                    from: from,
                                                    category: categoriesView.selectedName, templateSource: templateSource,
                                                    otherParams: ["filter_status": filterType.value.reportName],
                                                    sectionName: sectionName,
                                                    index: index)
    }

}

extension TemplateTabView: TemplateBaseCellDelegate {
    func didClickMoreButtonOfCell(cell: TemplateBaseCell) {
        if let template = getTemplateOfCell(cell) {
            notifyClickCellsMoreButton?(template, cell.moreButton)
        }
    }
}

extension TemplateTabView: TemplateBannerViewDelegate {
    func didClickBanner(at index: Int, templateBanner: TemplateBanner) {
        notifyClickBanner?(index, templateBanner)
    }
}
