//
//  AtPickerController.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/3.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import EENavigator
import UniverseDesignToast
import LarkModel
import LKCommonsLogging
import LarkKeyboardKit
import LarkKeyCommandKit
import LarkMessengerInterface
import LarkPerf
import LarkContainer

final class AtPickerController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate,
                          TableViewKeyboardHandlerDelegate {
    private let disposeBag = DisposeBag()
    private var comfirmDate: TimeInterval = 0

    private var viewModel: AtPickerViewModel

    private var selectedView = SelectedCollectionView()
    private var pickerToolBar = DefaultPickerToolBar()
    private var searchWrapper = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField
    private var table = ChatChatterBaseTable(frame: .zero, style: .plain)
    private var keyboardHandler: TableViewKeyboardHandler?

    private lazy var bottomCoverView: ChatterListBottomTipView = {
        return ChatterListBottomTipView(frame: ChatterListBottomTipView.defaultFrame(self.view.bounds.width))
    }()

    private lazy var atAllView = {
        return AtPickerAtAllView(
            usersCount: Int(viewModel.chat.userCount),
            showChatUserCount: viewModel.showChatUserCount,
            width: self.view.bounds.width
        )
    }()

    private lazy var myAiView = {
        return AtPickerMyAiView()
    }()

    private lazy var headerView: AtPickerHeaderView = {
        return AtPickerHeaderView(atAllView: self.atAllView, myAiView: self.myAiView)
    }()

    private lazy var rightItem: UIBarButtonItem = {
        return UIBarButtonItem(
            title: BundleI18n.LarkChat.Lark_Legacy_Select,
            style: .plain,
            target: self,
            action: #selector(toggleViewSelectStatus))
    }()

    public var displayMode: ChatChatterDisplayMode = .display {
        didSet { table.reloadData() }
    }

    private var datas: [ChatChatterSection] = []

    var isAtAllShouldShow: Bool {
        return (viewModel.allowAtAll || viewModel.allowMyAi) && viewModel.filterKey.isEmpty && displayMode == .display
    }

    public var selectUserCallback: AtPickerBody.AtPickerSureCallBack?

    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() +
            (keyboardHandler?.baseSelectiveKeyBindings ?? []) +
            (self.displayMode == .multiselect ? [confirmAtKeyBinding] : [] )
    }

    // cmd + enter
    private var confirmAtKeyBinding: KeyBindingWraper {
        weak var `self` = self
        return KeyCommandBaseInfo(input: UIKeyCommand.inputReturn, modifierFlags: .command)
            .binding(handler: { self?.confirmAt() })
            .wraper
    }

    init(viewModel: AtPickerViewModel) {
        self.viewModel = viewModel
        self.searchTextField = self.searchWrapper.searchUITextField
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchTextField.canEdit = true
        searchTextField.placeholder = BundleI18n.LarkChat.Lark_Legacy_Search
        self.view.addSubview(searchWrapper)
        searchWrapper.snp.makeConstraints({ make in
            make.left.right.top.equalToSuperview()
        })

        self.view.addSubview(selectedView)
        selectedView.setSelectedCollectionView(selectItems: [], didSelectBlock: { [weak self] (item) in
            self?.selectedViewSeleced(item)
        }, animated: false)
        selectedView.snp.makeConstraints { (maker) in
            maker.top.equalTo(searchWrapper.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(44)
        }

        pickerToolBar.setItems(pickerToolBar.toolbarItems(), animated: false)
        pickerToolBar.allowSelectNone = false
        updatePickerToolBar()
        pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in self?.confirmAt() }
        self.view.addSubview(pickerToolBar)
        self.pickerToolBar.isHidden = true
        self.pickerToolBar.snp.updateConstraints {
            $0.height.equalTo(49)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(self.avoidKeyboardBottom)
        }

        table.delegate = self
        table.dataSource = self
        table.estimatedRowHeight = 68
        table.rowHeight = 68
        table.separatorStyle = .none
        table.sectionIndexBackgroundColor = .clear
        table.sectionIndexColor = UIColor.ud.textTitle
        table.lu.register(cellSelf: ChatChatterCell.self)
        table.lu.register(cellSelf: ChatChatterProfileCell.self)
        table.lu.register(cellSelf: AtNoResultCell.self)
        table.register(
            GrayTableHeader.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GrayTableHeader.self))
        table.register(
            ContactTableHeader.self,
            forHeaderFooterViewReuseIdentifier: String(describing: ContactTableHeader.self))
        self.displayMode = .display

        self.view.addSubview(table)
        table.snp.makeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.bottom.left.right.equalToSuperview()
        }

        self.view.bringSubviewToFront(pickerToolBar)

        title = BundleI18n.LarkChat.Lark_Legacy_TitleSelectMember
        navigationItem.rightBarButtonItem = self.rightItem
        addCloseItem()

        bandingViewModelEvent()
        addSearchObserver()

        let startTimestamp = CACurrentMediaTime()
        self.viewModel.loadChatter()
        viewModel.onDataReady = { (result) in
            switch result {
            case .success(let isRemote):
                DispatchQueue.main.async {
                    AtAppReciableTracker.updateSDKCost(
                        cost: (CACurrentMediaTime() - startTimestamp) * 1000,
                        isRemote: isRemote
                    )
                    AtAppReciableTracker.end()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    AtAppReciableTracker.error(error)
                }
            }
        }
        self.headerView.snp.makeConstraints {
            $0.width.equalTo(view.bounds.width)
        }
        headerView.state = .init(hasAi: viewModel.isMyAiEnable, hasAll: viewModel.allowAtAll)
        self.headerView.layoutIfNeeded()
        table.tableHeaderView = headerView
        if viewModel.allowAtAll {
            atAllView.onTap = { [weak self] in
                self?.confirmAtAll()
            }
        }
        if viewModel.isMyAiEnable {
            myAiView.ai = viewModel.aiEntity
            myAiView.onTap = { [weak self] in
                self?.confirmMyAi()
            }
        }

        AtAppReciableTracker.firstRenderEnd()
        keyboardHandler = TableViewKeyboardHandler()
        keyboardHandler?.delegate = self
    }

    private var isAppeared: Bool = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isAppeared {
            isAppeared = true
            // 在有外接键盘的 iPad 上，自动聚焦 searchTextField
            if Display.pad && KeyboardKit.shared.keyboardType == .hardware {
                self.searchTextField.becomeFirstResponder()
            }
        }
    }

    /// switch table display mode between *dispaly* and *multiple selection*
    @objc
    private func toggleViewSelectStatus() {
        if self.displayMode == .multiselect {
            switchToSingleSelect()
        } else {
            switchToMultiSelect()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let header = self.table.tableHeaderView {
            header.frame = AtPickerAtAllView.defaultFrame(size.width)
            header.snp.updateConstraints {
                $0.width.equalTo(size.width)
            }
            header.layoutIfNeeded()
            self.table.tableHeaderView = header
        }

        if let footer = self.table.tableFooterView {
            footer.frame = ChatterListBottomTipView.defaultFrame(size.width)
            self.table.tableFooterView = footer
        }
    }

    private func refreshFotterView() {
        bottomCoverView.title = BundleI18n.LarkChat.Lark_Group_HugeGroup_MemberList_Bottom
        table.tableFooterView = viewModel.shouldShowTipView && viewModel.filterKey.isEmpty ? bottomCoverView : nil
    }

    // MARK: - TableViewKeyboardHandlerDelegate
    func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView { table }

    // MARK: - UITableViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if searchTextField.canResignFirstResponder == true {
            searchTextField.resignFirstResponder()
        }
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // remove seleced background
        tableView.deselectRow(at: indexPath, animated: true)

        // get seleced cell and item
        guard let cell = tableView.cellForRow(at: indexPath) as? ChatChatterCellProtocol,
            let item = cell.item
            else { return }

        switch displayMode {

        case .display:
            if let item = item as? AtPickerItem {
                self.confirmAt(item)
            }
        case .multiselect:
            guard item.isSelectedable, let item = item as? AtPickerItem else { return }

            let cells = tableView.visibleCells.compactMap { (cell) -> ChatChatterCellProtocol? in

                if let cell_ = cell as? ChatChatterCellProtocol, cell_.item?.itemId == item.itemId {
                    return cell_
                }

                return nil
            }

            if viewModel.isItemSelected(item) {
                for var cell in cells { cell.isCheckboxSelected = false }
                viewModel.deselected(item)
                onDeselected(item)
            } else {
                for var cell in cells { cell.isCheckboxSelected = true }
                viewModel.selected(item)
                onSelected(item)
            }
        }
    }
    // swiftlint:enable did_select_row_protection

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section >= datas.count || datas[section].title?.isEmpty ?? true || datas[section].title == nil {
            return 0
        }

        return 30
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section < datas.count {
            let sectionItem = datas[section]
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: sectionItem.sectionHeaderClass))
            (header as? ChatChatterSectionHeaderProtocol)?.set(sectionItem)
            return header
        }
        return nil
    }

    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.shouldShowIndex ? datas.map { $0.indexKey } : nil
    }
    // MARK: - UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return datas.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < datas.count else { return 0 }
        return datas[section].items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < datas.count, indexPath.row < datas[indexPath.section].items.count else {
            return UITableViewCell()
        }

        let item = datas[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: item.itemCellClass), for: indexPath)

        if var itemCell = cell as? ChatChatterCellProtocol {
            itemCell.set(item, filterKey: viewModel.filterKey, userResolver: viewModel.userResolver)

            if displayMode == .multiselect {
                itemCell.isCheckboxHidden = false
                itemCell.isCheckboxSelected = viewModel.selectedItems.contains(where: { $0.itemId == item.itemId })
            } else {
                itemCell.isCheckboxHidden = true
                itemCell.isCheckboxSelected = viewModel.selectedItems.contains(where: { $0.itemId == item.itemId })
            }
            (itemCell as? ChatChatterProfileCell)?.personCardButtonTapHandler = { [weak self] chatterID in
                guard let self = self else { return }
                self.gotoPersonCardWith(chatterID: chatterID, fromVC: self)
            }
        }
        return cell
    }

    func gotoPersonCardWith(chatterID: String, fromVC: UIViewController) {
        let body = PersonCardBody(chatterId: chatterID)
        let presentStyle = Display.phone ? UIModalPresentationStyle.pageSheet : UIModalPresentationStyle.formSheet
        viewModel.userResolver.navigator.present(
            body: body,
            wrap: LkNavigationController.self, from: fromVC,
            prepare: { vc in
                vc.modalPresentationStyle = presentStyle
            })
    }
}

