//
//  TemplateHorizontalListView.swift
//  SKCommon
//
//  Created by lijuyou on 2023/6/2.
//  

import UIKit
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import Lottie
import RxSwift
import SpaceInterface
import SKInfra
import EENavigator

public final class TemplateHorizontalListView: UIControl {
    weak var delegate: TemplateHorizontalListViewDelegate?
    
    public var collectionViewHeight: CGFloat {
        return templateParams.itemHeight
    }
    private lazy var failedView = TemplateSpecialViewProvider.makeFailViewForSuggestion()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = sectionInset
        layout.minimumLineSpacing = minimumLineSpacing
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        return cv
    }()
    private lazy var defaultLoadingView: DocsUDLoadingImageView = {
        let loading = DocsUDLoadingImageView()
        loading.isHidden = true
        return loading
    }()

    private(set) var templateDataSource = [TemplateModel]() {
        didSet {
            self.collectionView.reloadData()
        }
    }

    private var sectionInset: UIEdgeInsets {
        let padding: CGFloat = 16
        return templateParams.uiConfig?.sectionInset ?? UIEdgeInsets(top: 0, left: 16, bottom: padding, right: 16)
    }

    private var minimumLineSpacing: CGFloat {
        templateParams.uiConfig?.minimumLineSpacing ?? 20
    }

    private var showMoreTemplateView: Bool {
        templateParams.uiConfig?.showMoreTemplateView ?? true && hasMore
    }

    private var hasMore: Bool = false

    var isNetworkReachable: Bool {
        return DocsNetStateMonitor.shared.isReachable
    }

    private let bag = DisposeBag()
    lazy var viewModel: TemplateHorizontalListViewModel = {
        return generateTemplateViewModel()
    }()
    
    let templateParams: HorizontalTemplateParams
    var isStarted: Bool = false
    private let templateSource: TemplateCenterTracker.TemplateSource

    
    init(frame: CGRect,
         params: HorizontalTemplateParams,
         delegate: TemplateHorizontalListViewDelegate) {
        self.templateParams = params
        self.templateSource = TemplateCenterTracker.TemplateSource(params.templateSource)
        super.init(frame: frame)
        self.delegate = delegate
        setupDefaultValue()
        setupSubviews()
    }

    private func setupDefaultValue() {
        collectionView.register(TemplateHorizontalItemDefaultCell.self, forCellWithReuseIdentifier: TemplateHorizontalItemDefaultCell.reuseIdentifier)
        collectionView.register(TemplateHorizontalMoreItemCell.self, forCellWithReuseIdentifier: TemplateHorizontalMoreItemCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        self.backgroundColor = UDColor.bgFloat
    }
    private func setupSubviews() {
        self.addSubview(collectionView)
        self.addSubview(defaultLoadingView)
        self.addSubview(failedView)
        failedView.isHidden = true
        setupSubviewConstraints()
    }

    private func setupSubviewConstraints() {
        collectionView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(collectionViewHeight)
            make.bottom.equalToSuperview()
        }
        defaultLoadingView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(collectionView.snp.top)
            make.height.equalTo(3)// topSpaceView的存在导致Lottie view被挤到下面。topSpaceView的高度为superview的1/3，故这里把superview的高度设置得比较小，让topSpaceView的高度接近0
        }
        failedView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(collectionView.snp.top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startLoading() {
        hideFailedView()
        defaultLoadingView.isHidden = false
    }

    func endLoading() {
        hideFailedView()
        defaultLoadingView.isHidden = true
    }

    func showFailedView() {
        delegate?.templateHorizontalListView(self, onFailedStatus: true)
        self.bringSubviewToFront(failedView)
        failedView.isHidden = false
    }
    
    func hideFailedView() {
        failedView.isHidden = true
    }
    
    func reloadData() {
        collectionView.reloadData()
    }

    /// 更新模版数据源
    /// - Parameters:
    ///   - templates: 模版总数量，上限200
    ///   - hasMore: 是否包含所有模版
    func updateData(_ templates: [TemplateModel], hasMore: Bool) {
        /// 包含所有模版，但由于 pageSize 限制展示了部分时，需要展示 more view
        self.hasMore = hasMore || templates.count > templateParams.pageSize
        templateDataSource = templates
        collectionView.reloadData()
        if templates.isEmpty {
            showFailedView()
        } else {
            hideFailedView()
        }
    }
}

