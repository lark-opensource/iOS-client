import LarkUIKit
import RxSwift
import RxCocoa
import SnapKit
import UniverseDesignEmpty
import LarkContainer
import UniverseDesignFont

/// AtPicker - ViewController
/// At 选择器（选人）

class AtPickerViewController: UIViewController, HasViewModel, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    /// select 处理
    var selectHandler: ((_ user: User) -> Void)?

    /// dismiss 处理
    var dismissHandler: (() -> Void)?

    /// 可见区域
    let rxVisibleRect = BehaviorRelay(value: CGRect.zero)

    let viewModel: AtPickerViewModel

    private typealias VisibleViewPadding = (constraint: Constraint, inset: CGFloat)

    private let disposeBag = DisposeBag()
    private let tapView = UIButton()
    private let visibleView = UIView()
    private let contentView = UIView()
    private let tableView = UITableView()
    private var stateViews: (loading: LoadingPlaceholderView?, empty: UDEmptyView?)
    private var visibleViewPaddings: (top: VisibleViewPadding?, bottom: VisibleViewPadding?)
    private var lastQuery: String?

    init(resolver: UserResolver, chatId: String?) {
        self.userResolver = resolver
        self.viewModel = ViewModel(resolver: userResolver, chatId: chatId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        bindViewAction()
        bindViewState()
        bindVisibleRect()
    }

    override func loadView() {
        super.loadView()
        view = PassthroungView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // fix layout if needed
        updateVisibleViewTop(byViewState: viewModel.rxViewState.value, withDuration: 0, animated: false)
    }

    typealias BottomInsetAlongside = (_ bottomInset: CGFloat) -> Void
    func active() -> BottomInsetAlongside {
        lastQuery = nil
        return { [weak self] inset in
            guard let self = self, self.parent != nil, self.view.superview != nil else {
                return
            }
            self.updateVisibleViewBottom(byInset: inset)
        }
    }

    func inactive() {
        // do nothing
    }

    /// 更新搜索词
    func updateQuery(_ query: String) {
        Detail.logger.info("query updated: \(query)")
        let needsScrollToTop = query != lastQuery
        lastQuery = query
        viewModel.updateQuery(query)
        if needsScrollToTop {
            DispatchQueue.main.async {
                self.tableView.setContentOffset(.zero, animated: false)
            }
        }
    }

}

// MARK: - Setup/Layout View

extension AtPickerViewController {

    private func setupView() {
        /// view hierarchy
        ///
        /// |---self.view
        ///     |---tapView (处理点击)
        ///     |---visibleView
        ///         |---shadowView (圆角 + 阴影）
        ///         |---contentView
        ///             |---tableView || stateViews.empty || stateViews.loading
        ///
        if let passthroughView = view as? PassthroungView {
            passthroughView.eventFilter = { [weak self] (point, _) in
                guard let self = self else { return false }
                return point.y <= self.visibleView.frame.maxY
            }
        }

        view.addSubview(tapView)
        tapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // visibleView
        visibleView.clipsToBounds = false
        view.addSubview(visibleView)
        var topConstraint: Constraint?
        var bottomConstraint: Constraint?
        visibleView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            topConstraint = make.top.equalToSuperview().constraint
            bottomConstraint = make.bottom.equalToSuperview().constraint
        }
        if let constraint = topConstraint {
            visibleViewPaddings.top = (constraint: constraint, inset: 0)
        }
        if let constraint = bottomConstraint {
            visibleViewPaddings.bottom = (constraint: constraint, inset: 0)
        }