// MARK: - confirm at
private extension AtPickerController {
    func confirmAt(_ item: AtPickerItem? = nil) {
        if comfirmRepeated() { return } // 避免短时间多次触发，例如键盘回车
        self.dismiss(animated: true, completion: nil)
        // multiselect
        if self.displayMode == .multiselect {
            self.selectUserCallback?(self.viewModel.selectedItems.map { (item) -> AtPickerBody.SelectedItem in
                ChatTracker.trackAtPerson(params: item.trackExtension.toDictionary(item.isOuter))
                return AtPickerBody.SelectedItem(id: item.itemId,
                                                 name: item.itemName,
                                                 actualName: item.chatter.localizedName,
                                                 isOuter: item.isOuter)
            })
        } else if let item = item {
            ChatTracker.trackAtPerson(params: item.trackExtension.toDictionary(item.isOuter))
            self.selectUserCallback?([AtPickerBody.SelectedItem(id: item.itemId,
                                                                name: item.itemName,
                                                                actualName: item.chatter.localizedName,
                                                                isOuter: item.isOuter)])
        }
    }

    // for at all memebers
    func confirmAtAll() {
        self.dismiss(animated: true, completion: nil)
        ChatTracker.trackAtAll()
        self.selectUserCallback?([
            AtPickerBody.SelectedItem(id: AtPickerAtAllView.defaultAtAllId,
                                      name: BundleI18n.LarkChat.Lark_Legacy_AllPeople,
                                      actualName: "",
                                      isOuter: false)
        ])
    }
    func confirmMyAi() {
        self.dismiss(animated: true, completion: nil)
        self.selectUserCallback?([
            AtPickerBody.SelectedItem(id: (try? viewModel.userResolver.resolve(type: MyAIService.self).defaultResource.mockID) ?? "",
                                      name: "MyAi",
                                      actualName: "",
                                      isOuter: false)
        ])
    }
    private func comfirmRepeated() -> Bool {
        let currentDate = Date().timeIntervalSince1970 * 1000
        if (currentDate - comfirmDate) > 500 {
            comfirmDate = currentDate
            return false
        }
        return true
    }
}

