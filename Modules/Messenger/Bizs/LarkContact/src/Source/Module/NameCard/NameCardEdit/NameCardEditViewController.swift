//
//  NameCardEditViewController.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/13.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignToast
import RxSwift
import RxCocoa
import RustPB
import EENavigator
import UniverseDesignDialog
import UniverseDesignEmpty
import UniverseDesignActionPanel
import FigmaKit
import LarkContainer

final class NameCardEditViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {

    private let disposeBag: DisposeBag = DisposeBag()
    var userResolver: LarkContainer.UserResolver
    private let viewModel: NameCardEditViewModel
    private weak var focusedInputView: UIView?
    private weak var focusedInputCellViewModel: NameCardEditItemViewModel?
    private let cellsMap: [NameCardEditType: NameCardEditCellProtocol.Type]
    private weak var popGesDelegate: UIGestureRecognizerDelegate?

    // 右上保存按钮
    private lazy var saveButtonItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: nil, title: BundleI18n.LarkContact.Lark_Contacts_AddContactCardConfirm)
        item.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .center)
        item.addTarget(self, action: #selector(saveData), for: .touchUpInside)
        item.setBtnColor(color: UIColor.ud.colorfulBlue)
        return item
    }()

    private let tableView: UITableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.lu.register(cellSelf: NameCardEditCell.self)
        return tableView
    }()

    // 空态页
    private weak var emptyView: UDEmptyView?
    private weak var selectAccountPanel: UDActionPanel?
    private var didAppear = false
    private var nameCell: NameCardEditCell?

    init(viewModel: NameCardEditViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        self.cellsMap = [.phone: NameCardEditPhoneCell.self,
                         .extra: NameCardEditRemarkCell.self]
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()

        NotificationCenter.default.addObserver(self, selector: #selector(onAccountPermissionLost), name: .LKNameCardNoPermissionNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController as? LkNavigationController {
            nav.update(style: .custom(.ud.bgBase, tintColor: nav.navigationBar.tintColor))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setPopGesDelegate(true)
        didAppear = true
        nameCell?.textField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setPopGesDelegate(false)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    // 更新信息
    @objc
    private func saveData() {
        _saveData()
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        _keyboardWillShow(notification)
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        _keyboardWillHide(notification)
    }

    @objc
    private func hideKeyboard() {
        _hideKeyboard()
    }

    @objc
    override func backItemTapped() {
        if tryShowAlertForExit() {
            self.popSelf()
        }
    }

    @objc
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return tryShowAlertForExit()
    }

    /// 邮箱账号权限失效，退出编辑
    @objc
    private func onAccountPermissionLost(notification: Notification) {
        popSelf()
    }

    // MARK: - UITableViewDataSource && UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataSource[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellVM = viewModel.dataSource[safe: indexPath.section]?[safe: indexPath.row] else {
            return UITableViewCell()
        }
        let cellType = cellsMap[cellVM.type] ?? NameCardEditCell.self
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellType.identifier, for: indexPath) as? NameCardEditCellProtocol else {
            return UITableViewCell()
        }
        if cellVM.type == .name, let cell = cell as? NameCardEditCell {
            if didAppear {
                cell.textField.becomeFirstResponder()
            } else {
                nameCell = cell
            }
        }
        cell.delegate = self
        cell.setCellViewModel(cellVM)
        return cell
    }

    /// Create fixed spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

// MARK: - 数据相关
extension NameCardEditViewController {
    private func bind() {
        delayAndShowLoading()
        viewModel.dataSourceObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if !self.viewModel.dataSource.isEmpty {
                    self.tableView.reloadData()
                }
                self.addEmptyViewIfNeeded()
            }, onError: { [weak self] _ in
                guard let self = self else { return }
                self.addEmptyViewIfNeeded()
            }).disposed(by: disposeBag)

        viewModel.savableStateObserable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] savable in
                guard let self = self else { return }
                self.saveButtonItem.isEnabled = savable
                self.saveButtonItem.setBtnColor(color: savable ? UIColor.ud.colorfulBlue : UIColor.ud.textDisabled)
            }).disposed(by: disposeBag)
    }

    // 上传信息
    private func _saveData() {
        guard !viewModel.isLoading else { return }
        if let text = viewModel.checkAll() {
            NameCardEditViewModel.log.info("saveData: preCheck: \(text)")
            self.tableView.reloadData()
            return
        }
        viewModel.updateData()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (success, text) in
                guard let self = self else { return }
                self._hideKeyboard()
                guard let window = self.view.window else {
                    assertionFailure("缺少 window")
                    return
                }
                if !text.isEmpty {
                    UDToast.showTips(with: text, on: window)
                }
                self.viewModel.callback?(success)
                if success {
                    self.popSelf()
                } else {
                    self.tableView.reloadData()
                }
            }).disposed(by: disposeBag)
    }
}