        // shadowView
        let shadowView = UIView()
        shadowView.backgroundColor = UIColor.ud.bgBody
        shadowView.layer.masksToBounds = false
        shadowView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        shadowView.layer.cornerRadius = 12
        shadowView.layer.shadowColor = UIColor.ud.N900.cgColor
        shadowView.layer.shadowOpacity = 0.09
        shadowView.layer.shadowRadius = 4
        shadowView.layer.shadowOffset = CGSize(width: 0, height: -4)
        visibleView.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(18)
        }

        // contentView
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.clipsToBounds = true
        visibleView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(shadowView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        // tableView
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.ctf.register(cellType: AtPickerTableViewCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // 更新 visibleView 的 top
    private func updateVisibleViewTop(
        byViewState viewState: ListViewState,
        withDuration duration: TimeInterval = 0.25,
        animated: Bool = true
    ) {
        guard let bottomPadding = visibleViewPaddings.bottom else { return }

        let targetTopInset: CGFloat
        let superViewHeight = (visibleView.superview?.bounds ?? UIScreen.main.bounds).height
        let minTopInset: CGFloat = 20
        let maxTopInset: CGFloat = 204
        let standardHeight: CGFloat = 184
        switch viewState {
        case .data, .loading, .idle:
            if superViewHeight - minTopInset - bottomPadding.inset >= standardHeight {
                targetTopInset = min(superViewHeight - bottomPadding.inset - standardHeight, maxTopInset)
            } else {
                targetTopInset = minTopInset
            }
        case .empty, .failed:
            targetTopInset = max(minTopInset, superViewHeight - 50 - bottomPadding.inset)
        }
        visibleViewPaddings.top?.inset = targetTopInset
        visibleViewPaddings.top?.constraint.update(inset: targetTopInset)

        guard visibleViewPaddings.top?.inset != targetTopInset else { return }

        if animated && view.window != nil {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    // 更新 visibleView 的 bottom
    private func updateVisibleViewBottom(byInset bottomInset: CGFloat) {
        guard visibleViewPaddings.bottom?.inset != bottomInset else { return }

        visibleViewPaddings.bottom?.inset = bottomInset
        visibleViewPaddings.bottom?.constraint.update(inset: bottomInset)
        view.layoutIfNeeded()
    }

    private func bindVisibleRect() {
        visibleView.rx.observe(CGRect.self, #keyPath(UIView.frame))
            .compactMap { $0 }
            .bind(to: rxVisibleRect)
            .disposed(by: disposeBag)
    }

}

// MARK: - Bind View Action

extension AtPickerViewController {

    private func bindViewAction() {
        tapView.addTarget(self, action: #selector(handleViewTapped), for: .touchUpInside)
    }

    @objc
    private func handleViewTapped() {
        dismissHandler?()
    }
}

// MARK: - ViewState

extension AtPickerViewController {

    private func bindViewState() {
        viewModel.rxViewState.subscribe(onNext: { [weak self] viewState in
            self?.doUpdateViewState(viewState)
            self?.updateVisibleViewTop(byViewState: viewState)
        }).disposed(by: disposeBag)

        viewModel.rxUpdateList.subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }

    private func doUpdateViewState(_ viewState: ListViewState) {
        Detail.logger.info("atPicker doUpdateViewState: \(viewState)")
        var hiddens = (empty: true, loading: true, list: true)
        var targetView: UIView?
        switch viewState {
        case .idle, .data:
            hiddens.list = false
            targetView = tableView
        case .empty, .failed:
            if stateViews.empty == nil {
                let emptyView = lazyInitEmptyView()
                contentView.addSubview(emptyView)
                emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
                stateViews.empty = emptyView
            }
            hiddens.empty = false
            targetView = stateViews.empty
        case .loading:
            if stateViews.loading == nil {
                let loadingView = lazyInitLoadingView()
                contentView.addSubview(loadingView)
                loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
                stateViews.loading = loadingView
            }
            hiddens.loading = false
            targetView = stateViews.loading
        }
        if let targetView = targetView {
            contentView.bringSubviewToFront(targetView)
        }
        tableView.isHidden = hiddens.list
        stateViews.empty?.isHidden = hiddens.empty
        stateViews.loading?.isHidden = hiddens.loading
    }

    private func lazyInitEmptyView() -> UDEmptyView {
        let description = UDEmptyConfig.Description(
            descriptionText: NSAttributedString(
                string: I18N.Lark_Legacy_SearchNoAnyResult,
                attributes: [
                    .font: UDFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.ud.textCaption
                ])
        )
        let view = UDEmptyView(config: UDEmptyConfig(
            description: description,
            type: .done
        ))
        view.backgroundColor = UIColor.ud.bgBody
        view.useCenterConstraints = true
        return view
    }

    private func lazyInitLoadingView() -> LoadingPlaceholderView {
        let loadingView = LoadingPlaceholderView()
        loadingView.isHidden = true
        loadingView.backgroundColor = UIColor.ud.bgBody
        return loadingView
    }

}

// MARK: - UITableView DataSource & Delegate

extension AtPickerViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(inSection: section)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeader(inSection: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = viewModel.titleForHeader(inSection: section), !title.isEmpty else {
            return nil
        }
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBody
        let label = UILabel()
        label.text = title
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UDFont.systemFont(ofSize: 17)
        headerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalToSuperview()
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let title = viewModel.titleForHeader(inSection: section), !title.isEmpty else {
            return CGFloat.leastNormalMagnitude
        }
        return 28
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.ctf.dequeueReusableCell(AtPickerTableViewCell.self, for: indexPath) else {
            return UITableViewCell()
        }
        cell.viewData = viewModel.cellDataForRow(atIndexPath: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AtPickerTableViewCell.desiredHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        guard let user = viewModel.userForRow(atIndexPath: indexPath) else {
            assertionFailure("逻辑错误")
            return
        }
        viewModel.updateUser(user, completion: selectHandler)
    }

}