// MARK: - UI Event
private extension AtPickerController {

    /// update pickerToolBar status
    /// - Parameter isClean: default is *true* will reset pickerToolBar,
    ///     pass *false* to set selected datas count
    func updatePickerToolBar(isClean: Bool = true) {
        if isClean {
            pickerToolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        } else {
            pickerToolBar.updateSelectedItem(
                firstSelectedItems: viewModel.selectedItems,
                secondSelectedItems: [],
                updateResultButton: true
            )
        }
    }

    /// swicth to *.multiSelect* for Multiselect
    /// - change top right button title to *Cancel*
    /// - show top selected preview list
    /// - show bottom picker tool bar
    /// - reload table to show check box
    func switchToMultiSelect() {
        ChatTracker.trackRemoveMemberClick()
        self.rightItem.title = BundleI18n.LarkChat.Lark_Legacy_Cancel
        self.pickerToolBar.isHidden = false
        self.table.snp.remakeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(pickerToolBar.snp.top)
        }

        self.displayMode = .multiselect
        self.table.tableHeaderView = nil
    }

    /// swicth to *dispaly* for single select
    /// - change top right button title to *Multiselect*
    /// - reset and hide top selected preview list
    /// - reset and hide bottom picker tool bar
    /// - reload table to hide check box
    func switchToSingleSelect() {
        self.rightItem.title = BundleI18n.LarkChat.Lark_Legacy_Select

        self.selectedView.removeSelectAllItems()
        self.pickerToolBar.isHidden = true
        self.updatePickerToolBar()
        table.snp.remakeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.bottom.left.right.equalToSuperview()
        }

        self.displayMode = .display
        self.viewModel.selectedItems.removeAll()
        self.headerView.layoutIfNeeded()
        self.table.tableHeaderView = isAtAllShouldShow ? self.headerView : nil
    }

    func selectedViewSeleced(_ item: SelectedCollectionItem) {
        guard let item = item as? AtPickerItem else { return }

        self.viewModel.deselected(item, isTableEvent: false)
        self.updatePickerToolBar(isClean: false)

        if viewModel.selectedItems.isEmpty {
            refreshUI()
        }
    }

    func changeViewStatus(_ status: ChatChatterViewStatus) {
        switch status {
        case .loading:
            loadingPlaceholderView.isHidden = false
        case .error(let error):
            loadingPlaceholderView.isHidden = true

            table.status = viewModel.datas.isEmpty ? .empty : .display
            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)

            AtPickerViewModel.logger.error("AtPickerController load data error", error: error)
        case .viewStatus(let status):
            loadingPlaceholderView.isHidden = true
            table.status = status
            self.headerView.layoutIfNeeded()
            table.tableHeaderView = isAtAllShouldShow ? self.headerView : nil
        }
    }

    func bandingViewModelEvent() {
        viewModel.reloadData.throttle(.milliseconds(200))
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.datas = self.viewModel.datas
                self.table.reloadData()
                self.refreshFotterView()
            }).disposed(by: disposeBag)

        viewModel.statusVar.drive(onNext: { [weak self] (status) in
            self?.changeViewStatus(status)
        }).disposed(by: disposeBag)
    }

    func onSelected(_ item: AtPickerItem) {
        self.selectedView.addSelectItem(selectItem: item)
        self.updatePickerToolBar(isClean: false)
        if viewModel.selectedItems.count == 1 {
            refreshUI()
        }
    }

    func onDeselected(_ item: AtPickerItem) {
        self.selectedView.removeSelectItem(selectItem: item)
        self.updatePickerToolBar(isClean: false)
        if viewModel.selectedItems.isEmpty {
            refreshUI()
        }
    }

    func refreshUI() {
        let isEmpty = viewModel.selectedItems.isEmpty
        self.table.snp.updateConstraints {
            $0.top.equalTo(self.selectedView.snp.top).offset(isEmpty ? 0 : 44)
        }
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        })
    }

    func addSearchObserver() {
        searchTextField.rx.text.asDriver().skip(1)
            .distinctUntilChanged({ (str1, str2) -> Bool in
                return str1 == str2
            })
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (text) in
                self?.viewModel.filterChatter(text ?? "")
                self?.keyboardHandler?.resetFocus()
            }).disposed(by: disposeBag)
    }
}
