//
//  SendDocController.swift
//  Lark
//
//  Created by lichen on 2018/7/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import LarkModel

#if MessengerMod
import LarkCore
#endif

import LarkUIKit
import LKCommonsLogging
import LarkKeyboardKit
import UniverseDesignColor
import UniverseDesignEmpty
import Homeric
import LKCommonsTracker
import SKFoundation

public final class SendDocController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

    var dismissBlock: (() -> Void)?

    private let viewModel: SendDocViewModel
    let tableView: UITableView = UITableView()
    let emptyView: SendDocEmptyView = SendDocEmptyView()
    let panel: SendDocPanel = SendDocPanel()
    /// 搜索框
    private let searchTextWrapperView = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField {
        return searchTextWrapperView.searchUITextField
    }
    /// 横滑
    private(set) var swipeManager: HorizontalSwipeManager
    private(set) lazy var swipeGesture: UIPanGestureRecognizer = {
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(swipeAction(_:)))
        swipeGesture.minimumNumberOfTouches = 1
        swipeGesture.maximumNumberOfTouches = 1
        swipeGesture.delegate = self
        return swipeGesture
    }()
    
    private var tableViewContentWidth: CGFloat {
        var contentWidth = tableView.frame.width
        tableView.visibleCells.forEach { cell in
            if let cell = cell as? SendDocCell {
                let cellWidth = cell.contentWidth
                contentWidth = cellWidth > contentWidth ? cellWidth : contentWidth
            }
        }
        return contentWidth
    }

    private let disposeBag = DisposeBag()

    static let logger = Logger.log(SendDocController.self, category: "Module.SendDocController")

    public init(viewModel: SendDocViewModel) {
        self.viewModel = viewModel
        self.swipeManager = HorizontalSwipeManager(frameWidtn: tableView.frame.width)
        super.init(nibName: nil, bundle: nil)
        if UserScopeNoChangeFG.MJ.imSendDocSwipeEnable {
            self.tableView.addGestureRecognizer(swipeGesture)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.bgBody

        titleString = viewModel.context.title ?? BundleI18n.CCMMod.Lark_Legacy_SendDocTitle
        addCancelItem()

        searchTextField.canEdit = true
        searchTextField.tapBlock = { (textField) in
            textField.becomeFirstResponder()
        }
        searchTextField.layer.cornerRadius = 6
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        view.addSubview(searchTextWrapperView)
        searchTextWrapperView.backgroundColor = UDColor.bgBody
        searchTextWrapperView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }

        self.view.addSubview(tableView)
        tableView.backgroundColor = UDColor.bgBody
        tableView.lu.register(cellSelf: SendDocCell.self)
        tableView.lu.register(cellSelf: SendDocStatusCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.canCancelContentTouches = true

        self.view.addSubview(self.panel)
        if let sureTitle = viewModel.context.confirmText {
            panel.setSureTitle(sureTitle)
        }
        panel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(tableView.snp.bottom)
            make.bottom.equalTo(self.view.lkKeyboardLayoutGuide.update(respectSafeArea: true).snp.top)
        }
        panel.leftBtnTappedCallback = { [weak self] in
            guard let `self` = self else { return }
            if self.viewModel.selected.isEmpty { return }
            let viewModel = SendDocSelectedViewModel(
                items: self.viewModel.selected, deleteBlock: { [weak self] (docs) in
                    for doc in docs {
                        self?.viewModel.selectOrUnselected(doc)
                    }
                    self?.tableView.reloadData()
                }
            )
            let sendDocSelectVC = SendDocSelectController(viewModel: viewModel)
            self.navigationController?.pushViewController(sendDocSelectVC, animated: true)
        }

        panel.sureCallback = { [weak self] in
            self?.viewModel.didClickConfirm = true
            self?.navigationController?.dismiss(animated: true, completion: {
                self?.viewModel.sendDoc()
            })
        }

        self.view.addSubview(self.emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalTo(tableView)
        }
        emptyView.isHidden = true

        self.viewModel.reloadDriver.drive(onNext: { [weak self] (_) in
            guard let self else { return }
            self.tableView.reloadData()
            self.swipeManager.updateContentWidth(self.tableViewContentWidth)
        }).disposed(by: self.disposeBag)

        self.viewModel.selectedDriver.drive(onNext: { [weak self] (docs) in
            self?.panel.setSelectCount(docs.count)
        }).disposed(by: self.disposeBag)

        if self.viewModel.sendDocCanSelectType == .sendDocOptionalType {
            //可被选中
            self.panel.isHidden = false
            tableView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(searchTextWrapperView.snp.bottom)
            }
        } else if self.viewModel.sendDocCanSelectType == .sendDocNotOptionalType {
            //不可被选中（点击跳转）
            self.panel.isHidden = true
            tableView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(searchTextWrapperView.snp.bottom)
            }
        }
        swipeManager.updateFrameWidth(view.frame.width)
        //TODO
        //Homeric.IM_CHAT_DOC_PAGE_ADD_VIEW
        Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_ADD_VIEW, params: ["view": "im_chat_doc_page_add_view"]))
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchTextField.resignFirstResponder()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // when user had clicked Confirm, `sendDocBlock` would call immediately
        if !viewModel.didClickConfirm {
            viewModel.sendDocBlock(false, [])
        }
    }

    @objc
    fileprivate func searchTextChanged() {
        self.viewModel.searchDoc(self.searchTextField.text ?? "")
        Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_ADD_CLICK, params: [
            "click": "search_doc",
            "target": "none"
        ]))
    }
    
    @objc
    func swipeAction(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: tableView)
        guard swipeManager.canSwiped else {
            //没有超过屏幕的标题，不能滑动
            return
        }
        if translation.x < 0, swipeManager.isEnd {
            //右滑到头不能继续滑动
            return
        }
        if translation.x > 0, swipeManager.offset == 0 {
            //左滑到头不能继续滑动
            return
        }
        /// 计算当前偏移量
        let distance = translation.x * -1
        var offset = swipeManager.offset + distance
        if offset <= 0 {
            offset = 0
        }
        if offset > swipeManager.overFrameWidth {
            offset = swipeManager.overFrameWidth
        }
        switch sender.state {
        case .changed:
            UIView.animate(withDuration: .zero, delay: .zero) { [weak self] in
                guard let self else { return }
                self.tableView.snp.updateConstraints { make in
                    make.left.equalToSuperview().offset(offset * -1)
                }
            }
        case .ended:
            swipeManager.updateOffset(offset)
            if swipeManager.offset <= 0 {
                swipeManager.updateContentWidth(tableViewContentWidth)
            }
        default:
            return
        }
    }
    // MARK: - UITableViewDataSource, UITableViewDelegate
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? SendDocCell else { return }
        if self.viewModel.sendDocCanSelectType == .sendDocOptionalType {
            //可以被选中
            // Select at SendDocStatusCell
            let count = viewModel.showDocs.count
            if indexPath.row == count {
                tableView.deselectRow(at: indexPath, animated: false)
                return
            }
            guard indexPath.row < count else { return }
            let doc = self.viewModel.showDocs[indexPath.row]
            let isSelected = viewModel.isSelected(doc)
            let isAchievedMaxCountBefore = isAchievedMaxCount()
            if !isSelected && isAchievedMaxCountBefore {
                tableView.deselectRow(at: indexPath, animated: false)
                return
            }
            self.viewModel.selectOrUnselected(doc)
            // already be the max count can select
            let isAchievedMaxCountAfter = isAchievedMaxCount()
            if isAchievedMaxCountAfter || isAchievedMaxCountBefore {
                tableView.reloadData()
            } else {
                cell.setDoc(doc, selected: !isSelected)
                tableView.deselectRow(at: indexPath, animated: false)
            }
        } else if self.viewModel.sendDocCanSelectType == .sendDocNotOptionalType {
            //不可被选中（点击跳转）
            let sendDocModel = self.viewModel.showDocs[indexPath.row]
            let setLabelNameControllerVC = SetLabelNameController(viewModel: sendDocModel, chat: self.viewModel.chat!, chatOpenTabService: self.viewModel.context.chatOpenTabService)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_ADD_CLICK, params: [
                "click": "select_doc_mobile",
                "target": "im_chat_doc_page_name_setting_view"
            ]))
            self.navigationController?.pushViewController(setLabelNameControllerVC, animated: true)
        }
    }

    public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SendDocCell else {
            return
        }
        cell.update(isHighlight: true)
    }

    public func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SendDocCell else {
            return
        }
        cell.update(isHighlight: false)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellSelectEnable = !isAchievedMaxCount()
        if indexPath.row < self.viewModel.showDocs.count {
            let identifier = String(describing: SendDocCell.self)
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SendDocCell {
                let doc = self.viewModel.showDocs[indexPath.row]
                cell.setDoc(doc, selected: self.viewModel.isSelected(doc))
                cell.update(enable: cellSelectEnable || self.viewModel.isSelected(doc))
                return cell
            }
        } else {
            let identifier = String(describing: SendDocStatusCell.self)
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SendDocStatusCell {
                cell.searchResult = self.viewModel.searchResult
                return cell
            }
        }
        return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var itemCount = self.viewModel.showDocs.count
        if !self.viewModel.searchKey.isEmpty, (itemCount > 0 || self.viewModel.searchResult != .nomore) {
            itemCount += 1
        }

        self.emptyView.isHidden = itemCount != 0
        self.emptyView.isDocHistory = self.viewModel.searchKey.isEmpty
        return itemCount
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.height

        if offset + height * 2 > contentHeight {
            self.viewModel.loadMoreIfNeeded()
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        swipeManager.updateContentWidth(tableViewContentWidth)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        swipeManager.updateContentWidth(tableViewContentWidth)
    }

    private func isAchievedMaxCount() -> Bool {
        return viewModel.selected.count >= viewModel.context.maxSelect
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == swipeGesture, let gesture = gestureRecognizer as? UIPanGestureRecognizer {
            let offset = gesture.translation(in: tableView)
            if abs(offset.x) > abs(offset.y),
               swipeManager.offset > 0,
               (gesture.state == .changed || gesture.state == .ended || gesture.state == .began) {
                return false
            } else {
                return true
            }
        }
        return true
    }
    
     public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                   shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

