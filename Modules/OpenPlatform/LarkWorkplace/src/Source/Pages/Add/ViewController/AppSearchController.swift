//
//  AppSearchController.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/6/24.
//

import EENavigator
import LarkUIKit
import RoundedHUD
import SwiftyJSON
import Swinject
import LKCommonsLogging
import LarkInteraction
import LarkWorkplaceModel
import RxSwift
import RxCocoa
import LarkNavigator

final class AppSearchController: BaseUIViewController, UITextFieldDelegate {
    static let logger = Logger.log(AppSearchController.self)

    private let userId: String
    @available(*, deprecated, message: "be compatible for monitor")
    private let tenantId: String

    private let navigator: UserNavigator
    /// 数据Model
    private let viewModel: AppCategoryViewModel
    /// 搜索模型
    private let appSearchModel: WPAppSearchModel

    /// RxSwift dispose bag
    private let disposeBag = DisposeBag()

    /// Search框
    // MARK: UI Elements
    private lazy var searchField: SearchUITextField = {
        let searchField = SearchUITextField()
        searchField.placeholder = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Search_Apps
        searchField.textColor = UIColor.ud.textTitle
        searchField.backgroundColor = UIColor.ud.bgBodyOverlay
        searchField.returnKeyType = .search
        searchField.enablesReturnKeyAutomatically = true
        searchField.canEdit = true
        searchField.delegate = self
        return searchField
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        let cancelText = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Cancel
        button.setTitle(cancelText, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18.0)
        button.addTarget(self, action: #selector(clickCancel), for: .touchUpInside)
        return button
    }()

    /// UI - Result View, shown when the queried app list is not empty
    private lazy var resultView: WPCategoryPageView = {
        let resultView = WPCategoryPageView(
            frame: .zero,
            viewModel: viewModel.searchModel
        )
        resultView.scrollEvent = { [weak self] in self?.searchField.resignFirstResponder() }
        return resultView
    }()

    /// UI - Loading / Empty result / Search failed
    private lazy var stateView = WPPageStateView()

    private lazy var searchContainerView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.clear
        view.isHidden = true
        return view
    }()

    // MARK: VC初始化
    init(
        userId: String,
        tenantId: String,
        navigator: UserNavigator,
        model: AppCategoryViewModel,
        searchModel: WPAppSearchModel
    ) {
        self.userId = userId
        self.tenantId = tenantId
        self.navigator = navigator
        self.viewModel = model
        self.appSearchModel = searchModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        setupViews()
        setupLayout()
        setupActions()
    }

    private func setupActions() {
        // Hide keyboard action
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(myHideKeyboard)))

        // Search field editing change
        searchField.rx.controlEvent([.editingChanged]).asObservable()
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .filter({ [weak self] in
                // Chinese pinyin jitter issue
                return self?.searchField.markedTextRange == nil
            })
            .subscribe({ [weak self] _ in
                self?.searchTextChanged()
            })
            .disposed(by: disposeBag)

        // Put the pointer on cancel button
        setPointerEffect()
    }

    @objc func myHideKeyboard() {
        self.searchField.resignFirstResponder()
    }

    private func setupViews() {
        /* View Hierarchy：
        - view
         - searchField (left top)
         - cancelButton (right top)
         - resultContainerView (bottom)
            - stateView (loading / empty result / search failed) [below]
            - resultView [top]
        */
        // styles of the root view
        view.backgroundColor = UIColor.ud.bgBody
        // view hierarchy
        view.addSubview(searchField)
        view.addSubview(cancelButton)
        view.addSubview(searchContainerView)
        searchContainerView.addSubview(stateView)
        searchContainerView.addSubview(resultView)
    }

    private func setupLayout() {
        searchField.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(cancelButton.snp.left).offset(-8)
            make.height.equalTo(32)
        }
        cancelButton.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(searchField.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
        cancelButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        searchField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        searchContainerView.snp.makeConstraints { (make) in
            make.top.equalTo(searchField.snp.bottom).offset(8)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        stateView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        resultView.snp.makeConstraints { (make) in
            make.top.equalTo(searchField.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func setPointerEffect() {
        cancelButton.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (
                        CGSize(width: size.width + highLightTextWidthMargin, height: highLightCommonTextHeight),
                        highLightCorner
                    )
                }
            )
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchField.becomeFirstResponder()
    }

    @objc func clickCancel() {
        WPEventReport(name: WPEvent.appcenter_search.rawValue, userId: userId, tenantId: tenantId)
            .set(key: "search_key", value: appSearchModel.lastSearchedText)
            .post()
        Self.logger.info("click cancel")
        // ipad下，如果是唯一一个VC，则展示Default来关闭VC
        if Display.pad, navigationController?.viewControllers.first == self {
            navigator.showDetail(DefaultDetailController(), from: self)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    /// Send a search request and refresh the result view, when an editing change has been made in the search field
    func searchTextChanged() {
        guard let keyWords = searchField.text else { return }

        /* Case 1: searchField.text is empty */
        if keyWords.isEmpty {
            clearResultContainer()
            appSearchModel.lastSearchedText = keyWords
            return
        }

        /* Case 2: searchField.text is not empty */
        // step1 - Show loading view if the lastSearchedText is empty
        if appSearchModel.lastSearchedText.isEmpty { showLoadingView() }
        // step2 - update lastSearchedText
        appSearchModel.lastSearchedText = keyWords
        // step3 - Request for app list, refresh result container
        appSearchModel.search(
            keyWord: keyWords,
            disposeBag: disposeBag,
            success: { [weak self] (result) in
                guard let `self` = self else { return }
                // step4: data model -> view model
                self.viewModel.updateSearchResult(searchResult: result)
                // step5: refresh result container
                self.refreshResultContainer(with: self.viewModel.searchModel)
            }, failure: { [weak self] (_) in
                self?.showSearchFailedView()
            }
        )
    }

    /// Refresh result container view with query result
    ///
    /// - Parameter model: the queried view model
    private func refreshResultContainer(with model: AppCategoryPageModel) {
        switch model.pageState {
        case .success:
            showResultView(with: model)
        case .empty:
            showEmptyResultView(text: appSearchModel.lastSearchedText)
        default:
            return
        }
    }

    /// Show loading view
    private func showLoadingView() {
        searchContainerView.isHidden = false
        resultView.isHidden = true
        stateView.state = .loading
    }

    /// Show empty result view
    ///
    /// - Parameter text: The latest query keyword
    private func showEmptyResultView(text: String) {
        searchContainerView.isHidden = false
        resultView.isHidden = true
        stateView.state = .searchNoRet(.create(text: text))
    }

    /// Show result table view
    ///
    /// - Parameter model: the queried view model
    private func showResultView(with model: AppCategoryPageModel) {
        searchContainerView.isHidden = false
        resultView.isHidden = false
        resultView.reloadData(model: model)
        stateView.state = .hidden
    }

    /// Show search failed view
    private func showSearchFailedView() {
        searchContainerView.isHidden = false
        resultView.isHidden = true
        stateView.state = .loadFail(.create { [weak self] in
            self?.searchTextChanged()
        })
    }

    /// Clear result container view
    private func clearResultContainer() {
        searchContainerView.isHidden = true
        resultView.isHidden = true
        stateView.isHidden = true
    }
}
