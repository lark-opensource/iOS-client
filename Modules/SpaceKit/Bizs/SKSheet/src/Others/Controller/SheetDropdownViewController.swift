//
// Created by duanxiaochen.7 on 2019/8/19.
// Affiliated with SpaceKit.
//
// Description: Sheet Redesign - SheetDropdown List - Modal VC

import Foundation
import UIKit
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignColor

protocol SheetDropdownDelegate: AnyObject {
    var browserBounds: CGRect { get }
    var webviewHeight: CGFloat { get }
    func requestToSwitchToKeyboard(currentDropdownVC: SheetDropdownViewController?)
    func didSelectOption(value: String, shouldDismiss: Bool, callback: String)
    func presentDropdownVC(_: SheetDropdownViewController, completion: @escaping () -> Void)
    func notifyH5ToDismissDropdownVC()
}

class SheetDropdownViewController: OverCurrentContextViewController, UITableViewDataSource, UITableViewDelegate {
    private weak var presentingDelegate: SheetDropdownDelegate?
    private var optionModel: [SheetDropdownInfo] = []
    var selectionCallback = ""
    private let isMultipleSelection: Bool
    private let reuseID = "sheet.dropdown.option"
    private let cellHeight: CGFloat = 52
    private var preferredTrait = UITraitCollection()

    /// 上部空白区域（用来响应点击 dismiss 事件
    private lazy var blankView = UIView().construct { it in
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        it.addGestureRecognizer(tapGestureRecognizer)
    }

    /// 下部整个下拉列表，包含 headerView 和 optionView
    private lazy var presentedView = UIView().construct { it in
        it.backgroundColor = .clear
        it.layer.cornerRadius = 12
        it.layer.maskedCorners = .top
        it.layer.ud.setShadowColor(UDColor.shadowDefaultLg)
        it.layer.shadowOpacity = 1
        it.layer.shadowRadius = 24
        it.layer.shadowOffset = CGSize(width: 0, height: -6)
    }

    /// headerView 右边的键盘按钮
    private lazy var keyboardBtn = UIButton().construct { it in
        it.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        it.setImage(UDIcon.keyboardOutlined, withColorsForStates: [
            (UDColor.iconN1, .normal),
            (UDColor.iconN3, .highlighted),
            (UDColor.iconDisabled, .disabled)
        ])
        it.addTarget(self, action: #selector(notifyH5ToSwitchToKeyboard), for: .touchUpInside)
    }

    /// 下拉列表的 header view
    private lazy var headerView = SKPanelHeaderView().construct { it in
        it.backgroundColor = UDColor.bgFloat
    }

    /// 下拉列表本体
    private lazy var optionView = UITableView(frame: .zero, style: .plain).construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.register(SheetDropdownOptionCell.self, forCellReuseIdentifier: reuseID)
        it.isScrollEnabled = true
        it.separatorColor = UDColor.lineDividerDefault
        it.allowsMultipleSelection = isMultipleSelection
        it.dataSource = self
        it.delegate = self
        it.layer.masksToBounds = true
        it.clipsToBounds = true
        it.separatorStyle = .none
    }

