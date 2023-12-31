//
//  DetailViewController.swift
//  Todo
//
//  Created by 白言韬 on 2021/1/22.
//

import LarkUIKit
import RxSwift
import RxCocoa
import LarkContainer
import CTFoundation
import LarkExtensions
import SnapKit
import LarkSplitViewController
import UniverseDesignEmpty
import UIKit
import EENavigator
import TodoInterface

/// Detail - ViewController

final class DetailViewController: BaseViewController, HasViewModel, ModuleContextHolder, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    /// todo 的 guid. `nil` 表示新建场景
    var guid: String? { context.scene.todoId }
    let viewModel: DetailViewModel
    // module context
    let context: DetailModuleContext

    enum ExitReason: String {
        case cancel     // 取消按钮被点击, 用于present时候
        case clickBack  // present: 右上角返回, push: 左上角返回
        case create     // 新建任务
        case delete     // 删除任务
        case quit       // 不再参与（作为执行人）
        case unfollow   // 不再关注
        case bacthAdd   // pad下批量添加子任务
    }

    /// exit handler，自定义 Detail 的退出方式
    ///
    /// - Parameter reason: 退出理由
    /// - Returns: `true` 表示已处理，`false` 表示由详情页自行处理退出
    var onNeedsExit: ((ExitReason) -> Bool)?

    let disposeBag = DisposeBag()

    // state views
    var loadingView: LoadingPlaceholderView?
    var failedView: UDEmptyView?

    // container views
    private let containerViews = (
        root: UIStackView(),
        simpleModule: ModuleContainerView(),
        sectionModule: UITableView(frame: .zero, style: .grouped)
    )

    ///  --- Modules Guide ---
    ///  |--- top module ----|  // stick at top
    ///  |-- simple modules -|  // simple modules
    ///  |- section modules -|  // section modules
    ///  |-- bottom module --|  // stick at bottom

    // top module
    private lazy var topModule = DetailTopModule(resolver: userResolver, context: context)
    // simple modules
    var simpleModules = [DetailBaseModule]()
    // section modules
    private var sectionModules = [DetailBaseModule]()
    // bottom module
    lazy var bottomModule = DetailBottomModule(resolver: userResolver, context: context)
    // bottom create view for iphone create
    lazy var bottomCreateView = initBottomCreateView()
    // flag for create view
    var isCreateShown: Bool = false
    var lastBottomInset: CGFloat = 0

    // 加载 detail 耗时埋点
    var loadDetailTrackerTask: Tracker.Appreciable.Task?

    @ScopedInjectedLazy var routeDependency: RouteDependency?
    @ScopedInjectedLazy var todoService: TodoService?

    init(resolver: UserResolver, input: DetailInput) {
        self.userResolver = resolver
        viewModel = DetailViewModel(resolver: resolver, input: input)
        context = DetailModuleContext(store: viewModel.store)
        if case .edit = input {
            loadDetailTrackerTask = Tracker.Appreciable.Task(scene: .detail, event: .detailLoad).resume()
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContext()
        setupKeyBoard()
        bindBusEvent()
        bindViewState()

        setupNaviItem()
        setupView()
        setupModule()
        setupBottomCreate()

        observeScreenshot()
        bindViewModelAction()
        viewModel.setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        context.bus.post(.hostLifeCycle(.willAppear))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        context.bus.post(.hostLifeCycle(.didAppear))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        context.bus.post(.hostLifeCycle(.willDisappear))
        // 侧滑或者下拉返回的时候
        if (isMovingFromParent || navigationController?.isBeingDismissed == true) && !isExiting {
            cancelEditing()
            viewModel.handleExitAction()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        context.bus.post(.hostLifeCycle(.didDisappear))
    }

    override func backItemTapped() {
        exit(reason: .clickBack)
    }

    override func closeBtnTapped() {
        exit(reason: .cancel)
    }

    private func observeScreenshot() {
        NotificationCenter.default.rx
            .notification(UIApplication.userDidTakeScreenshotNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.viewModel.trackScreenshot() })
            .disposed(by: disposeBag)
    }

    private func bindBusEvent() {
        context.bus.subscribe { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .exit(let reason):
                switch reason {
                case .quit:
                    self.exit(reason: .quit)
                case .unfollow:
                    self.exit(reason: .unfollow)
                }
            case .batchAddSubtasks(let ids):
                // 监听pad下批量创建的操作
                if Display.pad, self.viewModel.store.state.scene.isForSubTaskCreating {
                    self.viewModel.doBatchAddOwner(with: ids)
                }
            default:
                break
            }
        }
        .disposed(by: disposeBag)
    }

    private func bindViewModelAction() {
        viewModel.onNeedsExit = { [weak self] reason in
            self?.exit(reason: reason)
        }
    }

    // 描述是否在退出
    private var isExiting = false
    // 退出页面
    func exit(reason: ExitReason) {
        guard !isExiting else { return }
        isExiting = true
        Detail.logger.info("will exit for reason: \(reason)")
        cancelEditing()
        if [.cancel, .clickBack].contains(reason) {
            viewModel.handleExitAction()
        }
        if let exitHandler = onNeedsExit, exitHandler(reason) {
            return
        }
        closeViewController(userResolver)
    }

    // MARK: - Setup KeyBoard
    private func setupKeyBoard() {
        if !context.keyboard.isListening {
            context.keyboard.on(events: Keyboard.KeyboardEvent.allCases) { [weak self] options in
                guard let self = self else { return }
                if Display.pad,
                   case .formSheet = self.navigationController?.modalPresentationStyle,
                   let superView = self.view.superview, let window = self.view.window {
                    let rectInWindow = superView.convert(self.view.frame, to: window)
                    let offsetY = window.bounds.height - rectInWindow.maxY
                    let fixedHeight = max(0, options.endFrame.height - offsetY)
                    self.context.rxKeyboardHeight.accept(fixedHeight)
                } else {
                    var height = options.endFrame.height
                    if self.viewModel.hasBottomCrateView() {
                        height += self.viewModel.createViewHeight
                    }
                    self.context.rxKeyboardHeight.accept(height)
                }
            }
            context.keyboard.start()
        }
    }

    // MARK: - Setup View

    private func setupView() {
        // containerViews.root
        view.backgroundColor = UIColor.ud.bgBody
        containerViews.root.axis = .vertical
        view.addSubview(containerViews.root)
        containerViews.root.snp.makeConstraints { $0.edges.equalToSuperview() }

        containerViews.root.addArrangedSubview(topModule.view)
        topModule.view.setContentHuggingPriority(.defaultHigh, for: .vertical)

        containerViews.root.addArrangedSubview(containerViews.sectionModule)
        containerViews.sectionModule.setContentHuggingPriority(.defaultLow, for: .vertical)

        containerViews.root.addArrangedSubview(bottomModule.view)
        bottomModule.view.setContentHuggingPriority(.defaultHigh, for: .vertical)

        // containerViews.simpleModules
        containerViews.simpleModule.frame = view.bounds
        var containerLastFrame = containerViews.simpleModule.frame
        containerViews.simpleModule.stackView.onPreferredSizeChanged = { [weak self] size in
            guard let self = self else { return }
            guard size.width >= 100, size != containerLastFrame.size else { return }
            var frame = self.containerViews.simpleModule.frame
            frame.size = size
            self.containerViews.simpleModule.frame = frame
            self.containerViews.sectionModule.tableHeaderView = self.containerViews.simpleModule
            containerLastFrame = self.containerViews.simpleModule.frame
        }
        let ges = UITapGestureRecognizer()
        ges.addTarget(self, action: #selector(cancelEditing))
        ges.cancelsTouchesInView = false
        containerViews.simpleModule.addGestureRecognizer(ges)

        // containerViews.sectionModule
        containerViews.sectionModule.backgroundColor = UIColor.ud.bgBody
        containerViews.sectionModule.tableHeaderView = containerViews.simpleModule
        containerViews.sectionModule.tableFooterView = UIView()
        // 低于 v13.0 的版本，关掉 estimate height，避免 reload 时抖动
        if #available(iOS 13.0, *) {} else {
            containerViews.sectionModule.estimatedRowHeight = 0
            containerViews.sectionModule.estimatedSectionHeaderHeight = 0
            containerViews.sectionModule.estimatedSectionFooterHeight = 0
        }
    }

    private func setupContext() {
        context.viewController = self
        context.tableView = containerViews.sectionModule
    }

    @objc
    func cancelEditing() {
        view.endEditing(true)
    }

    // MARK: - Module

    private func setupModule() {
        defer { view.setNeedsLayout() }

        // setup top module
        topModule.setup()
        // setup simple modules
        let ancestorTaskModule = DetailAncestorTaskModule(resolver: userResolver, context: context)
        let ganttModule = DetailGanttModule(resolver: userResolver, context: context)
        let summaryModule = DetailSummaryModule(resolver: userResolver, context: context)
        let notesModule: DetailBaseModule = context.scene.isForCreating
            ? DetailNotesInputModule(resolver: userResolver, context: context)
            : DetailNotesEntryModule(resolver: userResolver, context: context)
        let refMessageModule = DetailRefMessageModule(resolver: userResolver, context: context)
        let sourceModule = DetailSourceModule(resolver: userResolver, context: context)
        let ownerModule = DetailOwnerModule(resolver: userResolver, context: context)
        let timeModule = DetailTimeModule(resolver: userResolver, context: context)
        let taskList = DetailTaskListModule(resolver: userResolver, context: context)
        let customFieldsModule = DetailCustomFieldsModule(resolver: userResolver, context: context)
        let subTaskModule = DetailSubTaskModule(resolver: userResolver, context: context)
        let followerModule = DetailFollowerModule(resolver: userResolver, context: context)
        let attachemtModule = DetailAttachmentModule(resolver: userResolver, context: context)
        simpleModules = [
            ancestorTaskModule, ganttModule, summaryModule, notesModule, refMessageModule, sourceModule,
            ownerModule, timeModule, taskList, customFieldsModule, subTaskModule, followerModule, attachemtModule
        ]
        var (items1, items2): ([ModuleItem], [ModuleItem])
        items1 = [ancestorTaskModule, summaryModule, notesModule, refMessageModule, sourceModule]
        if FeatureGating.boolValue(for: .gantt) {
            items1.insert(ganttModule, at: 1)
        }
        if FeatureGating.boolValue(for: .customFields) {
            items2 = [ownerModule, timeModule, taskList, customFieldsModule, subTaskModule, attachemtModule, followerModule]
        } else {
            items2 = [ownerModule, timeModule, taskList, subTaskModule, attachemtModule, followerModule]
        }
        let emptyColor = UIColor.ud.bgBody
        var groupList = [
            ModuleGroup(
                items: items1,
                topMargin: .init(height: 6, color: emptyColor),
                spacing: .init(height: 12, color: emptyColor)
            ),
            ModuleGroup(
                items: items2,
                topMargin: .init(height: 12)
            )
        ]
        if !groupList.isEmpty {
            groupList[groupList.count - 1].bottomMargin = .init(height: 15)
        }
        containerViews.simpleModule.groups = groupList
        simpleModules.forEach { $0.setup() }

        // setup section modules
        sectionModules = [DetailCommentModule(resolver: userResolver, context: context)]
        sectionModules.forEach { $0.setup() }

        // setup bottom module
        bottomModule.setup()
    }

    // MARK: Navi Action - Shrink

    @objc
    func handleShrinkItemClick() {
        exit(reason: .clickBack)
    }

    // MARK: Navi Action - Create

    @objc
    func handleCreateItemClick() {
        _handleCreateItemClick()
    }

    // MARK: Navi Action - Subscribe / Subscribed

    @objc
    func handleSubscribeItemClick() {
        _handleSubscribeItemClick()
    }

    // MARK: Navi Action - Share

    @objc
    func handleShareItemClick() {
        _handleShareItemClick()
    }

    // MARK: Navi Action - More

    @objc
    func handleMoreItemClick() {
        _handleMoreItemClick()
    }

    @objc
    func numClick() {
        _copyTaskNum()
    }

}