// MARK: - 布局
extension NameCardEditViewController {
    private func setupViews() {
        self.title = viewModel.getTitle()
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(tableView)
        for cellType in self.cellsMap.values {
            tableView.register(cellType.self, forCellReuseIdentifier: cellType.identifier)
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(horizontal: 16, vertical: 0)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tableView.addGestureRecognizer(tap)
        registerNotifications()
    }

    private func delayAndShowLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, self.viewModel.dataSource.isEmpty else { return }
            self.loadingPlaceholderView.isHidden = false
        }
    }

    // 添加空态页
    private func addEmptyViewIfNeeded() {
        guard viewModel.shouldShowEmptyState else {
            self.loadingPlaceholderView.isHidden = true
            self.emptyView?.removeFromSuperview()
            self.emptyView = nil
            self.navigationItem.rightBarButtonItem = self.saveButtonItem
            return
        }
        self.loadingPlaceholderView.isHidden = true
        let emptyView = UDEmptyView(config: UDEmptyConfig(type: .defaultPage))
        self.emptyView = emptyView
        self.view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - NameCardSelectAccountViewDelegate
extension NameCardEditViewController: NameCardSelectAccountViewDelegate {
    var selectedAccount: String {
        viewModel.getItem(type: .account)?.content ?? ""
    }

    func didTapClose() {
        dismissSelectAccountPanel()
    }

    func didSelectAccount(_ account: String) {
        let indexPath = viewModel.updateSelectedAccount(account)
        tableView.reloadRows(at: [indexPath], with: .none)
        dismissSelectAccountPanel()
    }

    private func dismissSelectAccountPanel() {
        selectAccountPanel?.dismiss(animated: true)
        selectAccountPanel = nil
    }
}

// MARK: - Cell事件
extension NameCardEditViewController: NameCardEditCellDelegate {
    func becomeFirstResponser(_ focusedInputView: UIView, _ cellVM: NameCardEditItemViewModel?) {
        self.focusedInputView = focusedInputView
        self.focusedInputCellViewModel = cellVM
    }

    func textDidChange(_ cellVM: NameCardEditItemViewModel?) {
        check(cellVM)
    }

    func tapCountryCodeView() {
        showCountryCodeSelectController()
    }

    func tapSelectAccount() {
        let vc = UIViewController()
        let contentView = NameCardSelectAccountView(accounts: viewModel.mailAccounts, delegate: self)
        vc.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let originY = UIScreen.main.bounds.height - contentView.estimateHeight - view.safeAreaInsets.bottom
        let panelVC = UDActionPanel(customViewController: vc, config: UDActionPanelUIConfig(originY: originY, canBeDragged: false, dismissByDrag: { [weak self] in
            self?.selectAccountPanel = nil
        }))
        selectAccountPanel = panelVC
        present(panelVC, animated: true)
    }

    private func check(_ cellVM: NameCardEditItemViewModel?) {
        guard let vm = cellVM, let needUpdatendexPath = viewModel.checkSingle(vm) else { return }
        guard let cell = self.tableView.cellForRow(at: needUpdatendexPath) as? NameCardEditCellProtocol else { return }
        cell.setCellViewModel(vm)
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}

// MARK: - 手机点击区域号码
extension NameCardEditViewController {

    private func showCountryCodeSelectController() {
        let settings = viewModel.getCodeSettings()
        let vc = MobileCodeSelectViewController(mobileCodeLocale: settings.language, topCountryList: settings.countryList, blackCountryList: settings.blackCountryList) { [weak self] code in
            guard let indexPath = self?.viewModel.updateCountryCode(code) else { return }
            self?.tableView.reloadRows(at: [indexPath], with: .none)
        }

        if Display.pad {
            navigator.present(vc, from: self, prepare: { $0.modalPresentationStyle = .formSheet }
            )
        } else {
            navigator.present(vc, from: self)
        }
    }
}

// MARK: - 键盘相关
extension NameCardEditViewController {

    private func registerNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    private func _keyboardWillShow(_ notification: Notification) {
        guard let focusedInputView = self.focusedInputView,
              let focusedInputCellViewModel = self.focusedInputCellViewModel else { return }
        guard let focusedParentView = focusedInputView.superview else { return }
        // 获取输入框相对于self.view的位置
        let focusedViewRect = focusedParentView.convert(focusedInputView.frame, to: self.view)
        // 获取键盘相对于self.view的Y值
        let keyBoardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let keyboardY = self.view.bounds.size.height - keyBoardRect.size.height

        // 如果可输入view没有被键盘遮挡，则直接返回
        let value = focusedViewRect.maxY - keyboardY
        guard value > 0 else { return }

        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0

        // 如果键盘盖住了输入框
        UIView.animate(withDuration: duration) {
        } completion: { _ in
//            let value1 = self.tableView.bounds.size.height - self.tableView.contentSize.height
//            if value1 > 0 {
//                value += value1
//            }
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyBoardRect.size.height, right: 0)
            guard let indexPath = self.viewModel.getIndex(focusedInputCellViewModel) else { return }
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    private func _keyboardWillHide(_ notification: Notification) {
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0
        UIView.animate(withDuration: duration) {
            var inset = self.tableView.contentInset
            inset.bottom = 0.0
            self.tableView.contentInset = inset
        }
    }

    private func _hideKeyboard() {
        self.view.endEditing(true)
    }
}

// MARK: 页面退出时需要弹框提示
extension NameCardEditViewController: UIGestureRecognizerDelegate {
    private func setPopGesDelegate(_ isSetDelegate: Bool) {
        if isSetDelegate {
            self.popGesDelegate = self.navigationController?.interactivePopGestureRecognizer?.delegate
            self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        } else {
            self.navigationController?.interactivePopGestureRecognizer?.delegate = self.popGesDelegate
        }
    }

    private func tryShowAlertForExit() -> Bool {
        guard viewModel.judgeIsModified() else {
            return true
        }
        showAlertForExit()
        return false
    }

    // 当用户退出编辑时需要弹框
    private func showAlertForExit() {
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.LarkContact.Lark_Contacts_DiscardChangesConfirmation, numberOfLines: 0)
        dialog.addSecondaryButton(text: BundleI18n.LarkContact.Lark_Contacts_Cancel)
        dialog.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Contacts_Discard, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.popSelf()
        })
        self.present(dialog, animated: true, completion: nil)
    }
}
