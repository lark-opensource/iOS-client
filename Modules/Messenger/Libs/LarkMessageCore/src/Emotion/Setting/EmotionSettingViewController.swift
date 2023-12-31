//
//  EmotionSettingViewController.swift
//  AudioSessionScenario
//
//  Created by huangjianming on 2019/8/5.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkUIKit
import EENavigator
import LarkModel
import LarkAlertController
import UniverseDesignToast
import LarkMessengerInterface

enum EmotionSettingViewControllerState: Int {
    case Sorting = 0
    case Normal = 1
}

open class EmotionSettingViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: - 成员变量
    var tableViewModel: EmotionSettingTableViewModel
    var disposeBag = DisposeBag()
    private let showType: ShowType
    private var shouldShowLoadingHud = true
    lazy var sortBtn: UIButton = {
        let sortBtn = UIButton()
        sortBtn.titleLabel?.font = .systemFont(ofSize: 16)
        sortBtn.setTitleColor(UIColor.ud.staticBlack, for: .normal)
        sortBtn.setTitleColor(.lightGray, for: .disabled)
        return sortBtn
    }()

    private var tableView = UITableView()
    var hud: UDToast?
    private var state: EmotionSettingViewControllerState = .Normal {
        didSet {
            if oldValue != state {
                self.updateNaviBar()
                self.tableView.setEditing((state == .Normal ? false : true), animated: false)
                self.setDeleteButtonsHidden(shouldHidden: self.tableView.isEditing)
            }
        }
    }

    lazy var headerButton: EmotionSettingHeaderButton = {
        let headerButton = EmotionSettingHeaderButton()
        headerButton.backgroundColor = UIColor.ud.bgBody
        headerButton.addTarget(self, action: #selector(headerButtonClick), for: .touchUpInside)
        return headerButton
    }()

    // MARK: - 生命周期
    public init(viewModel: EmotionSettingTableViewModel, showType: ShowType) {
        self.tableViewModel = viewModel
        self.showType = showType
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        setupheaderButton()
        setupTableview()
        //设置导航栏空间
        setupNaviBar()
    }

    // MARK: - 内部方法
    private func setDeleteButtonsHidden(shouldHidden: Bool) {
        for cell in tableView.visibleCells {
            if let cell = cell as? EmotionSettingTableViewSortCell {
                cell.deleteButton.isHidden = shouldHidden
            }
        }
    }

    private func updateLeftNaviItem() {
        func updateNaviIten () {
            switch self.showType {
            case .present:
                self.addCloseItem()
            case .push:
                self.addBackItem()
            }
        }

        self.state == .Normal ? (updateNaviIten()) : (self.addCancelLeftItem())
    }

    func addCancelLeftItem() {
        let barItem = LKBarButtonItem(title: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackCancel)
        barItem.button.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
    }

    func setupheaderButton() {
        self.view.addSubview(self.headerButton)
        self.headerButton.snp.makeConstraints { (make) in
            make.top.equalTo(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
        }
    }

    func setupNaviBar() {
        self.titleString = BundleI18n.LarkMessageCore.Lark_Chat_StickerPackMySticker
        self.updateNaviBar()
    }

    func setupRightNaviItem() {
        self.sortBtn.addTarget(self, action: #selector(rightBarButtonItemClicked), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: self.sortBtn)
        self.navigationItem.rightBarButtonItems = [rightBarButtonItem]
    }

    func removeRightNaviItem() {
        self.navigationItem.rightBarButtonItems = nil
    }

    func setupTableview() {
        tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(62)

        }
        let DetailCellID = String(describing: EmotionSettingTableViewSortCell.self)
        self.tableView.register(EmotionSettingTableViewSortCell.self, forCellReuseIdentifier: DetailCellID)

        self.tableViewModel.dataDriver.drive(onNext: { [weak self] (_) in
            //为防止状态不对,编辑状态中不允许自动刷新
            guard let self = self, !self.tableView.isEditing else { return }
            self.tableView.reloadData()
            self.updateNaviBar()
        }).disposed(by: self.disposeBag)
    }

    func patchStickerSets() {
        self.shouldShowLoadingHud = true
        _ = Observable<Void>.empty().delay(.milliseconds(300), scheduler: MainScheduler.instance).subscribe { [weak self] (_) in
            guard let self = self else { return }
            guard self.shouldShowLoadingHud else { return }
            self.hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        }

        self.tableViewModel.patch().subscribe(onError: { [weak self] (_) in
            guard let self = self else { return }
            self.shouldShowLoadingHud = false
            self.hud?.remove()
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackNetworkError, font: .systemFont(ofSize: 17))
            alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackKnow)
            self.tableViewModel.navigator.present(alertController, from: self)
        }, onCompleted: {
            self.shouldShowLoadingHud = false
            self.hud?.remove()
        }).disposed(by: self.disposeBag)
    }

    func updateNaviBar() {
        //show sorted button if data count more than 1
        //排序按钮在数据大于1时再展示
        if self.tableViewModel.stickerSets.count > 1 { setupRightNaviItem() } else { removeRightNaviItem() }
        updateLeftNaviItem()
        if self.state == .Normal {
            sortBtn.setTitle(BundleI18n.LarkMessageCore.Lark_Chat_StickerPackReorder, for: .normal)
            sortBtn.setTitleColor(UIColor.ud.N900, for: .normal)
        } else {
            sortBtn.setTitle(BundleI18n.LarkMessageCore.Lark_Chat_StickerPackSave, for: .normal)
            sortBtn.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        }
    }

    // MARK: - 点击事件
    @objc
    private func rightBarButtonItemClicked() {
        if self.state == .Normal {
            self.state = .Sorting
            StickerTracker.trackStickerRecorder()
        } else {
            self.state = .Normal
            self.patchStickerSets()
            StickerTracker.trackStickerRecorderSave()
        }
    }

    @objc
    private func cancelBtnTapped() {
        self.state = .Normal
        self.tableView.setEditing(false, animated: false)
    }

    @objc
    private func headerButtonClick() {
        self.tableViewModel.navigator.push(body: StickerManagerBody(showType: .push), from: self)
    }

    private func deleteCell(index: Int) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackDeleteConfirmContent, font: .systemFont(ofSize: 17))
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_DeleteConfirm, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.shouldShowLoadingHud = true
            _ = Observable<Void>.empty().delay(.milliseconds(300), scheduler: MainScheduler.instance).subscribe { [weak self] (_) in
                guard let self = self else { return }
                guard self.shouldShowLoadingHud else { return }
                self.hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
            }

            self.tableViewModel.delete(idx: index)
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] (_) in
                    guard let self = self else { return }
                    self.shouldShowLoadingHud = false
                    self.hud?.remove()
                    let alertController = LarkAlertController()
                    alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackNetworkError, font: .systemFont(ofSize: 17))
                    alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackKnow)
                    self.tableViewModel.navigator.present(alertController, from: self)
                }, onCompleted: {
                    self.shouldShowLoadingHud = false
                    self.hud?.remove()
                }).disposed(by: self.disposeBag)
        })
        self.tableViewModel.navigator.present(alertController, from: self)
    }
    // MARK: - UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewModel.stickerSets.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let detailCellID = String(describing: EmotionSettingTableViewSortCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: detailCellID) as? EmotionSettingTableViewSortCell
            else { return UITableViewCell() }
        guard self.tableViewModel.stickerSets.count > indexPath.row else { return cell }
        let model = self.tableViewModel.stickerSets[indexPath.row]
        cell.deleteButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.deleteCell(index: indexPath.row)
        }).disposed(by: cell.disposeBag)
        cell.configure(stickerSet: model)
        cell.shouldIndentWhileEditing = false
        cell.deleteButton.isHidden = tableView.isEditing
        //如果是最后一个cell,分割线为full
        cell.setSperatorlineStyle(style: indexPath.row == self.tableViewModel.stickerSets.count - 1 ? .full : .half)
        return cell
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116
    }

    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        //swap
        self.tableViewModel.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    // MARK: - UITableViewDelegate
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.ud.bgBase
        let label = UILabel()
        label.text = BundleI18n.LarkMessageCore.Lark_Chat_StickerPackTitle
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        header.addSubview(label)
        label.sizeToFit()
        label.frame = CGRect(x: 17, y: 14, width: label.frame.size.width, height: label.frame.size.height)

        return header
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.tableViewModel.stickerSets.isEmpty {
            return 0
        }
        return 39
    }

    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return BundleI18n.LarkMessageCore.Lark_Chat_StickerPackDelete
    }

    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        } else {
            return sourceIndexPath
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        self.tableView.deselectRow(at: indexPath, animated: false)
        let stickerSet = self.tableViewModel.stickerSets[indexPath.row]
        let body = EmotionShopDetailBody(stickerSet: stickerSet)
        self.tableViewModel.navigator.push(body: body, from: self)
    }

    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
