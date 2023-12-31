//
//  FlagListViewController.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty
import RxSwift
import LarkContainer
import LarkCore
import LKCommonsLogging
import EENavigator
import LarkAlertController
import LarkMessengerInterface
import RustPB
import LarkSwipeCellKit
import LarkModel
import LarkMessageCore
import LKCommonsTracker
import Homeric
import LarkOpenFeed
import LarkSceneManager
import LarkMessageBase
import RichLabel
import LarkZoomable

public final class FlagListViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate, UserResolverWrapper {
    static let logger = Logger.log(FlagListViewController.self, category: "flag.list.view.controller")
    public var userResolver: UserResolver { return feedContext.userResolver}
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    // MARK: - FeedModuleVCInterface
    public let tableView: FeedTableView
    public let tab: Feed_V1_FeedFilter.TypeEnum = .flag
    public weak var delegate: FeedModuleVCDelegate?

    let viewModel: FlagListViewModel

    let disposeBag = DisposeBag()

    let feedContext: FeedContextService!

    var datasource: [FlagItem] = [] {
        didSet {
            viewModel.componentDataSource = []
            datasource.forEach({
                if let vm = $0.messageVM as? FlagMessageComponentCellViewModel {
                    viewModel.componentDataSource.append(vm.componentViewModel)
                }
            })
        }
    }

    var cellFactory: FlagListCellFactory!

    var screenWidth: CGFloat = UIScreen.main.bounds.width

    var loadingHud: UDToast?

    weak var emptyView: UDEmptyView?

    // leftOrientation、rightOrientation 用于缓存
    static var leftOrientation: SwipeOptions?
    static var rightOrientation: SwipeOptions?

    init(viewModel: FlagListViewModel, feedContext: FeedContextService) {
        self.viewModel = viewModel
        self.feedContext = feedContext
        self.tableView = FeedTableView(frame: .zero, style: .plain)
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.fillerRowHeight = 0
            tableView.sectionHeaderTopPadding = .zero
        }
        #endif
        super.init(nibName: nil, bundle: nil)
        self.isNavigationBarHidden = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // 设置context
        self.viewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        // 设置子控件
        self.setupSubViews()
        // 加载动画
        if let window = self.currentWindow() {
            self.loadingHud = UDToast.showLoading(on: window, disableUserInteraction: true)
        }
        // 绑定数据
        self.bindData()

        // 订阅字体大小变更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeZoomLevel),
            name: Zoom.didChangeNotification,
            object: nil
        )
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.dataDependency.audioPlayer?.stopPlayingAudio()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.screenWidth = size.width
        self.viewModel.hostUIConfig.size = size
        self.viewModel.onResize()
        self.tableView.reloadData()
    }

    // MARK: - UIScrollViewDelegate
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.viewModel.frozenDataQueue()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.viewModel.resumeDataQueue()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.viewModel.resumeDataQueue()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.height
        if offset + height * 2 > contentHeight {
            self.viewModel.loadMore()
        }
    }

    // MARK: - 监听字体大小变化
    @objc
    private func didChangeZoomLevel() {
        self.tableView.reloadData()
    }

    // MARK: - UITableViewDragDelegate
    public func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let cell = tableView.cellForRow(at: indexPath) as? FeedCardCellInterface,
              let scene = cell.supportDragScene() else {
            return []
        }
        scene.sceneSourceID = self.currentSceneID()
        let activity = SceneTransformer.transform(scene: scene)
        let itemProvider = NSItemProvider()
        itemProvider.registerObject(activity, visibility: .all)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    public func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 12)
        return parameters
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.datasource.count else {
            return UITableViewCell()
        }
        let flagItem = self.datasource[indexPath.row]
        let identifier = FlagUtility.getCellIdentifier(flagItem, feedCardModuleManager: viewModel.cellViewModelFactory.feedCardModuleManager)
        let cell = cellFactory.dequeueReusableCell(with: identifier,
                                                   screenWidth: screenWidth,
                                                   flagItem: flagItem)
        cell.delegate = self
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.row < datasource.count else { return }
        let flagItem = datasource[indexPath.row]
        if flagItem.type == .message {
            // 消息埋点，feed的埋点在LarkFeed那边已经统一埋了
            FlagTracker.Main.Click(flagItem, viewModel.dataDependency.iPadStatus)
            // 消息类型的Flag
            self.pushToChatViewController(flagItem)
        } else if flagItem.type == .feed {
            // Feed类型的Flag
            guard let selectedCell = tableView.cellForRow(at: indexPath) as? FeedCardCellInterface else {
                return
            }
            if let feedVM = flagItem.feedVM,
               let context = try? userResolver.resolve(assert: FeedCardContext.self) {
                FeedActionFactoryManager.performJumpAction(
                    feedPreview: feedVM.feedPreview,
                    context: context,
                    from: self,
                    basicData: feedVM.basicData,
                    bizData: feedVM.bizData,
                    extraData: [:])
            }
        }
        // iPad的话需要记录选中状态
        if Display.pad {
            self.viewModel.dataDependency.setSelected(flagId: flagItem.uniqueId)
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < datasource.count else { return 0 }
        let flagItem = datasource[indexPath.row]
        if flagItem.type == .feed, let feedVM = flagItem.feedVM {
            // feed类型的话Cell的高度是根据feed的vm计算出来的
            return feedVM.cellRowHeight
        }
        // message类型的话Cell的高度是自动布局计算出来的
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < datasource.count else { return }
        let flagItem = datasource[indexPath.row]
        if flagItem.type == .message, let cell = cell as? FlagMessageCell {
            cell.willDisplay()
        } else if flagItem.type == .feed, let cell = cell as? FeedCardCellInterface {
            cell.willDisplay()
        }
        if flagItem.type == .message, let messageVM = flagItem.messageVM {
            messageVM.willDisplay()
        }
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < datasource.count else { return }
        let flagItem = datasource[indexPath.row]
        if flagItem.type == .message, let cell = cell as? FlagMessageCell {
            cell.didEndDisplay()
        }
        if flagItem.type == .message, let messageVM = flagItem.messageVM {
            messageVM.didEndDisplay()
        }
        if let cell = cell as? FeedCardCellInterface {
            cell.didEndDisplay()
        }
    }
}

extension FlagListViewController: PageAPI {
    public func reply(message: LarkModel.Message, partialReplyInfo: LarkModel.PartialReplyInfo?) {
    }

    public func insertAt(by chatter: LarkModel.Chatter?) {
    }

    public func reply(message: LarkModel.Message) {
    }

    public func reedit(_ message: LarkModel.Message) {
    }

    public func multiEdit(_ message: LarkModel.Message) {
    }

    public var pageSupportReply: Bool {
        return false
    }

    public func viewWillEndDisplay() {
    }

    public func viewDidDisplay() {
    }

    public func getSelectionLabelDelegate() -> RichLabel.LKSelectionLabelDelegate? {
        return nil
    }
}
