//
//  TemplateSearchResultView.swift
//  SKCommon
//
//  Created by bytedance on 2021/1/6.
//

import Foundation
import SKUIKit
import SKFoundation
import Lottie
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignButton
import UniverseDesignLoading

protocol TemplateSearchResultViewDelegate: AnyObject {
    func templateSearchResultViewDidClickOrScrollListView(_ searchResultView: TemplateSearchResultView)
    func templateSearchResultView(_ searchResultView: TemplateSearchResultView, didClickTemplate template: TemplateModel)
    func templateSearchResultViewBeginLoadMore(_ searchResultView: TemplateSearchResultView)
    func templateSearchResultView(_ searchResultView: TemplateSearchResultView, didClickMoreButton button: UIButton, for template: TemplateModel)
}
extension TemplateSearchResultViewDelegate {
    func templateSearchResultViewDidClickOrScrollListView(_ searchResultView: TemplateSearchResultView) {}
    func templateSearchResultView(_ searchResultView: TemplateSearchResultView, didClickTemplate template: TemplateModel) {}
    func templateSearchResultViewBeginLoadMore(_ searchResultView: TemplateSearchResultView) {}
    func templateSearchResultView(_ searchResultView: TemplateSearchResultView, didClickMoreButton button: UIButton, for template: TemplateModel) {}
}

final class TemplateSearchResultView: UIView {
    // data
    private(set) var dataSource = [TemplateModel]()
    private var searchResult = TemplateSearchResult(keyword: "", templates: [], hasMore: false, buffer: "")
    let tabName: String
    var isRequestingData: Bool = false
    var isSearchingRecommendWord = false

    // interface
    weak var delegate: TemplateSearchResultViewDelegate?

    // view
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 15.0
        layout.minimumInteritemSpacing = 0

        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UDColor.bgBody
        collectionView.register(TemplateCenterCell.self, forCellWithReuseIdentifier: TemplateCenterCell.reuseIdentifier)

        collectionView.register(TemplateEmptyDataCell.self, forCellWithReuseIdentifier: TemplateEmptyDataCell.cellID)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell") // 以防万一
        collectionView.register(TemplateNameHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TemplateNameHeaderView.reuseIdentifier)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)

        return collectionView
    }()

    private weak var errorView: UIView?

    private lazy var blankView: TemplateEmptyView = {
        let blankView = TemplateEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Template_Feedback_NoTemplateSearch),
                                                  imageSize: 100,
                                                  spaceBelowDescription: 2,
                                                  type: .searchFailed,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: nil,
                                                  secondaryButtonConfig: nil))
        return blankView
    }()

    private lazy var loadingView = UDLoading.loadingImageView()
    
    private lazy var whiteBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    
    private var hostViewSize: CGSize
    private let templateSource: TemplateCenterTracker.TemplateSource?
    var mainType: TemplateMainType?

    init(tabName: String,
         hostViewSize: CGSize,
         templateSource: TemplateCenterTracker.TemplateSource?,
         mainType: TemplateMainType? = nil) {
        self.tabName = tabName
        self.hostViewSize = hostViewSize
        self.templateSource = templateSource
        self.mainType = mainType
        super.init(frame: .zero)
        setupUI()
        setupNetworkMonitor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //iPad分屏、转屏情况下刷新布局
    func refreshLayout(width: CGFloat) {
        self.hostViewSize.width = width
        TemplateCellLayoutInfo.isRegularSize = self.isMyWindowRegularSize()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupUI() {
        addSubview(collectionView)
        addSubview(blankView)
        addSubview(whiteBgView)
        addSubview(loadingView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        collectionView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let self = self else { return }
            self.delegate?.templateSearchResultViewBeginLoadMore(self)
        }
        
        blankView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        whiteBgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        loadingView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-120)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapScrollView))
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)
        
        loadingView.isHidden = true
        whiteBgView.isHidden = true
        showBlankView(false)
    }

    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] _, _ in
            self?.collectionView.reloadData()
        }
    }
    
    private func setLoadingViewShow(_ show: Bool) {
        loadingView.isHidden = !show
        whiteBgView.isHidden = !show
    }
    
    func startLoading() {
        setLoadingViewShow(true)
        isRequestingData = true
    }
    
    func stopLoadingIfNeed() {
        setLoadingViewShow(false)
        isRequestingData = false
    }
    
    func showBlankView(_ show: Bool) {
        blankView.isHidden = !show
        blankView.empty.isHidden = !show
    }
    
    private func getTemplateOfCell(_ cell: UICollectionViewCell) -> TemplateModel? {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            DocsLogger.warning("can not find correct template indexpath")
            return nil
        }
        guard
            self.dataSource.count > indexPath.item else {
                spaceAssertionFailure("did click template out of range \(indexPath)")
                return nil
        }
        DocsLogger.info("did click template at \(indexPath)")
        return dataSource[indexPath.item]
    }
}