    private lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: emptyConfig)
        emptyView.useCenterConstraints = true
        return emptyView
    }()

    private lazy var emptyConfig: UDEmptyConfig = {
        let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.CreationDoc_Sheets_DropDown_NoOption),
                                   imageSize: 80,
                                   type: .noContent)
        return config
    }()

    private var presentedViewPreferredHeight: CGFloat {
        guard let browserViewBounds = presentingDelegate?.browserBounds else { return 0 }
        let browserHeight: CGFloat
        // 由于调用该方法的时候取到的可能是转屏前的 bounds，所以做一下处理
        // preferredTrait 会在即将转屏的时候立即赋值为新的 trait，所以取 verticalSizeClass 拿到的是准确的目标
        if preferredTrait.verticalSizeClass == .compact {
            browserHeight = min(browserViewBounds.height, browserViewBounds.width)
        } else {
            browserHeight = browserViewBounds.height
        }
        let minHeight = browserHeight * 0.25
        let maxHeight = browserHeight * 0.45
        var contentHeight = CGFloat(optionModel.count) * cellHeight
        if optionModel.isEmpty {
            contentHeight = 167
        }
        let neededHeight = headerViewPreferredHeight + contentHeight + safeArea.bottom
        return max(min(neededHeight, maxHeight), minHeight)
    }

    private var headerViewPreferredHeight: CGFloat {
        if preferredTrait.verticalSizeClass == .compact {
            return 0
        } else {
            return 48
        }
    }

    var visualHeight: CGFloat {
        return presentedViewPreferredHeight + 5 // 阴影 5pt
    }

    init(delegate: SheetDropdownDelegate?, isMultipleSelection: Bool) {
        presentingDelegate = delegate
        self.isMultipleSelection = isMultipleSelection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return super.supportedInterfaceOrientations
        }
        return [.allButUpsideDown]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredTrait = traitCollection

        assembleHeaderView()
        headerView.isHidden = preferredTrait.verticalSizeClass == .compact
        assemblePresentedView()

        view.addSubview(presentedView)
        presentedView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(presentedViewPreferredHeight)
        }

        view.addSubview(blankView)
        blankView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(presentedView.snp.top)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        relayoutPresentedView()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        relayoutPresentedView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: Notification.Name.Docs.modalViewControllerWillAppear, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name.Docs.modalViewControllerWillDismiss, object: nil)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        preferredTrait = newCollection
        super.willTransition(to: newCollection, with: coordinator)
        if SKDisplay.pad {
            self.presentingDelegate?.notifyH5ToDismissDropdownVC()
        }
        coordinator.animate(alongsideTransition: { _ in
            self.relayoutPresentedView()
        }, completion: { _ in
            self.relayoutPresentedView()
        })
    }

    @objc
    private func tapToDismiss() {
        dismiss(animated: true) { [weak self] in
            self?.presentingDelegate?.notifyH5ToDismissDropdownVC()
        }
    }

    @objc
    private func notifyH5ToSwitchToKeyboard() {
        presentingDelegate?.requestToSwitchToKeyboard(currentDropdownVC: self)
    }

    func update(info: [SheetDropdownInfo]) {
        optionModel = info
        optionView.reloadData()
    }

    private var safeArea: UIEdgeInsets { view.window?.safeAreaInsets ?? view.safeAreaInsets }

    private func relayoutPresentedView() {
        preferredTrait = traitCollection
        headerView.isHidden = preferredTrait.verticalSizeClass == .compact
        headerView.toggleSeparator(isHidden: optionModel.isEmpty)
        optionView.isHidden = optionModel.isEmpty
        emptyView.isHidden = !optionModel.isEmpty
        headerView.snp.updateConstraints { make in
            make.height.equalTo(headerViewPreferredHeight)
            make.left.equalToSuperview().offset(safeArea.left)
            make.right.equalToSuperview().offset(-safeArea.right)
        }
        optionView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(safeArea.left)
            make.right.equalToSuperview().offset(-safeArea.right)
        }
        presentedView.snp.updateConstraints { make in
            make.height.equalTo(presentedViewPreferredHeight)
        }
        presentedView.layoutIfNeeded()
    }

    private func assembleHeaderView() {
        headerView.setTitle(BundleI18n.SKResource.Doc_Sheet_Dropdown)
        headerView.setCloseButtonAction(#selector(tapToDismiss), target: self)

        headerView.addSubview(keyboardBtn)
        keyboardBtn.snp.makeConstraints { make in
            make.centerY.equalTo(headerView.titleCenterY)
            make.trailing.equalToSuperview().offset(-16)
            make.height.width.equalTo(24)
        }
    }

    private func assemblePresentedView() {
        presentedView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(headerViewPreferredHeight)
            make.left.equalToSuperview().offset(safeArea.left)
            make.right.equalToSuperview().offset(-safeArea.right)
        }

        presentedView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }

        presentedView.addSubview(optionView)
        optionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(safeArea.left)
            make.right.equalToSuperview().offset(-safeArea.right)
        }
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        optionModel[indexPath.row].isSelected.toggle()
        tableView.reloadRows(at: [indexPath], with: .none)
        presentingDelegate?.didSelectOption(value: optionModel[indexPath.row].optionValue, shouldDismiss: !isMultipleSelection, callback: selectionCallback)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        if let cell = cell as? SheetDropdownOptionCell {
            configureCell(cell, with: optionModel[indexPath.row])
        }
        return cell
    }

    private func configureCell(_ cell: SheetDropdownOptionCell, with info: SheetDropdownInfo) {
        cell.update(text: info.optionValue, bgColor: info.optionColor, textColor: info.textColor, isSelected: info.isSelected)
    }
}
