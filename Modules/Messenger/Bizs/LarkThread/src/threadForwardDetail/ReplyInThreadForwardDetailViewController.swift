//
//  ReplyInThreadForwardDetailViewController.swift
//  LarkThread
//
//  Created by liluobin on 2022/6/24.
//
import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import LarkCore
import LarkModel
import RichLabel
import LarkMessageCore
import LarkMessageBase
import LarkMessengerInterface
import EENavigator
import LarkOpenChat

final class ReplyInThreadForwardDetailViewController: ThreadDetailBaseViewController {

    lazy var tableView: ThreadDetailTableView = {
        let tableView = ThreadDetailTableView(viewModel: viewModel, tableDelegate: self)
        let footer = ThreadPostForwardDetailFooterView(text: viewModel.replyCount() > viewModel.replyMessages.count ?
                                                       BundleI18n.LarkThread.Lark_IM_Thread_NotInGroupUnableToReply_Text :
                                                        BundleI18n.LarkThread.Lark_Group_UnableToReplyNotGroupMember)
        footer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: footer.contentHeightForMaxWidth(view.frame.width))
        tableView.tableFooterView = footer
        return tableView
    }()
    private let disposeBag = DisposeBag()
    let viewModel: ReplyInThreadForwardDetailViewModel
    private var viewDidAppeaded: Bool = false

    init(viewModel: ReplyInThreadForwardDetailViewModel) {
        self.viewModel = viewModel
        super.init(userResolver: viewModel.userResolver)
        viewModel.context.pageContainer.pageInit()
        viewModel.constructThreadMessageAndFactoryData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        viewModel.context.pageContainer.pageDeinit()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        viewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        setupView()
        /// 加完数据
        viewModel.loadData()
        observerViewModel()
        viewModel.context.pageContainer.pageViewDidLoad()
    }
    private func observerViewModel() {
        viewModel.tableRefreshPublish
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (type) in
                switch type {
                case .refreshTable:
                self?.tableView.reloadData()
                case .startMultiSelect(let startIndex):
                    self?.multiSelecting = true
                    self?.tableView.reloadData()
                    self?.tableView.scrollRectToVisibleBottom(indexPath: startIndex, animated: true)
                case .finishMultiSelect:
                    self?.multiSelecting = false
                    self?.tableView.reloadAndGuarantLastCellVisible()
                case .messagesUpdate(indexs: let indexs, guarantLastCellVisible: let guarantLastCellVisible):
                    self?.tableView.refresh(indexPaths: indexs, guarantLastCellVisible: guarantLastCellVisible)
                }
            }).disposed(by: disposeBag)
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBase
        setupNavBar()
        threadTitleView.chatName = BundleI18n.LarkThread.Lark_IM_Thread_ThreadDetail_Title
        forwardBarButton.setImage(Resources.replyInThreadFoward.withRenderingMode(.alwaysTemplate),
                                  for: .normal)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
    }

    /// 配置导航栏
    private func setupNavBar() {
        isNavigationBarHidden = true
        navBar.addBackButton { [weak self] in
            self?.backItemTapped()
        }
        navBar.titleView = threadTitleView
        threadTitleView.hideTitleArrow()
        // 设置chatName,subjectText
        view.addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }
        if viewModel.forwardMessage != nil {
            navBar.rightViews = [forwardBarButton]
        } else {
            navBar.rightViews = []
        }
    }

    private func reloadNavigationBar() {
        if multiSelecting {
            navBar.rightViews = [cancelMutilButton]
        } else {
            navBar.rightViews = [forwardBarButton]
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resizeTableViewFooter(size)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewDidAppeaded {
            let size = navigationController?.view.bounds.size ?? view.bounds.size
            resizeTableViewFooter(size)
        }
        viewModel.context.pageContainer.pageWillAppear()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !viewDidAppeaded {
            viewDidAppeaded = true
        }
        viewModel.context.pageContainer.pageDidAppear()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.context.pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.context.pageContainer.pageDidDisappear()
    }

    private func resizeTableViewFooter(_ size: CGSize) {
        if let footer = tableView.tableFooterView as? ThreadPostForwardDetailFooterView {
            footer.frame = CGRect(x: 0, y: 0, width: size.width, height: footer.contentHeightForMaxWidth(size.width))
            tableView.tableFooterView = footer
        }
    }

    private func resizeVMIfNeeded() {
        let size = view.bounds.size
        if size != viewModel.hostUIConfig.size {
            let needOnResize = size.width != viewModel.hostUIConfig.size.width
            viewModel.hostUIConfig.size = size
            let fg = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.message.resize_if_need_by_width")
            if fg {
                // 仅宽度更新才刷新cell，因为部分机型系统下(iphone8 iOS15、不排除其他系统也存在相同问题)存在非预期回调，比如当唤起大图查看器时，系统回调了该函数，且给的高度不对
                /*1. cell渲染只依赖宽度 2. 目前正常情况下不存在只变高，不变宽的情况（转屏、ipad拖拽）
                 */
                if needOnResize {
                    viewModel.onResize()
                }
            } else {
                viewModel.onResize()
            }
        }
    }

    override func forwardButtonTapped(sender: UIButton) {
        guard let message = viewModel.forwardMessage else { return }
        let targetVC = self.navigationController ?? self
        let body = ForwardMessageBody(originMergeForwardId: originMergeForwardId(),
                                      message: message,
                                      type: .message(message.id),
                                      from: .thread,
                                      traceChatType: .threadDetail)
            navigator.present(
                body: body,
                from: targetVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
            )
    }

    /// 这里转发帖子
    override func multiSelectingValueUpdate() {
        if multiSelecting {
            self.tableView.longPressGesture.isEnabled = false
            self.reloadNavigationBar()
            let bottomMenBarHeight = BottomMenuBar.barHeight(in: self.view)
            self.tableView.snp.remakeConstraints { (make) in
                make.left.right.equalTo(self.view)
                make.top.equalTo(navBar.snp.bottom)
                make.bottom.equalTo(self.view).offset(-bottomMenBarHeight)
            }
            self.view.layoutIfNeeded()
        } else {
            self.tableView.longPressGesture.isEnabled = true
            self.reloadNavigationBar()
            self.tableView.snp.remakeConstraints { (make) in
                make.left.right.equalTo(self.view)
                make.top.equalTo(navBar.snp.bottom)
                make.bottom.equalToSuperview()
            }
            self.view.layoutIfNeeded()
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y), animated: false)
        }
    }

    override func cancelMutilButtonTapped(sender: UIButton) {
        viewModel.finishMultiSelect()
    }
}