extension TemplateSearchResultView {
    func updateSearchResult(_ result: TemplateSearchResult, isSearchingRecommendWord: Bool) {
        searchResult = result
        self.isSearchingRecommendWord = isSearchingRecommendWord
        dataSource = searchResult.templates
        collectionView.reloadData()
        
        self.collectionView.es.stopLoadingMore()
        self.collectionView.footer?.noMoreData = !result.hasMore
        self.collectionView.footer?.isHidden = !result.hasMore
        showBlankView(dataSource.isEmpty)
    }
}

extension TemplateSearchResultView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let template = self.dataSource[indexPath.item]
        TemplateCenterTracker.reportTemplateDisplay(
            template: template,
            from: .searchResult,
            category: nil,
            templateSource: templateSource,
            otherParams: ["keywords": self.keywordsForReport()],
            sectionName: "",
            index: indexPath.item
        )
        return TemplateCenterCell.getCell(
            collectionView,
            indexPath: indexPath,
            template: template,
            delegate: self,
            hostViewWidth: hostViewSize.width,
            mainTabType: mainType
        )
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return TemplateCellLayoutInfo.inCenter(with: hostViewSize.width)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                               withReuseIdentifier: TemplateNameHeaderView.reuseIdentifier,
                                                                               for: indexPath) as? TemplateNameHeaderView else {
                return UICollectionReusableView()
            }
        
            let keyword = searchResult.keyword
            var str = ""
            if !keyword.isEmpty {
                str = BundleI18n.SKResource.Doc_List_TemplateSearchResult(keyword)
            }
       
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.N900, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
            let finalStr = NSMutableAttributedString(string: str,
                                                     attributes: attributes)
            
            let newStr = NSString(string: str)
            let range = newStr.range(of: keyword)
            if range.location != NSNotFound {
                finalStr.removeAttribute(NSAttributedString.Key.foregroundColor, range: range)
                finalStr.addAttribute(.foregroundColor, value: UIColor.ud.colorfulBlue, range: range)
            }
            
            header.tipLabel.attributedText = finalStr
            return header
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.hostViewSize.width, height: 44)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.dataSource.count > indexPath.item else {
            spaceAssertionFailure("did click template out of range \(indexPath)")
            return
        }
        let template = self.dataSource[indexPath.item]
        delegate?.templateSearchResultView(self, didClickTemplate: template)
        reportTemplateClick(template, indexPath.item)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.templateSearchResultViewDidClickOrScrollListView(self)
    }
    
    @objc
    func tapScrollView() {
        delegate?.templateSearchResultViewDidClickOrScrollListView(self)
    }
}

extension TemplateSearchResultView: TemplateBaseCellDelegate {
    func didClickMoreButtonOfCell(cell: TemplateBaseCell) {
        if let template = getTemplateOfCell(cell) {
            delegate?.templateSearchResultView(self, didClickMoreButton: cell.moreButton, for: template)
        }
    }
}

extension TemplateSearchResultView {
    private func reportTemplateClick(_ template: TemplateModel, _ index: Int) {
        var otherParams: [String: Any] = [:]
        otherParams["keywords"] = keywordsForReport()
        TemplateCenterTracker.reportUseTemplate(
            template: template,
            from: .searchResult,
            templateSource: templateSource,
            category: nil,
            clickType: .preview,
            index: index,
            filterName: "",
            sectionName: searchResult.keyword,
            otherParams: otherParams
        )
    }
    private func keywordsForReport() -> String {
        return isSearchingRecommendWord ? searchResult.keyword : "input"
    }
}
