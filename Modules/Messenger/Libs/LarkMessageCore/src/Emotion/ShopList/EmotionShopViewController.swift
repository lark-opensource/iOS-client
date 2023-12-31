//
//  EmotionStoreViewController.swift
//  Action
//
//  Created by huangjianming on 2019/8/2.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import EENavigator
import LarkModel
import UniverseDesignToast
import LarkAlertController
import LarkMessengerInterface

public final class EmotionShopViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - 成员变量
    var tableView = UITableView()
    let viewModel: EmotionShopViewModel
    var disposeBag = DisposeBag()
    let emptyViewContainer = UIView()

    lazy var emptyImageView: UIImageView = {
        let emptyImageView = UIImageView()
        emptyImageView.image = BundleResources.emotionEmptyIcon
        return emptyImageView
    }()

    lazy var emptyLabel: UILabel = {
        let emptyLabel = UILabel()
        emptyLabel.font = UIFont.systemFont(ofSize: 16)
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = UIColor.ud.textPlaceholder
        emptyLabel.text = BundleI18n.LarkMessageCore.Lark_Chat_StickerPackNoStore
        return emptyLabel
    }()

    // MARK: - 生命周期
    init(viewModel: EmotionShopViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        self.updateNavibar()
        self.setupTableview()
    }

    // MARK: - 内部方法
    func updateNavibar() {
        addCloseItem()
        addSettingRightItem()
        self.titleString = BundleI18n.LarkMessageCore.Lark_Chat_StickerPackStore
    }

    func addSettingRightItem() {
        let barItem = LKBarButtonItem(image: Resources.emotionSettingRightItemIcon)
        barItem.button.addTarget(self, action: #selector(settingBtnTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = barItem
    }

    func setupTableview() {
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = self.viewModel.cellHeight
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgBody

        let reuseID = String(describing: EmotionShopViewTableViewCell.self)
        tableView.register(EmotionShopViewTableViewCell.self, forCellReuseIdentifier: reuseID)
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        fetchData()
    }

    private var shouldShowLoadingHud = true
    func fetchData() {
        var hud: UDToast?
        self.shouldShowLoadingHud = true
        _ = Observable<Void>.empty().delay(.milliseconds(300), scheduler: MainScheduler.instance).subscribe {[weak self] (_) in
            guard let self = self else { return }
            guard self.shouldShowLoadingHud else { return }
            hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        }

        self.viewModel.dataObserver.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (hasMore) in
            guard let self = self else {
                return
            }
            self.shouldShowLoadingHud = false
            hud?.remove()

            self.hideErrorView()
            self.showAndReloadTableView()
            if hasMore {
                self.addBottomLoadMoveView()
            } else {
                self.removeBottomLoadMoveView()
            }
        }, onError: { [weak self] (_) in
            guard let self = self else { return }
            self.hideTableView()
            self.showErrorView()
        }).disposed(by: self.disposeBag)
        self.viewModel.fetchData()
    }

    func addBottomLoadMoveView() {
        self.tableView.addBottomLoadMoreView {[weak self] in
            guard let self = self else {
                return
            }
            self.viewModel.loadMoreData()
        }
    }

    func hideTableView() {
        self.tableView.isHidden = true
    }

    func showAndReloadTableView() {
        self.tableView.isHidden = false
        self.tableView.reloadData()
    }

    func hideErrorView() {
        self.emptyViewContainer.isHidden = true
        self.emptyViewContainer.removeFromSuperview()
    }

    func showErrorView() {
        self.emptyViewContainer.isHidden = false
        self.view.addSubview(self.emptyViewContainer)
        emptyViewContainer.snp.makeConstraints { (make) in
            make.width.equalTo(125)
            make.height.equalTo(158)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }

        self.emptyViewContainer.addSubview(self.emptyImageView)
        emptyImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(125)
            make.top.left.equalToSuperview()
        }

        self.emptyViewContainer.addSubview(self.emptyLabel)
        emptyLabel.snp.makeConstraints { (make) in
            make.centerX.bottom.equalToSuperview()
        }
    }

    func removeBottomLoadMoveView() {
        self.tableView.removeBottomLoadMore()
    }

    func showUpgradeAlert() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackBuyToast, font: .systemFont(ofSize: 17))
        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackKnow)
        self.viewModel.navigator.present(alertController, from: self)
    }

    // MARK: - 点击事件
    @objc
    private func settingBtnTapped() {
        StickerTracker.trackEmotionSettingShow(from: .fromEmotionShop)
        //右上角设置按钮点击
        let body = EmotionSettingBody(showType: .push)
        self.viewModel.navigator.push(body: body, from: self)
    }
    // MARK: - UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.stickerSets.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseID = String(describing: EmotionShopViewTableViewCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? EmotionShopViewTableViewCell else { return UITableViewCell() }
        guard self.viewModel.stickerSets.count > indexPath.row else { return cell }
        let stickerSet = self.viewModel.stickerSets[indexPath.row]
        let state = self.viewModel.getDownloadState(stickerSet: stickerSet)
        cell.setHasPaid(hasPaid: stickerSet.hasPaid_p)
        cell.configure(stickerSet: stickerSet, state: state) {[weak self] in
            if stickerSet.hasPaid_p {
                StickerTracker.trackStickerSetAdded(from: .emotionShop, stickerID: stickerSet.stickerSetID, stickersCount: stickerSet.stickers.count)
                self?.viewModel.addEmotionPackage(stickerSet: stickerSet)
            } else {
                self?.showUpgradeAlert()
            }
        }
        //如果是最后一个cell,分割线为full
        cell.setSperatorlineStyle(style: indexPath.row == self.viewModel.stickerSets.count - 1 ? .full : .half)
        return cell
    }
    // MARK: - UITableViewDelegate
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        self.tableView.deselectRow(at: indexPath, animated: false)
        let stickerSets = self.viewModel.stickerSets
        let stickerSet = stickerSets[indexPath.row]
        let body = EmotionShopDetailBody(stickerSet: stickerSet)
        self.viewModel.navigator.push(body: body, from: self)
    }
}