extension TemplateHorizontalListView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = min(templateDataSource.count, templateParams.pageSize)
        return count + (showMoreTemplateView ? 1 : 0)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemSize = collectionView.numberOfItems(inSection: indexPath.section)
        if showMoreTemplateView,
           indexPath.item == itemSize - 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TemplateHorizontalMoreItemCell.reuseIdentifier, for: indexPath)
            return cell
        } else {
            let template = templateDataSource[indexPath.item]
            return getDefaultCell(
                collectionView,
                indexPath: indexPath,
                template: template,
                delegate: nil,
                hostViewWidth: collectionView.frame.width)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return TemplateCellLayoutInfo.suggest(with: TemplateCellLayoutInfo.baseScreenWidth)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let fromVC = self.affiliatedViewController else {
            spaceAssertionFailure("must in vc")
            return
        }
        guard DocsNetStateMonitor.shared.isReachable else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_NoInternetClickMoreToast, on: fromVC.view ?? self)
            return
        }

        let itemsSize = collectionView.numberOfItems(inSection: indexPath.section)

        if showMoreTemplateView,
           indexPath.item == itemsSize - 1 {
            guard let fromVC = self.affiliatedViewController else {
                spaceAssertionFailure("must in vc")
                return
            }
            TemplateCenterTracker.reporBottomTemplateListClickMore(templateSource: self.templateSource)
            self.viewModel.handleClickMore(createController: fromVC)
            return
        }

        guard indexPath.item < self.templateDataSource.count else { return }
        
        let template = self.templateDataSource[indexPath.item]
        TemplateCenterTracker.reportUseTemplate(
            template: template,
            from: .horizontalListView,
            templateSource: templateSource,
            category: nil,
            clickType: .bottomTemplate,
            index: indexPath.item,
            filterName: "",
            sectionName: ""
        )
        
        let hasProc = delegate?.templateHorizontalListView(self, didClick: template.id) ?? false
        if hasProc {
            //如果业务拦截则不再处理
            return
        }
        
        guard let previewVC = NormalTemplatesPreviewVC(templates: self.templateDataSource,
                                                       currentIndex: indexPath.item,
                                                       templateSource: templateSource,
                                                       filterType: nil,
                                                       sectionName: nil) else {
            return
        }
        
        let dependency = DocsCreateDependency(
            trackParamterModule: .calendar,
            trackExtraParamter: nil,
            templateCenterSource: .templatecenterNormalcreate,
            mountLocation: .spaceDefault,
            targetPopVC: fromVC,
            createByTemplateHandler: createByTemplateHandler()
        )
        previewVC.docsCreateDependency = dependency
        previewVC.selectedDelegate = self.delegate
        previewVC.templatePageConfig = templateParams.templatePageConfig ?? TemplatePageConfig.default
        Navigator.shared.push(previewVC, from: fromVC, animated: true)
    }
    
    private func getDefaultCell(
        _ collectionView: UICollectionView,
        indexPath: IndexPath,
        template: TemplateModel,
        delegate: TemplateBaseCellDelegate?,
        hostViewWidth: CGFloat
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TemplateHorizontalItemDefaultCell.reuseIdentifier, for: indexPath)
        guard let templateCell = cell as? TemplateHorizontalItemDefaultCell else {
            return cell
        }
        templateCell.configCell(with: template, hostViewWidth: hostViewWidth)
        templateCell.delegate = delegate
        templateCell.resetNetStatus(isreachable: DocsNetStateMonitor.shared.isReachable)
        TemplateCenterTracker.reportShowSingleTemplateTracker(template)
        return templateCell
    }
}

extension TemplateHorizontalListView {
    
    /// 创建文档处理，useTemplateType=.create or .createAndOpen时会调用Handler
    private func createByTemplateHandler(trackParameters: DocsCreateDirectorV2.TrackParameters? = nil,
                                         successHandler: ((_ fileToken: String) -> Void)? = nil) -> (TemplateModel, UIViewController, @escaping CreateCompletion) -> Void {
        
        return {  [weak self] (model, vc, createCompletion)  in
            guard let self = self else { return }
            let createCallback: (DocsTemplateCreateResult?, Error?) -> Void = { [weak self] (result, error) in
                guard let self = self else { return }
                if let error = error {
                    DocsLogger.error("createByTemplateHandler error", error: error, component: LogComponents.template)
                }
                var token: String?
                var docsType: DocsType?
                if let urlString = result?.url, let url = URL(string: urlString) {
                    (token, docsType) = DocsUrlUtil.getFileInfoFrom(url)
                }
                DocsLogger.info("createByTemplateHandler finish", component: LogComponents.template)
                createCompletion(token, nil, docsType ?? .docX, result?.url, error)//回调给预览页
                self.delegate?.templateHorizontalListView(self, onCreateDoc: result, error: error)
            }
            
            TemplateAPIImpl.shared.createDocsByTemplate(docType: model.objType,
                                                        docToken: model.objToken,
                                                        templateId: model.id,
                                                        templateSource: self.templateSource.rawValue,
                                                        titleParam: self.templateParams.createDocParams,
                                                        callback: createCallback)

        }
    }

    private func generateTemplateViewModel() -> TemplateHorizontalListViewModel {
        let dataProvider = TemplateDataProvider()
        let createHandler: (TemplateModel, UIViewController) -> Void = { (_, _) in
            spaceAssertionFailure()
        }
        return TemplateHorizontalListViewModel(categoryId: templateParams.categoryId,
                                               pageSize: templateParams.pageSize,
                                               uiConfig: templateParams.uiConfig,
                                               templateProvider: dataProvider,
                                               templateCache: dataProvider,
                                               createByTemplateHandler: createHandler,
                                               moreTemplateHandler: { createController in
            //点击更多跳转到模板选择页
            let param = CreateTemplatePageParam(categoryId: self.templateParams.categoryId,
                                                templateSource: self.templateSource.rawValue,
                                                templatePageConfig: self.templateParams.templatePageConfig ?? .default,
                                                dcSceneId: self.templateParams.docComponentSceneId)
            guard let vc = TemplateAPIImpl.shared.createTemplateSelectedPage(param: param, fromVC: createController, delegate: self.delegate) else {
                spaceAssertionFailure("createTemplateSelectedPage error")
                return
            }
            Navigator.shared.push(vc, from: createController)
        })
    }
}

extension TemplateHorizontalListView: TemplateHorizontalListViewProtocol {
    public func start() {
        guard !self.isStarted else {
            if defaultLoadingView.isHidden, templateDataSource.isEmpty {
                /// 不在 loading，没有模版，展示失败 View
                showFailedView()
            }
            return
        }
        self.isStarted = true
        self.viewModel.setup(templateView: self)
    }
}