class SendDocEmptyView: UIView {

    private let icon: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()
    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(icon)
        self.addSubview(titleLabel)
        backgroundColor = UDColor.bgBody
        icon.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(70.5)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(icon.snp.bottom).offset(20)
        }
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UDColor.textPlaceholder
        self.isDocHistory = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isDocHistory: Bool = true {
        didSet {
            #if MessengerMod
            if isDocHistory {
                icon.image = UDEmptyType.noData.defaultImage()
                titleLabel.text = BundleI18n.CCMMod.Lark_Legacy_RecentEmpty

            } else {
                icon.image = LarkCore.Resources.empty_search
                titleLabel.text = BundleI18n.CCMMod.Lark_Legacy_SearchEmpty
            }
            #endif
        }
    }
}

class SendDocPanel: UIView {
    let leftButton: UIButton
    let sureButton: UIButton
    var sureCallback: (() -> Void)?
    var leftBtnTappedCallback: (() -> Void)?
    var isAutomaticSureButton: Bool = true

    init() {
        let horizonLine = UIView()
        horizonLine.backgroundColor = UDColor.lineDividerDefault

        leftButton = UIButton(type: .custom)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        leftButton.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        leftButton.titleLabel?.textAlignment = .left

        sureButton = UIButton(type: .custom)
        sureButton.backgroundColor = UDColor.getValueByKey(.fillDisabled) ?? UDColor.N400
        sureButton.layer.cornerRadius = 6
        sureButton.layer.masksToBounds = true
        sureButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        sureButton.setTitleColor(UDColor.udtokenBtnPriTextDisabled, for: .disabled)
        sureButton.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        sureButton.isEnabled = false
        sureButton.setTitle(BundleI18n.CCMMod.Lark_Legacy_Send, for: .normal)

        super.init(frame: CGRect.zero)
        leftButton.addTarget(self, action: #selector(didTapLeftBtn), for: .touchUpInside)
        sureButton.addTarget(self, action: #selector(didTapSure), for: .touchUpInside)

        self.backgroundColor = UDColor.bgBody
        self.addSubview(leftButton)
        self.addSubview(sureButton)
        self.addSubview(horizonLine)

        horizonLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(0.5)
        }

        sureButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        sureButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(64)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        leftButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalTo(sureButton)
        }
        setSelectCount(0)
    }

    @objc
    func didTapSure() {
        self.sureCallback?()
    }

    @objc
    func didTapLeftBtn() {
        self.leftBtnTappedCallback?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelectCount(_ selectCount: Int) {
        self.leftButton.setTitle(BundleI18n.CCMMod.Lark_Legacy_SelectedCountHint(selectCount), for: .normal)

        if selectCount > 0 {
            self.sureButton.isEnabled = true
            sureButton.backgroundColor = UDColor.primaryContentDefault
        } else {
            self.sureButton.isEnabled = false
            sureButton.backgroundColor = UDColor.getValueByKey(.fillDisabled) ?? UDColor.N400
        }

        if !self.isAutomaticSureButton {
            self.sureButton.isEnabled = true
            sureButton.backgroundColor = UDColor.primaryContentDefault
        }
    }

    func setSureTitle(_ title: String) {
        sureButton.setTitle(title, for: .normal)
    }
}