// MARK: - ChatPageAPI 多选
extension ReplyInThreadForwardDetailViewController: ChatPageAPI {
    func originMergeForwardId() -> String? {
        return viewModel.originMergeForwardId
    }

    func reloadRows(current: String, others: [String]) {
    }

    var inSelectMode: Observable<Bool> {
        return self.viewModel.inSelectMode.asObservable()
    }

    var selectedMessages: BehaviorRelay<[ChatSelectedMessageContext]> {
        return self.viewModel.pickedMessages
    }

    func startMultiSelect(by messageId: String) {
        self.viewModel.startMultiSelect(by: messageId)
    }

    func endMultiSelect() {
        self.viewModel.finishMultiSelect()
    }

    func toggleSelectedMessage(by messageId: String) {
        self.viewModel.toggleSelectedMessage(by: messageId)
    }

}

extension ReplyInThreadForwardDetailViewController: DetailTableDelegate {
    var menuService: MessageMenuOpenService? { self.viewModel.context.pageContainer.resolve(MessageMenuOpenService.self) }

    func tapHandler() {}

    func showTopLoadMore(status: ScrollViewLoadMoreStatus) {}

    func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {}

    func showMenuForCellVM(cellVM: ThreadDetailCellVMGeneralAbility) {}

    func willDisplay(cell: UITableViewCell, cellVM: ThreadDetailCellViewModel) {}
}

extension ReplyInThreadForwardDetailViewController: PageAPI {
    func multiEdit(_ message: Message) {}

    func viewWillEndDisplay() {
        tableView.endDisplayVisibleCells()
    }

    func viewDidDisplay() {
        tableView.displayVisibleCells()
    }

    var pageSupportReply: Bool {
        return true
    }

    func insertAt(by chatter: Chatter?) {}

    func reply(message: Message, partialReplyInfo: PartialReplyInfo?) {}

    func reedit(_ message: Message) {}

    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return nil
    }
}

extension ReplyInThreadForwardDetailViewController: ChatMessagesOpenService {
    var pageAPI: PageAPI? {
        return self
    }
    var dataSource: DataSourceAPI? {
        return self.viewModel.context.dataSourceAPI
    }
}

extension ReplyInThreadForwardDetailViewController: MessageMenuServiceDelegate, LongMessageMenuOffsetProtocol {
    func messageMenuDidLoad(_ menuService: MessageMenuOpenService,
                            message: Message,
                            touchTest: MenuTouchTestInterface) {
        touchTest.enableTransmitTouch = true
    }

    func offsetTableView(_ menuService: MessageMenuOpenService, offset: MessageMenuVerticalOffset) {
        switch offset {
        case .normalSizeBegin(let offset):
            tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x,
                                               y: tableView.contentOffset.y + offset),
                                       animated: false)
        case .longSizeBegin(let view):
            self.autoOffsetForLargeSizeView(view, fromVC: self, tableView: self.tableView, tableTopBlockHeight: nil)
        case .move(let offset):
            tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x,
                                           y: tableView.contentOffset.y + offset),
                                   animated: false)
        case .end:
            let maxOffset = tableView.contentSize.height - tableView.frame.height
            let isNormalOffset = maxOffset > 0 && tableView.contentOffset.y <= ceil(maxOffset)
            if !isNormalOffset {
                tableView.scrollToOffsetY(maxOffset)
            }
        }
    }
}
