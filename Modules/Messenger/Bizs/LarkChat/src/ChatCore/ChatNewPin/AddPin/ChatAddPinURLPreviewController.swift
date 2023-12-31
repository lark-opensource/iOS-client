//
//  ChatAddPinURLPreviewController.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/5.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import LarkMessageCore
import RxSwift
import RxCocoa
import LarkCore
import LarkContainer
import LarkMessengerInterface
import EENavigator
import UniverseDesignToast
import UniverseDesignEmpty

final class ChatAddPinURLPreviewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private static let logger = Logger.log(ChatAddPinURLPreviewController.self, category: "Module.IM.ChatPin")

    private lazy var addItem: LKBarButtonItem = {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkChat.Lark_IM_NewPin_AddPinnedLink_Add_Button)
        rightItem.button.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
        rightItem.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        rightItem.button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        rightItem.button.addTarget(self, action: #selector(clickAdd), for: .touchUpInside)
        rightItem.isEnabled = false
        return rightItem
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(ChatAddPinURLPreviewTableViewCell.self, forCellReuseIdentifier: ChatAddPinURLPreviewTableViewCell.reuseIdentifier)
        return tableView
    }()

    private lazy var failedView: UIView = {
        let retryTitle = BundleI18n.LarkChat.Lark_IM_Pinned_LoadingFailedReload_Button
        let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.LarkChat.Lark_IM_Pinned_LoadingFailed_Empty(retryTitle)),
                                   type: .loadingFailure)
        let empty = UDEmpty(config: config)
        let failedView = UIView()
        failedView.backgroundColor = UIColor.ud.bgBase
        failedView.addSubview(empty)
        empty.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.6)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(retry))
        failedView.addGestureRecognizer(tap)
        failedView.isHidden = true
        return failedView
    }()

    private let viewModel: ChatAddPinURLPreviewViewModel
    private let disposeBag = DisposeBag()
    private var exceedSelectLimit: Bool = false
    private let maxSelectCount: Int = 10

    private lazy var titleView: ChatAddPinURLPreviewTitleView = {
        return ChatAddPinURLPreviewTitleView()
    }()

    override var navigationBarStyle: LarkUIKit.NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    init(viewModel: ChatAddPinURLPreviewViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.targetVC = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        self.title = BundleI18n.LarkChat.Lark_IM_NewPin_AddPinnedItem_Button
        self.navigationItem.rightBarButtonItem = self.addItem

        self.view.addSubview(titleView)
        self.view.addSubview(tableView)
        self.view.addSubview(failedView)
        titleView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
        failedView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }

        self.viewModel.titleTypeDriver
            .drive(onNext: { [weak self] titleType in
                guard let self = self else { return }
                self.titleView.set(titleType, userResolver: self.viewModel.userResolver)
            }).disposed(by: self.disposeBag)

        self.viewModel.errorDriver.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.failedView.isHidden = false
        }).disposed(by: self.disposeBag)

        self.viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                guard let self = self else { return }
                Self.logger.info("chatPinCardTrace tableRefreshDriver chatId: \(self.viewModel.chat.id) onNext: \(refreshType.describ)")
                switch refreshType {
                case .refreshTable:
                    self.tableView.reloadData()
                }
                self.fixAddItem()
            }).disposed(by: self.disposeBag)
        self.viewModel.availableMaxWidth = self.view.bounds.width
        self.viewModel.setup()
        self.viewModel.createURLPreview()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let availableMaxWidth = self.view.bounds.width
        if availableMaxWidth != self.viewModel.availableMaxWidth {
            self.viewModel.availableMaxWidth = availableMaxWidth
            self.viewModel.onResize()
        }
    }

    @objc
    private func clickAdd() {
        self.viewModel.addPins()
    }

    @objc
    private func retry() {
        self.failedView.isHidden = true
        self.viewModel.createURLPreview()
    }

    private func fixAddItem() {
        let selectCount = self.viewModel.uiDataSource.filter { $0.isSelected }.count
        if selectCount == 0 {
            self.addItem.isEnabled = false
            self.addItem.resetTitle(title: BundleI18n.LarkChat.Lark_IM_NewPin_AddPinnedLink_Add_Button, font: UIFont.systemFont(ofSize: 16, weight: .medium))
        } else {
            self.addItem.isEnabled = true
            self.addItem.resetTitle(title: BundleI18n.LarkChat.Lark_IM_NewPin_AddPin_AddNum_Button(selectCount), font: UIFont.systemFont(ofSize: 16, weight: .medium))
        }
    }

    // MARK: - UITableViewDelegate && UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = ChatAddPinURLPreviewTableViewCell.reuseIdentifier
        let cell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ChatAddPinURLPreviewTableViewCell)
            ?? ChatAddPinURLPreviewTableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        let cellVM = self.viewModel.uiDataSource[indexPath.row]
        cell.set(
            title: cellVM.title,
            selected: cellVM.isSelected,
            disabelCheck: self.exceedSelectLimit && !cellVM.isSelected,
            isSkeleton: cellVM.isSkeleton,
            toggleCheckStatus: { [weak cellVM, weak self] in
                guard let self = self, let cellVM = cellVM else { return false }
                defer {
                    self.fixAddItem()
                }
                let selectCount = self.viewModel.uiDataSource.filter { $0.isSelected }.count

                if !cellVM.isSelected {
                    if selectCount < self.maxSelectCount - 1 {
                        cellVM.isSelected = true
                        IMTracker.Chat.AddTop.Click.select(self.viewModel.chat, fromSearch: self.viewModel.fromSearch)
                        return true
                    }
                    /// 选中数量达到最大限制
                    else if selectCount == self.maxSelectCount - 1 {
                        cellVM.isSelected = true
                        self.exceedSelectLimit = true
                        self.tableView.reloadData()
                        IMTracker.Chat.AddTop.Click.select(self.viewModel.chat, fromSearch: self.viewModel.fromSearch)
                        return true
                    } else {
                        UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_MaxNumPinned_Hover(self.maxSelectCount), on: self.view)
                        return false
                    }
                } else {
                    cellVM.isSelected = false
                    if selectCount == self.maxSelectCount {
                        self.exceedSelectLimit = false
                        self.tableView.reloadData()
                    }
                    return false
                }
            },
            editHandler: { [weak self, weak cellVM] in
                guard let self = self, let cellVM = cellVM else { return }
                let editTitle = cellVM.title
                let updateTitleVC = ChatPinUpdateTitleViewController(
                    editTitle: editTitle,
                    saveHandler: { [weak cellVM, weak self] newTitle, _, completeHandler in
                        if editTitle != newTitle, let self = self {
                            IMTracker.Chat.AddTop.Click.edit(self.viewModel.chat)
                        }
                        cellVM?.updateTitle(newTitle)
                        completeHandler()
                    }
                )
                self.viewModel.userResolver.navigator.present(
                    updateTitleVC,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepare: { $0.modalPresentationStyle = .formSheet })
            },
            previewToken: cellVM.previewInfo.token
        )
        cellVM.renderContent(cell.containerView)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.viewModel.uiDataSource[indexPath.row].getCellHeight()
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.viewModel.uiDataSource[indexPath.row].getCellHeight()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            self.viewModel.uiDataSource[indexPath.row].willDisplay()
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            self.viewModel.uiDataSource[indexPath.row].didEndDisplay()
        }
    }
}
