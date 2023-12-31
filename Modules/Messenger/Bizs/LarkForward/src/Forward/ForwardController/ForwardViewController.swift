//
//  ForwardVIewController.swift
//  LarkForward
//
//  Created by 姚启灏 on 2018/11/26.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RxSwift
import RxCocoa
import LarkCore
import LarkAlertController
import EENavigator
import UniverseDesignToast
import LarkKeyboardKit
import LarkKeyCommandKit
import LarkMessengerInterface
import LKCommonsTracker
import LarkFocusInterface

public protocol ForwardViewControllerRouter: AnyObject {
    func creatChat(vc: ForwardViewController)
}

// nolint: long_function -- v1转发代码，历史代码全量下线后可删除
public class ForwardViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource,
                             UICollectionViewDelegate, UICollectionViewDataSource, TableViewKeyboardHandlerDelegate {
    weak var router: ForwardViewControllerRouter?

    private let disposeBag = DisposeBag()
    private let viewModel: ForwardViewModel
    private let kSelectedMemberAvatarSpacing: CGFloat = 10.0
    private let kSelectedMemberAvatarSize: CGFloat = 30.0
    private let headerViewHeight: CGFloat = 23
    private let footerViewHeight: CGFloat = 32

    var dataSource: [ForwardSectionData] = []
    private var selectItems: [ForwardItem] = []
    private var selectRecordInfos: [ForwardSelectRecordInfo] = []

    private var animated: Bool = false

    /// 点击导航左边的x按钮退出分享界面
    var cancelCallBack: (() -> Void)?
    /// 分享成功回调
    var successCallBack: (() -> Void)?

    var inputNavigationItem: UINavigationItem?

    private(set) var isMultiSelectMode = false {
        didSet {
            self.viewModel.removeAllSelectItem()
            self.selectRecordInfos.removeAll()
            let currentNavigationItem = inputNavigationItem ?? self.navigationItem
            if isMultiSelectMode {
                currentNavigationItem.leftBarButtonItem = self.cancelItem
                currentNavigationItem.rightBarButtonItem = UIBarButtonItem(customView: sureButton)
            } else {
                currentNavigationItem.leftBarButtonItem = self.leftBarButtonItem
                currentNavigationItem.rightBarButtonItem = self.rightBarButtonItem
            }
            self.updateUI(animated: true)
        }
    }

    private(set) lazy var leftBarButtonItem: UIBarButtonItem = {
        if hasBackPage, navigationItem.leftBarButtonItem == nil {
            return addBackItem()
        }
        if !hasBackPage, presentingViewController != nil {
            return addCancelItem()
        }
        return addCancelItem()
    }()

    private(set) lazy var rightBarButtonItem: UIBarButtonItem? = {
        if self.viewModel.isSupportMultiSelectMode {
            return self.multiSelectItem
        }
        return nil
    }()

    private var loadingView: CoreLoadingView!
    private var noResultView: NoResultView?

    public func content() -> ForwardAlertContent {
        return self.viewModel.provider.content
    }

    var searchWrapper: SearchUITextFieldWrapperView?
    var searchTextField: SearchUITextField! {
        didSet {
            searchTextField.rx.text.asDriver()
                .distinctUntilChanged({ (str1, str2) -> Bool in
                    return str1 == str2
                })
                .drive(onNext: { [weak self] (text) in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.viewModel.matchText(text: text ?? "")
                    weakSelf.noResultView?.isHidden = true
                    weakSelf.keyboardHandler?.resetFocus()
                })
                .disposed(by: self.disposeBag)
        }
    }

    private lazy var creatChatView: UIView = {
        let creatChatView = UIView()
        creatChatView.lu.addTapGestureRecognizer(action: #selector(didTapCreatChatView), target: self, touchNumber: 1)
        return creatChatView
    }()

    private lazy var selectedCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: kSelectedMemberAvatarSize, height: kSelectedMemberAvatarSize)
        layout.minimumInteritemSpacing = kSelectedMemberAvatarSpacing

        let selectedCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        selectedCollectionView.backgroundColor = UIColor.ud.bgBody
        selectedCollectionView.contentInset = UIEdgeInsets(top: 0, left: kSelectedMemberAvatarSpacing, bottom: 0, right: kSelectedMemberAvatarSpacing)
        selectedCollectionView.delegate = self
        selectedCollectionView.dataSource = self
        return selectedCollectionView
    }()

    private lazy var selectedCollectionBottomView: UIView = {
        return UIView()
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.rowHeight = 68
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    // TableView Keyboard
    private var keyboardHandler: TableViewKeyboardHandler?

    private(set) lazy var sureButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(didTapSure), for: .touchUpInside)
        button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        button.setTitleColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle(BundleI18n.LarkForward.Lark_Legacy_Send, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    private(set) lazy var cancelItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkForward.Lark_Legacy_Cancel)
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return btnItem
    }()

    private(set) lazy var multiSelectItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkForward.Lark_Legacy_MultipleChoice)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .right)
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(didTapMultiSelect), for: .touchUpInside)
        return btnItem
    }()

    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? []) + confirmKeyBinding
    }

    private var confirmKeyBinding: [KeyBindingWraper] {
        return isMultiSelectMode && sureButton.isEnabled ? [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkForward.Lark_Legacy_Sure
            )
            .binding(target: self, selector: #selector(didTapSure))
            .wraper
        ] : []
    }

    private var currentAlertController: LarkAlertController?

    public init(viewModel: ForwardViewModel,
         router: ForwardViewControllerRouter,
         inputNavigationItem: UINavigationItem? = nil) {
        self.viewModel = viewModel
        self.router = router
        self.inputNavigationItem = inputNavigationItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkForward.Lark_Legacy_SelectTip

        let headerWrapper = UIView()

        let searchWrapper = SearchUITextFieldWrapperView()
        self.searchWrapper = searchWrapper
        searchTextField = searchWrapper.searchUITextField
        searchTextField.canEdit = true
        headerWrapper.addSubview(searchWrapper)
        searchWrapper.snp.makeConstraints({ make in
            make.left.right.top.equalToSuperview()
        })

        if KeyboardKit.shared.keyboardType == .hardware {
            searchTextField.autoFocus = true
        }

        // 创建新的聊天View
        let creatChatViewLabel = UILabel()
        creatChatViewLabel.text = BundleI18n.LarkForward.Lark_IM_CreateGroupAndSend_Button
        creatChatViewLabel.textAlignment = .center
        creatChatViewLabel.font = UIFont.systemFont(ofSize: 16)
        self.creatChatView.addSubview(creatChatViewLabel)
        creatChatViewLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview().offset(-7)
        }

        let creatChatIcon = UIImageView(image: Resources.mine_right_arrow)
        self.creatChatView.addSubview(creatChatIcon)
        creatChatIcon.snp.makeConstraints { (make) in
            make.centerY.equalTo(creatChatViewLabel)
            make.right.equalToSuperview().offset(-18)
        }

        self.creatChatView.backgroundColor = UIColor.ud.bgBody
        headerWrapper.addSubview(self.creatChatView)
        self.creatChatView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchWrapper.snp.bottom)
            if !self.viewModel.isShowCreatChatView {
                make.height.equalTo(0)
            } else {
                make.height.equalTo(54)
            }
        }
        self.creatChatView.isHidden = !self.viewModel.isShowCreatChatView

        self.view.addSubview(headerWrapper)
        headerWrapper.snp.makeConstraints({ (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(creatChatView.snp.bottom)
        })
        headerWrapper.lu.addBottomBorder()

        // 选中项
        self.view.addSubview(selectedCollectionView)
        selectedCollectionView.snp.makeConstraints({ make in
            make.top.equalTo(headerWrapper.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        })

        // 选中项分割线
        selectedCollectionBottomView.lu.addBottomBorder()
        self.view.addSubview(selectedCollectionBottomView)
        selectedCollectionBottomView.snp.makeConstraints({ (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(selectedCollectionView.snp.bottom)
            make.height.equalTo(0)
        })

        // TableView
        var name = String(describing: ForwardChatTableCell.self)
        tableView.register(ForwardChatTableCell.self, forCellReuseIdentifier: name)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(selectedCollectionBottomView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        // TableView Keyboard
        keyboardHandler = TableViewKeyboardHandler(options: [.allowCellFocused(focused: Display.pad)])
        keyboardHandler?.delegate = self

        // selectedCollectionView
        name = String(describing: AvatarCollectionViewCell.self)
        selectedCollectionView.register(AvatarCollectionViewCell.self, forCellWithReuseIdentifier: name)
        selectedCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "emptyCell")

        self.loadingView = CoreLoadingView()
        self.view.addSubview(self.loadingView)
        self.loadingView.snp.makeConstraints({ make in
            make.top.equalTo(selectedCollectionView.snp.bottom)
            make.left.right.equalToSuperview()
        })
        self.loadingView.hide()

        let noResultView = NoResultView(frame: .zero)
        self.view.addSubview(noResultView)
        self.noResultView = noResultView
        self.noResultView?.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
        }
        self.noResultView?.isHidden = true

        DispatchQueue.main.async {
            let currentNavigationItem = self.inputNavigationItem ?? self.navigationItem
            currentNavigationItem.leftBarButtonItem = self.leftBarButtonItem
            currentNavigationItem.rightBarButtonItem = self.rightBarButtonItem
        }

        self.closeCallback = { [weak self] () in
            guard let `self` = self else { return }
            self.viewModel.provider.dismissAction()
            self.cancelCallBack?()
        }
        self.backCallback = { [weak self] in
            guard let `self` = self else { return }
            self.viewModel.provider.dismissAction()
            self.cancelCallBack?()
        }
        bindViewModel()
        PublicTracker.MultiSelectShare.View()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
    }

    private func bindViewModel() {
        viewModel.loadDefaultData()
        /* 搜索结果数据源驱动 */
        viewModel.dataSourceDriver
            .drive(onNext: { [weak self] (items) in
                guard let `self` = self else { return }
                self.dataSource = items
                self.updateUI(animated: false)
            }).disposed(by: self.disposeBag)

        viewModel.selectItemsDriver
            .drive(onNext: { [weak self] (items) in
                guard let `self` = self else { return }
                self.selectItems = items
                self.updateUI(animated: false)
            }).disposed(by: self.disposeBag)

        /* 是否有更多 */
        viewModel.hasMoreDriver
            .drive(onNext: { [weak self] (hasMore) in
                guard let `self` = self else { return }
                if hasMore {
                    self.tableView.addBottomLoadMoreView { [weak self] in
                        guard let `self` = self else { return }
                        self.viewModel.loadMoreData()
                    }
                } else {
                    self.tableView.removeBottomLoadMore()
                }
            }).disposed(by: self.disposeBag)

        /* 是否显示loading 小菊花 */
        viewModel.isloadingViewShowDriver
            .drive(onNext: { [weak self] (isLoading) in
                guard let `self` = self else { return }
                if isLoading {
                    self.loadingView.show()
                } else {
                    self.loadingView.hide()
                }
            }).disposed(by: self.disposeBag)

        viewModel.showNoResultViewDriver
            .drive(onNext: { [weak self] (showNoResult) in
                guard let `self` = self else { return }
                self.noResultView?.isHidden = !showNoResult
            }).disposed(by: self.disposeBag)
    }

    private func updateUI(animated: Bool = true) {
        self.animated = animated
        self.updateSureStatus()

        let updateCollection = !self.selectItems.isEmpty && isMultiSelectMode

        self.selectedCollectionBottomView.snp.updateConstraints({ (make) in
            make.height.equalTo(updateCollection ? (1 / UIScreen.main.scale) : 0)
        })
        self.selectedCollectionView.snp.updateConstraints { (make) in
            make.height.equalTo(updateCollection ? 44 : 0)
        }

        self.selectedCollectionView.reloadData()
        if updateCollection {
            let indexPath = IndexPath(item: self.selectItems.count - 1, section: 0)
            self.selectedCollectionView.scrollToItem(
                at: indexPath,
                /// iOS13上，只有一个元素时指定right进行scrollToItem会导致这一个元素跑到最右边，造成界面显示异常
                at: self.selectItems.count <= 1 ? .left : .right,
                animated: true
            )
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.selectedCollectionView.layoutIfNeeded()
            })
        }
        self.tableView.reloadData()
    }

    @objc
    private func willResignActive() {
        guard let vc = currentAlertController, vc.presentingViewController != nil else { return }

        vc.dismiss(animated: false, completion: nil)
        self.dismiss(animated: true, completion: { [weak self] in self?.cancelCallBack?() })
    }

    @objc
    private func didTapCreatChatView() {
        Tracer.trackMessageForwardCreateGroupAttempt()
        self.router?.creatChat(vc: self)
    }

    @objc
    func didTapSure(isCreateGroup: Bool = false) {
        var title = selectItems.count == 1 ? BundleI18n.LarkForward.Lark_Legacy_ChatViewSendTo : BundleI18n.LarkForward.Lark_Legacy_ChatViewDeliverSendTo
        if isCreateGroup {
            title = BundleI18n.LarkForward.Lark_IM_CreateGroupAndSend_Title
        }

        if self.searchTextField.isFirstResponder {
            self.searchTextField.resignFirstResponder()
        }

        self.showConfirmVC(alertTitle: title)
        PublicTracker.MultiSelectShare.Click.Confirm()
    }

    private func showConfirmVC(alertTitle: String) {
        viewModel.provider.beforeShowAction()
        let creater = ForwardAlertViewCreater(userResolver: self.viewModel.provider.userResolver,
                                              forwardChats: selectItems,
                                              forwardProvider: viewModel.provider)
        let alertController = LarkAlertController()
        let title = viewModel.provider.getTitle(by: selectItems) ?? alertTitle
        alertController.setTitle(text: title, alignment: .left)
        let contents = creater.createConfirmContentView()
        alertController.setContent(view: contents.0)
        alertController.addCancelButton(dismissCheck: { [weak self] in
            self?.viewModel.provider.cancelAction()
            return true
        })

        let sendText = isMultiSelectMode
            ? BundleI18n.LarkForward.Lark_IM_Forward_SendToNum_Button("\(selectItems.count)")
            : BundleI18n.LarkForward.Lark_Legacy_Send
        alertController.addPrimaryButton(
            text: self.viewModel.provider.getConfirmButtonTitle(by: self.selectItems) ?? sendText,
            dismissCompletion: { [weak self, weak alertController] in
                guard let `self` = self else { return }
                let messageIsEmpty = contents.1?.text.isEmpty ?? true
                Tracker.post(TeaEvent("im_msg_send_confirm_click",
                                      params: ["scene": "group_create_from_forward",
                                               "click": "send",
                                               "target": "none",
                                               "leave_a_message": messageIsEmpty ? false : true]))
                // 合并转发会出现二次弹窗，所以逻辑不一样。
                if self.viewModel.provider is MergeForwardAlertProvider || self.viewModel.provider is EventShareAlertProvider ||
                    self.viewModel.provider is ShareContentAlertProvider {
                    self.viewModel.provider
                        .sureAction(items: self.selectItems, input: contents.1?.text ?? "", from: self)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] (newChatIds)  in
                            // 出现二次弹框时触发onNext，隐藏第一弹窗。
                            guard let `self` = self, !newChatIds.isEmpty else { return }
                            self.viewModel.trackAction(
                                isMultiSelectMode: self.isMultiSelectMode,
                                selectRecordInfo: self.selectRecordInfos,
                                chatIds: newChatIds)
                            alertController?.dismiss(animated: true, completion: nil)
                        }, onCompleted: { [weak self] in
                            guard let `self` = self else { return }
                            alertController?.dismiss(animated: true, completion: nil)
                            self.dismiss(animated: true, completion: { [weak self] in self?.successCallBack?() })
                        }).disposed(by: self.disposeBag)
                } else {
                    self.viewModel.provider
                        .sureAction(items: self.selectItems, input: contents.1?.text ?? "", from: self)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] (newChatIds) in
                            guard let `self` = self else { return }
                            self.viewModel.trackAction(
                                isMultiSelectMode: self.isMultiSelectMode,
                                selectRecordInfo: self.selectRecordInfos,
                                chatIds: newChatIds)
                            self.dismiss(animated: true, completion: { [weak self] in self?.successCallBack?() })
                        }).disposed(by: self.disposeBag)
                }
            })

        currentAlertController = alertController

        self.viewModel.provider.userResolver.navigator.present(alertController, from: self)
        PublicTracker.Send.View()
        Tracker.post(TeaEvent("im_msg_send_confirm_view",
                              params: ["scene": "group_create_from_forward"]))
    }

    @objc
    open func didTapCancel() {
        self.isMultiSelectMode = false
    }

    @objc
    open func didTapMultiSelect() {
        self.isMultiSelectMode = true
    }

    private func updateSureStatus() {
        self.updateSureButton(count: self.selectItems.count)
        if !self.selectItems.isEmpty {
            self.sureButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
            self.sureButton.isEnabled = true
        } else {
            self.sureButton.setTitleColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.6), for: .normal)
            self.sureButton.isEnabled = false
        }
    }

    func updateSureButton(count: Int) {
        var title = BundleI18n.LarkForward.Lark_Legacy_Sure
        if count >= 1 {
            title = BundleI18n.LarkForward.Lark_Legacy_Sure + "(\(count))"
        }
        self.sureButton.setTitle(title, for: .normal)
    }

    // 用于router回调
    func selectNew(item: ForwardItem) {
        self.viewModel.removeAllSelectItem()
        self.selectRecordInfos.removeAll()
        self.viewModel.addSelectItem(item: item)
        didTapSure(isCreateGroup: true)
    }
    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard selectItems.count < indexPath.row,
              selectRecordInfos.count < indexPath.row else { return }
        let model = self.selectItems[indexPath.row]
        self.selectItems.remove(at: indexPath.row)
        self.selectRecordInfos.remove(at: indexPath.row)
        self.selectedCollectionView.deleteItems(at: [indexPath])

        self.viewModel.removeSelectItem(item: model)
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let name = String(describing: AvatarCollectionViewCell.self)
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath) as? AvatarCollectionViewCell {
            let model = self.selectItems[indexPath.row]
            var showThreadTopicIcon = false
            if model.type == .threadMessage {
                showThreadTopicIcon = true
            }
            cell.setContent(model.avatarKey, medalKey: "", id: model.id, showThreadTopicIcon: showThreadTopicIcon)
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "emptyCell", for: indexPath)
        }
    }

    // MARK: - TableViewKeyboardHandlerDelegate
    public func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return self.tableView
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource.count
    }

    // SectionHeader
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (self.dataSource.count == 1 && self.dataSource[section].title.isEmpty) || self.dataSource[section].dataSource.isEmpty {
            return nil
        } else {
            let headerView = UIView()
            headerView.backgroundColor = UIColor.ud.bgBase

            let headerLabel = UILabel()
            headerLabel.textColor = UIColor.ud.textPlaceholder
            headerLabel.textAlignment = .left
            headerLabel.font = UIFont.systemFont(ofSize: 12)
            headerLabel.text = self.dataSource[section].title
            headerView.addSubview(headerLabel)
            headerLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(17)
                make.right.lessThanOrEqualToSuperview()
                make.centerY.equalToSuperview()
                make.height.equalTo(24)
            }

            if section != 0 {
                headerView.lu.addTopBorder()
            }
            headerView.lu.addBottomBorder()

            return headerView
        }
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (self.dataSource.count == 1 && self.dataSource[section].title.isEmpty) || self.dataSource[section].dataSource.isEmpty {
            return 0
        } else {
            return headerViewHeight
        }
    }

    // SectionFooter
    // nolint: duplicated_code 不同的创建视图逻辑,后续该vc会下线
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.dataSource[section].showFooterView {
            let footerView = UIView()
            footerView.backgroundColor = UIColor.ud.bgBody
            let warpperView = UIView()

            let line = UIView()
            line.backgroundColor = UIColor.ud.lineDividerDefault
            footerView.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.height.equalTo(0.5)
                make.top.left.right.equalToSuperview()
            }

            let footerLabel = UILabel()
            footerLabel.text = self.dataSource[section].isFold ? BundleI18n.LarkForward.Lark_Legacy_ItemShowLess : BundleI18n.LarkForward.Lark_Legacy_ItemShowMore
            footerLabel.textColor = UIColor.ud.textPlaceholder
            footerLabel.textAlignment = .center
            footerLabel.font = UIFont.systemFont(ofSize: 12)

            warpperView.addSubview(footerLabel)
            footerLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(7)
                make.bottom.equalToSuperview().offset(-8)
                make.left.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
            }

            let image = self.dataSource[section].isFold ? Resources.table_unfold : Resources.table_fold
            let footerImageView = UIImageView(image: image)
            warpperView.addSubview(footerImageView)
            footerImageView.snp.makeConstraints { (make) in
                make.width.height.equalTo(12)
                make.centerY.equalTo(footerLabel)
                make.left.equalTo(footerLabel.snp.right).offset(4)
                make.right.equalToSuperview()
            }

            footerView.addSubview(warpperView)
            warpperView.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
            }

            footerView.lu.addTapGestureRecognizer(action: #selector(tapFooterView),
                                                  target: self,
                                                  touchNumber: 1)
            return footerView
        } else {
            return nil
        }
    }
    // enable-lint: duplicated_code

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if self.dataSource[section].showFooterView {
            return footerViewHeight
        } else {
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.dataSource[section].dataSource.count
        if self.dataSource[section].showFooterView,
            !self.dataSource[section].isFold,
            self.dataSource[section].dataSource.count > ForwardViewModel.minShowDataCount {
            return ForwardViewModel.minShowDataCount
        } else {
            return count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = String(describing: ForwardChatTableCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? ForwardChatTableCell {
            let model = self.dataSource[indexPath.section].dataSource[indexPath.row]
            if tableView.numberOfRows(inSection: indexPath.section) == (indexPath.row + 1) {
                cell.personInfoView.bottomSeperator.isHidden = true
            } else {
                cell.personInfoView.bottomSeperator.isHidden = false
            }
            cell.setContent(model: model,
                            currentTenantId: self.viewModel.currentTenantId,
                            isSelected: self.selectItems.contains(where: { $0.id == model.id }) && model.hasInvitePermission,
                            hideCheckBox: !isMultiSelectMode,
                            enable: model.hasInvitePermission,
                            animated: animated,
                            focusService: try? self.viewModel.provider.userResolver.resolve(assert: FocusService.self),
                            checkInDoNotDisturb: self.viewModel.checkInDoNotDisturb)
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        if let content = content() as? OpenShareContentAlertContent {
            Tracer.trackForwardSelectChat(source: content.sourceAppName ?? "")
        }

        tableView.deselectRow(at: indexPath, animated: true)

        let model = self.dataSource[indexPath.section].dataSource[indexPath.row]
        if !model.hasInvitePermission {
            guard let window = tableView.window else {
                assertionFailure()
                return
            }
            UDToast.showFailure(
                with: BundleI18n.LarkForward.Lark_NewContacts_CantForwardDueToBlockOthers,
                on: window
            )
            return
        }

        var resultType: ForwardSelectRecordInfo.ResultType
        if self.dataSource[indexPath.section].isSearchResult {
            resultType = .search
        } else {
            if indexPath.section == 0 {
                resultType = .top
            } else {
                resultType = .recent
            }
        }

        if !isMultiSelectMode {
            self.viewModel.removeAllSelectItem()
            self.viewModel.addSelectItem(item: model)
            self.selectRecordInfos.removeAll()
            self.selectRecordInfos.append(ForwardSelectRecordInfo(id: model.id,
                                                                  offset: Int32(indexPath.row),
                                                                  resultType: resultType))
            self.didTapSure()
        } else {
            if selectItems.contains(where: { $0.id == model.id }) {
                self.viewModel.removeSelectItem(item: model)
                self.selectRecordInfos.removeAll { $0.id == model.id }
            } else {
                if selectItems.count < viewModel.maxSelectCount {
                    self.viewModel.addSelectItem(item: model)
                    self.selectRecordInfos.append(ForwardSelectRecordInfo(id: model.id,
                                                                          offset: Int32(indexPath.row),
                                                                          resultType: resultType))
                } else {
                    let alertController = LarkAlertController()
                    alertController.setContent(text: String(format: BundleI18n.LarkForward.Lark_Legacy_MaxChooseLimit, viewModel.maxSelectCount))
                    alertController.addButton(text: BundleI18n.LarkForward.Lark_Legacy_Sure)
                    self.viewModel.provider.userResolver.navigator.present(alertController, from: self)
                }

                if !(self.searchTextField.text?.isEmpty ?? true) {
                    self.searchTextField.text = ""
                    self.searchTextField.resignFirstResponder()
                }
            }
        }
    }

    @objc
    private func tapFooterView() {
        self.viewModel.changeSectionFlod()
    }
}

private final class NoResultView: UIView {
    private let textLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 图标
        let icon = UIImageView()
        icon.image = Resources.search_empty
        self.addSubview(icon)
        icon.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        })
        // 无结果 显示
        // TODO: 缺少文案
        self.addSubview(textLabel)
        textLabel.textAlignment = .center
        textLabel.font = UIFont.systemFont(ofSize: 16)
        textLabel.lineBreakMode = .byTruncatingMiddle
        textLabel.snp.makeConstraints({ make in
            make.top.equalTo(icon.snp.bottom).offset(10)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalToSuperview()
        })
        textLabel.text = BundleI18n.LarkForward.Lark_Legacy_SearchNoAnyResult
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
