//
//  ChatInfoController.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/1/29.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkModel
import LKCommonsLogging
import LarkCore
import Swinject
import LarkMessengerInterface
import EENavigator
import LarkFeatureGating
import LarkSplitViewController
import LarkOpenChat
import UniverseDesignToast
import LarkAlertController
import FigmaKit

/// 设置页代码导读文档: https://bytedance.feishu.cn/docs/doccnwg9Ae1FcFHza0JAWmmsIcb#KDwoKq
final class ChatInfoViewController: BaseSettingController, UITableViewDataSource, UITableViewDelegate,
                                       CommonItemStyleFormat {
    // UI
    private let naviBar: TitleNaviBar
    var tableView: InsetTableView?

    // Logic
    static let logger = Logger.log(ChatInfoViewController.self, category: "LarkChatSetting")
    private let disposeBag = DisposeBag()
    private(set) var viewModel: ChatInfoViewModel
    private var items: [CommonSectionModel] = []
    private var maxWidth: CGFloat?
    override var navigationBarStyle: NavigationBarStyle {
        return .none
    }
    private let appreciableTracker: AppreciableTracker

    init(viewModel: ChatInfoViewModel,
         appreciableTracker: AppreciableTracker) {
        self.viewModel = viewModel
        self.naviBar = TitleNaviBar(titleString: viewModel.naviBarTitle)
        self.appreciableTracker = appreciableTracker
        super.init(nibName: nil, bundle: nil)
        appreciableTracker.initViewEnd()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        isNavigationBarHidden = true
        self.configViewModel()
        self.commInit()
        let startTime = CACurrentMediaTime()

        self.viewModel.viewDidLoadTask()
        self.viewModel.reloadData
            .drive(onNext: { [weak self] (items) in
                self?.items = items
                self?.tableView?.reloadData()
            }).disposed(by: self.disposeBag)

        self.viewModel.updateHeight
            .drive(onNext: { [weak self]  in
                UIView.performWithoutAnimation {
                    self?.tableView?.beginUpdates()
                    self?.tableView?.endUpdates()
                }
            }).disposed(by: self.disposeBag)

        self.viewModel.firstScreenReadyDriver.drive(onNext: { [weak self] (_) in
            self?.appreciableTracker.updateSDKCost(CACurrentMediaTime() - startTime)
            self?.appreciableTracker.end()
        }).disposed(by: self.disposeBag)

        self.viewModel.errorObserver.subscribe { [weak self] (error) in
            self?.appreciableTracker.error(error)
        }.disposed(by: self.disposeBag)

        self.viewModel.startLoadData()
        appreciableTracker.viewDidLoadEnd()
    }

    private func configViewModel() {
        viewModel.targetVC = self
        viewModel.setupOpenModule()
        viewModel.chatSettingContext.currentVC = self
        viewModel.chatSettingContext.reload = { [weak self] in
            self?.viewModel.refresh()
        }
        self.viewModel.configModuleViewModules { [weak self] (title, message) in
            guard let self = self else { return }
            let alertController = LarkAlertController()
            alertController.setTitle(text: title)
            alertController.setContent(text: message)
            alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_Sure)
            self.viewModel.navigator.present(alertController, from: self)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.maxWidth = self.view.frame.width
        self.tableView?.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if Display.pad && UIApplication.shared.applicationState == .background { return }
        if size.width != self.maxWidth {
            self.maxWidth = size.width
            self.tableView?.reloadData()
        }
    }

    private func commInit() {
        commInitNavi()
        commTableView()
    }

    private func commInitNavi() {
        naviBar.addBackButton()
        setNaviBarRightItems()
        naviBar.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
    }

    private func setNaviBarRightItems() {
        if viewModel.chat.type == .p2P, viewModel.chatCanBeShared {
            let barItem = TitleNaviBarItem(image: Resources.multiple_share_chat_icon,
                                           action: { [weak self] _ in
                                            self?.shareUserCardTapped()
                                            guard let buriedPointChat = self?.viewModel.chat else { return }
                                            ChatSettingTracker.imChatSettingClickPersonShare(chat: buriedPointChat)
                                           })
            naviBar.rightItems = [barItem]
        } else if viewModel.chat.type != .p2P, viewModel.chatCanBeShared {
            let barItem = TitleNaviBarItem(image: Resources.multiple_share_chat_icon.ud.withTintColor(UIColor.ud.iconN1),
                                           action: { [weak self] _ in
                                            self?.shareChatViaLinkBtnTapped()
                                            guard let buriedPointChat = self?.viewModel.chat else { return }
                                            ChatSettingTracker.imChatSettingClickShare(chat: buriedPointChat)
                                           })
            naviBar.rightItems = [barItem]
        } else {
            Self.logger.info(
                """
                naviBarRightItems is nil, chatID = \(viewModel.chat.id),
                viewModel.chat.chatterHasResign = \(viewModel.chat.chatterHasResign),
                viewModel.chatCanbeShared = \(viewModel.chatCanBeShared)
                """
            )
            naviBar.rightItems = []
        }
    }

    func updateRightItems() {
        setNaviBarRightItems()
    }

    private func commTableView() {
        let tableView = InsetTableView(frame: .zero)
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = 0
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(naviBar.snp.bottom)
        }
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.lu.register(cellSelf: ChatInfoNameCell.self)
        tableView.lu.register(cellSelf: ChatInfoOncallCell.self)
        tableView.lu.register(cellSelf: ChatInfoDescriptionCell.self)
        tableView.lu.register(cellSelf: ChatInfoShareCell.self)
        tableView.lu.register(cellSelf: ChatInfoAddTabCell.self)
        tableView.lu.register(cellSelf: ChatInfoToTopCell.self)
        tableView.lu.register(cellSelf: ChatInfoEnterPositionCell.self)
        tableView.lu.register(cellSelf: ChatInfoLeaveGroupCell.self)
        tableView.lu.register(cellSelf: GroupSettingDisbandCell.self)
        tableView.lu.register(cellSelf: ChatInfoChatBoxCell.self)
        tableView.lu.register(cellSelf: ChatInfoNickNameCell.self)
        tableView.lu.register(cellSelf: ChatInfoAutoTranslateCell.self)
        tableView.lu.register(cellSelf: ChatInfoReportCell.self)
        tableView.lu.register(cellSelf: GroupInfoNameCell.self)
        tableView.lu.register(cellSelf: GroupInfoDescriptionCell.self)
        tableView.lu.register(cellSelf: GroupInfoMailAddressCell.self)
        tableView.lu.register(cellSelf: GroupInfoQRCodeCell.self)
        tableView.lu.register(cellSelf: GroupSettingTransferCell.self)
        tableView.lu.register(cellSelf: GroupSettingDeleteMessagesCell.self)
        tableView.lu.register(cellSelf: ChatInfoGroupAppCell.self)
        tableView.lu.register(cellSelf: ChatInfoPersonInfoCell.self)
        tableView.lu.register(cellSelf: ChatInfoSearchHistoryCell.self)
        tableView.lu.register(cellSelf: ChatInfoSearchDetailCell.self)
        tableView.lu.register(cellSelf: ChatInfoLinkedPagesTitleCell.self)
        tableView.lu.register(cellSelf: ChatInfoLinkedPagesDetailCell.self)
        tableView.lu.register(cellSelf: ChatInfoLinkedPagesFooterCell.self)
        tableView.lu.register(cellSelf: ChatInfoMemberCell.self)
        tableView.lu.register(cellSelf: ChatInfoMarkForFlagCell.self)
        tableView.lu.register(cellSelf: ChatInfoAtAllSilentCell.self)
        tableView.lu.register(cellSelf: ChatInfoMuteCell.self)
        tableView.lu.register(cellSelf: ChatInfoTranslateSettingCell.self)
        tableView.lu.register(cellSelf: ChatInfoBotForbiddenCell.self)
        tableView.lu.register(cellSelf: MessagePreventLeakCell.self)
        tableView.lu.register(cellSelf: MessagePreventLeakSubSwitchCell.self)
        tableView.lu.register(cellSelf: MessagePreventLeakBurnTimeCell.self)
        // 注册业务方的cellTypes
        viewModel.chatSettingModule.cellIdToTypeDic().forEach { item in
            tableView.register(item.value, forCellReuseIdentifier: item.key)
        }
        tableView.register(
            GroupSettingSectionView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionView.self)
        )

        self.tableView = tableView
    }

    @objc
    private func shareChatViaLinkBtnTapped() {
        let body = ShareChatViaLinkBody(chatId: viewModel.chat.id, defaultSelected: viewModel.defaultSelected)
        self.viewModel.navigator.open(body: body, from: self)
    }

    @objc
    private func shareUserCardTapped() {
        let content = BundleI18n.LarkChatSetting.Lark_NewContacts_NeedToAddToContactstShareContactCardDialogContent
        self.viewModel.fetchP2PChatterAuthAndHandle(content: content, businessType: .shareConfirm) { [weak self] in
            guard let `self` = self else { return }
            let body = ShareUserCardBody(shareChatterId: self.viewModel.chat.chatterId)
            self.viewModel.navigator.present(body: body,
                                     from: self,
                                     prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        }
    }

    // MARK: - UITableViewDelegate
    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // 最后一个section的cell是举报的场景下无header
        if section == (self.items.count - 1) && (self.items.last?.items.contains(where: { $0.type == .report }) ?? false) {
            return nil
        }
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionView.self)) as? GroupSettingSectionView else {
            return nil
        }
        if let title = items.sectionHeader(at: section) {
            header.titleLabel.text = title
            header.titleLabel.isHidden = false
        } else {
            header.titleLabel.isHidden = true
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // 最后一个section的cell是举报的场景下无间距
        if section == (self.items.count - 1) && (self.items.last?.items.contains(where: { $0.type == .report }) ?? false) {
            return 0
        }
        guard items.sectionHeader(at: section) != nil else {
            return 16
        }
        return 36
    }

    // MARK: - UITableViewDataSource
    private func item<T>(for items: [T], at index: Int) -> T? {
        guard index > -1, index < items.count else { return nil }
        return items[index]
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.item(for: self.items, at: section)?.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let section = self.item(for: self.items, at: indexPath.section),
            var item = section.item(at: indexPath.row),
            var cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? CommonCellProtocol {
            item.style = style(for: item, at: indexPath.row, total: section.items.count)
            cell.updateAvailableMaxWidth(self.maxWidth ?? self.view.bounds.width)
            cell.item = item
            return cell
        } else {
            assert(false, "未找到对应的Item or cell")
        }
        return UITableViewCell()
    }
}

protocol ChatInfoControllerAbility: UIViewController {
    func updateRightItems()
}

extension ChatInfoViewController: ChatInfoControllerAbility {

}
