//
//  TabManagementController.swift
//  LarkSpaceKit
//
//  Created by zhangxingcheng on 2021/7/30.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import LarkCore
import LarkUIKit
import LarkOpenChat
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignToast
import Homeric
import LKCommonsTracker
import UniverseDesignActionPanel
import EENavigator
import LarkAlertController
import LarkMessengerInterface
import LarkContainer

final class TabManagementController: BaseUIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }

    struct TabManagementLayout {
        static let itemHeight: CGFloat = 48
        static let headerHeight: CGFloat = 48
        static let collectionInsetTop: CGFloat = 16
        static let collectionInsetBottom: CGFloat = 8
    }

    func calculateHeight(bottomInset: CGFloat) -> CGFloat {
        var contentHeight: CGFloat = CGFloat(self.viewModel.manageItems.count) * TabManagementLayout.itemHeight + TabManagementLayout.collectionInsetTop + TabManagementLayout.headerHeight
        contentHeight += TabManagementLayout.collectionInsetBottom
        if displayAddEntry {
            contentHeight += CGFloat(addEntrys.count + 1) * TabManagementLayout.itemHeight + TabManagementLayout.collectionInsetTop
        }
        return contentHeight + bottomInset
    }

    static let logger = Logger.log(TabManagementController.self, category: "Module.IM.ChatTab")

    /**当前cell是否可编辑（默认不可编辑）*/
    private var tableEditOrFinishType: ChatTabManagementStatus

    /**长按后临时保存的Cell*/
    private var temporaryCell: TabManagementCollectionCell?
    /**当前手势是否在拖拽中*/
    private var onUserDrag = false

    private let disposeBag = DisposeBag()

    /**导航栏*/
    private lazy var tabManagementNavigationView: TabManagementNavigationView = {
        let nvaigationView = TabManagementNavigationView(targetVC: self, canManageTab: self.viewModel.canManageTab)
        return nvaigationView
    }()

    /**collectionView*/
    private lazy var tabManagementCollectionView: UICollectionView = {
        let collectionViewLayout = TabManagementCollectionCellFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumLineSpacing = 0
        let collectionView = ChatTabManagementCollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = false
        collectionView.backgroundColor = UIColor.ud.bgFloatBase
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.register(TabManagementCollectionCell.self, forCellWithReuseIdentifier: TabManagementCollectionCell.reuseId)
        collectionView.register(TabManagementAddCellCollectionCell.self, forCellWithReuseIdentifier: TabManagementAddCellCollectionCell.reuseId)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressEvent(gesture:)))
        longPressGesture.delegate = self
        collectionView.addGestureRecognizer(longPressGesture)
        return collectionView
    }()
    private var viewWidth: CGFloat = 0
    private var shouldShowLoadingHud = true
    private var hud: UDToast?
    private let viewModel: TabManagementViewModel

    private var originManageItems: [ChatTabManageItem] = []

    let tabModule: ChatTabModule
    let displayAddEntry: Bool
    let addEntrys: [ChatAddTabEntry]
    let jumpTab: (ChatTabContent?, Int64) -> Void
    let addTab: (ChatTabType) -> Void

    init(viewModel: TabManagementViewModel,
         tabModule: ChatTabModule,
         displayAddEntry: Bool,
         addEntrys: [ChatAddTabEntry],
         jumpTab: @escaping (ChatTabContent?, Int64) -> Void,
         addTab: @escaping (ChatTabType) -> Void) {
        self.tableEditOrFinishType = .normal
        self.viewModel = viewModel
        self.tabModule = tabModule
        self.displayAddEntry = displayAddEntry
        self.addEntrys = addEntrys
        self.jumpTab = jumpTab
        self.addTab = addTab
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        IMTracker.Chat.TabManagement.View(self.viewModel.getChat())
        self.view.backgroundColor = UIColor.ud.bgFloatBase
        self.view.addSubview(self.tabManagementCollectionView)

        // 创建导航
        self.view.addSubview(self.tabManagementNavigationView)
        self.tabManagementNavigationView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(TabManagementLayout.headerHeight)
        }
        self.view.addSubview(self.tabManagementCollectionView)
        self.tabManagementCollectionView.snp.makeConstraints { (make) in
            make.top.equalTo(tabManagementNavigationView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        self.tabManagementNavigationView.sortOrFinishBlock = { [weak self] (_ managementStatus: ChatTabManagementStatus) in
            guard let self = self else { return }
            self.tableEditOrFinishType = managementStatus
            switch managementStatus {
            case .normal:
                self.reOrderItems()
                Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_MANAGE_CLICK,
                                      params: ["click": "save_doc_page_manage",
                                               "target": "im_chat_main_view"]))
            case .sorting:
                self.originManageItems = self.viewModel.manageItems
            }
            //刷新表格
            self.tabManagementCollectionView.reloadData()
        }

        self.tabManagementNavigationView.closeViewBlock = { [weak self] in
            guard let self = self else { return }
            if self.tableEditOrFinishType == .sorting {
                self.tableEditOrFinishType = .normal
                self.viewModel.manageItems = self.originManageItems
                self.originManageItems = []
                self.tabManagementCollectionView.reloadData()
                return
            }
            //关闭按钮事件
            self.dismiss(animated: true, completion: nil)
        }

        self.viewModel.canManageTab
            .distinctUntilChanged { $0.0 == $1.0 && $0.1 == $1.1 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tabManagementCollectionView.reloadData()
            }).disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard self.viewWidth != self.view.bounds.width else { return }
        self.viewWidth = self.view.bounds.width
        DispatchQueue.main.async {
            self.tabManagementCollectionView.reloadData()
        }
    }

    @objc
    func longPressEvent(gesture: UILongPressGestureRecognizer) {
        //如果为不可编辑状态直接返回
        if self.tableEditOrFinishType == .normal {
            return
        }

        let gestureState = gesture.state

        switch gestureState {
        case .began:
            // 点击区域超出Cell return
            let point = gesture.location(in: tabManagementCollectionView)
            guard self.view.frame.width - point.x < 90 else { return }
            guard let selectedIndexPath = tabManagementCollectionView.indexPathForItem(at: point) else {
                self.temporaryCell = nil
                return
            }
            // cell不支持点击 return
            let tabTestModel = self.viewModel.manageItems[selectedIndexPath.row]
            if tabTestModel.canBeSorted == false {
                return
            }
            /**当前正在拖拽中*/
            self.onUserDrag = true
            // 满足条件获取Cell
            self.temporaryCell = tabManagementCollectionView.cellForItem(at: selectedIndexPath) as? TabManagementCollectionCell
            tabManagementCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            if self.temporaryCell != nil {
                if self.temporaryCell?.transform == CGAffineTransform.identity {
                    self.temporaryCell?.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                }
            }
        case .changed:
            var point = gesture.location(in: self.tabManagementCollectionView)
            point.x = self.tabManagementCollectionView.bounds.width / 2
            tabManagementCollectionView.updateInteractiveMovementTargetPosition(point)
        case .ended:
            self.onUserDrag = false
            self.temporaryCell?.transform = CGAffineTransform.identity
            tabManagementCollectionView.endInteractiveMovement()
        default:
            self.onUserDrag = false
            self.temporaryCell?.transform = CGAffineTransform.identity
            tabManagementCollectionView.cancelInteractiveMovement()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.viewModel.move(from: sourceIndexPath.item, to: destinationIndexPath.item)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_MANAGE_CLICK, params: [
            "click": "drag_doc",
            "target": "im_chat_doc_page_manage_view"
        ]))

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.tabManagementCollectionView.reloadData()
            }
            CATransaction.commit()
        }, completion: { _ in

        })
    }

    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        /// 用户拖拽编辑中
        if !onUserDrag {
            return true
        }

        let tabTestModel = self.viewModel.manageItems[indexPath.row]
        if tabTestModel.canBeSorted == false {
            return false
        } else {
            return true
        }
    }

    // 是否可以拖动到目标位置
    public func collectionView(_ collectionView: UICollectionView,
                               targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath,
                               toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        guard onUserDrag, proposedIndexPath.section == 0 else { return originalIndexPath }

        let tabTestModel = self.viewModel.manageItems[proposedIndexPath.row]
        if tabTestModel.canBeSorted == false {
            return originalIndexPath
        } else {
            return proposedIndexPath
        }
    }

    /// UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width - 16 * 2, height: TabManagementLayout.itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if !displayAddEntry {
            return UIEdgeInsets(top: TabManagementLayout.collectionInsetTop, left: 0, bottom: TabManagementLayout.collectionInsetBottom, right: 0)
        }
        if section == 0 {
            return UIEdgeInsets(top: TabManagementLayout.collectionInsetTop, left: 0, bottom: 0, right: 0)
        }
        return UIEdgeInsets(top: TabManagementLayout.collectionInsetTop, left: 0, bottom: TabManagementLayout.collectionInsetBottom, right: 0)
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return displayAddEntry ? 2 : 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return self.viewModel.manageItems.count
        } else {
            return self.addEntrys.count + 1
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabManagementCollectionCell.reuseId, for: indexPath)
            if let tabCollectionCell = cell as? TabManagementCollectionCell {
                let index = indexPath.item
                let chatTabManageItem = self.viewModel.manageItems[index]
                let tabId = chatTabManageItem.tabId
                tabCollectionCell.setTabManagementCellModel(chatTabManageItem, cellEditStatus: self.tableEditOrFinishType, enable: self.viewModel.canManageTab.value.0)
                // 点击...事件
                tabCollectionCell.cellMoreBlock = { [weak self] sourceView in
                    guard let self = self else { return }
                    self.clickMore(tabId, sourceView: sourceView)
                }
                let isLast = viewModel.manageItems.count - 1 == indexPath.item
                tabCollectionCell.setBottomBorderHidden(isLast)
            }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabManagementAddCellCollectionCell.reuseId, for: indexPath)
        let index = indexPath.item
        if index < self.addEntrys.count {
            let entry = self.addEntrys[index]
            if let addCollectionCell = cell as? TabManagementAddCellCollectionCell {
                addCollectionCell.setTitle(entry.title, enable: true)
                addCollectionCell.setBottomBorderHidden(false)
            }
            return cell
        }
        if let addCollectionCell = cell as? TabManagementAddCellCollectionCell {
            addCollectionCell.setTitle(BundleI18n.LarkChat.Lark_IM_AddTab_Button, enable: self.viewModel.canManageTab.value.0)
            addCollectionCell.setBottomBorderHidden(true)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if self.tableEditOrFinishType == .normal {
                //当前展示完成按钮（表格可编辑）
                let chatTabManageItem = self.viewModel.manageItems[indexPath.row]
                self.jumpTab(nil, chatTabManageItem.tabId)
                let chat = self.viewModel.getChat()
                guard let content = self.viewModel.getTab(chatTabManageItem.tabId),
                      let clickParams = self.tabModule.getClickParams(ChatTabMetaModel(chat: chat, type: content.type, content: content)) else {
                    return
                }
                IMTracker.Chat.TabManagement.Click.TabClick(
                    chat,
                    params: clickParams
                )
            }
            return
        }
        let index = indexPath.item
        if index < self.addEntrys.count {
            let entry = self.addEntrys[index]
            self.addTab(entry.type)
            return
        }
        if !self.viewModel.canManageTab.value.0 {
            UDToast.showTips(with: self.viewModel.canManageTab.value.1 ?? "", on: self.view)
            return
        }
        let body = ChatAddTabBody(
            chat: self.viewModel.getChat(),
            completion: { [weak self] tabContent in
                guard let self = self else { return }
                self.presentedViewController?.dismiss(animated: true)
                self.jumpTab(tabContent, tabContent.id)
            }
        )
        IMTracker.Chat.TabManagement.Click.TabAdd(self.viewModel.getChat())
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
    }

    private func clickMore(_ tabId: Int64, sourceView: UIView) {
        if !self.viewModel.canManageTab.value.0 {
            UDToast.showTips(with: self.viewModel.canManageTab.value.1 ?? "", on: self.view)
            return
        }
        guard let item = self.viewModel.manageItems.first(where: { $0.tabId == tabId }) else {
            assertionFailure("can not find tab \(tabId)")
            return
        }
        let sourceRect: CGRect = CGRect(origin: .zero, size: sourceView.bounds.size)
        let source = UDActionSheetSource(sourceView: sourceView, sourceRect: sourceRect, arrowDirection: .up)
        let actionsheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: source))
        if item.canEdit {
            actionsheet.addDefaultItem(text: BundleI18n.LarkChat.Lark_IM_EditTabs_Title) { [weak self] in
                guard let self = self,
                      let item = self.viewModel.manageItems.first(where: { $0.tabId == tabId }),
                      let tabContent = self.viewModel.getTab(item.tabId) else { return }
                let editViewController = TabManagementEditViewController(
                    userResolver: self.viewModel.userResolver,
                    chat: self.viewModel.getChat(),
                    tabTitle: item.name,
                    tabContent: tabContent
                )
                editViewController.updateCompletion = { [weak self] tabContent in
                    guard let self = self else { return }
                    self.presentedViewController?.dismiss(animated: true)
                    if let index = self.viewModel.manageItems.firstIndex(where: { $0.tabId == tabContent.id }),
                       let newItem = self.tabModule.getTabManageItem(ChatTabMetaModel(chat: self.viewModel.getChat(), type: tabContent.type, content: tabContent)) {
                        self.tabManagementCollectionView.performBatchUpdates { [weak self] in
                            guard let self = self else { return }
                            self.viewModel.manageItems.remove(at: index)
                            self.viewModel.manageItems.insert(newItem, at: index)
                            self.tabManagementCollectionView.reloadSections(IndexSet(integer: 0))
                        }
                    }
                }
                self.navigator.present(editViewController, wrap: LkNavigationController.self, from: self)
            }
        }
        if item.canBeDeleted {
            actionsheet.addDefaultItem(text: BundleI18n.LarkChat.Lark_IM_Tabs_RemoveTabs_Button_Mobile) { [weak self] in
                self?.deleteItem(tabId)
            }
        }
        actionsheet.setCancelItem(text: BundleI18n.LarkChat.Lark_Legacy_Cancel)
        navigator.present(actionsheet, from: self)
    }

    private func deleteItem(_ tabId: Int64) {
        guard let item = self.viewModel.manageItems.first(where: { $0.tabId == tabId }) else {
            assertionFailure("can not find tab \(tabId)")
            return
        }
        let alertController = LarkAlertController()
        alertController.setContent(text: BundleI18n.LarkChat.Lark_IM_DeleteTab_ConfirmDelete(item.name))
        alertController.addSecondaryButton(text: BundleI18n.LarkChat.Lark_Legacy_Cancel)
        alertController.addDestructiveButton(
            text: BundleI18n.LarkChat.Lark_IM_RemoveTab_Button,
            dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.shouldShowLoadingHud = true
                _ = Observable<Void>.empty()
                    .delay(.milliseconds(300), scheduler: MainScheduler.instance)
                    .subscribe { [weak self] _ in
                        guard let self = self else { return }
                        guard self.shouldShowLoadingHud else { return }
                        self.hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
                    }.disposed(by: self.disposeBag)

                self.viewModel.delete(tabId: tabId)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] deleteTabId in
                        guard let self = self else { return }
                        self.shouldShowLoadingHud = false
                        self.hud?.remove()
                        UIView.performWithoutAnimation {
                            guard let deleteIndex = self.viewModel.manageItems.firstIndex(where: { $0.tabId == deleteTabId }) else { return }
                            self.viewModel.manageItems.remove(at: deleteIndex)
                            self.tabManagementCollectionView.reloadSections(IndexSet(integer: 0))
                        }
                    }, onError: { [weak self] error in
                        guard let self = self else { return }
                        self.shouldShowLoadingHud = false
                        self.hud?.remove()
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)
                    }).disposed(by: self.disposeBag)
                IMTracker.Chat.TabManagement.Click.TabDelete(self.viewModel.getChat(), tabId: item.tabId)
            }
        )
        navigator.present(alertController, from: self)
    }

    private func reOrderItems() {
        self.shouldShowLoadingHud = true
        _ = Observable<Void>.empty()
            .delay(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                guard self.shouldShowLoadingHud else { return }
                self.hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
            }.disposed(by: self.disposeBag)

        self.viewModel.reOrder()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.shouldShowLoadingHud = false
                self.hud?.remove()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.shouldShowLoadingHud = false
                self.hud?.remove()
                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)
            }).disposed(by: self.disposeBag)
        IMTracker.Chat.TabManagement.Click.ReOrder(self.viewModel.getChat())
    }
}

final class ChatTabManagementCollectionView: UICollectionView {

    override func layoutSubviews() {
        super.layoutSubviews()

        for subview in subviews {
            if let cell = subview as? UICollectionViewCell {
                adjustCornerRadius(for: cell)
            }
        }
    }

    private func adjustCornerRadius(for cell: UICollectionViewCell) {
        guard let indexPath = indexPath(for: cell) else {
            return
        }
        let countOfRows = numberOfItems(inSection: indexPath.section)

        cell.clipsToBounds = true
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 10

        if countOfRows == 1 {
            cell.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            switch indexPath.row {
            case 0:
                cell.layer.maskedCorners = [
                    .layerMinXMinYCorner,
                    .layerMaxXMinYCorner
                ]
            case countOfRows - 1:
                cell.layer.maskedCorners = [
                    .layerMinXMaxYCorner,
                    .layerMaxXMaxYCorner
                ]
            default:
                cell.layer.maskedCorners = []
            }
        }
    }
}
