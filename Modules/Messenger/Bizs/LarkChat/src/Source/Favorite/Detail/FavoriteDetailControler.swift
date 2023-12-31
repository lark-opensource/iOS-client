//
//  FavoriteDetailControler.swift
//  Lark
//
//  Created by lichen on 2018/6/4.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkContainer
import LarkCore
import LKCommonsLogging
import EENavigator
import LarkAlertController
import LarkMessengerInterface
import UniverseDesignToast

public final class FavoriteDetailControler: FavoriteBaseControler {

    static let logger = Logger.log(FavoriteDetailControler.self, category: "favorite.detail.view.controller")

    public let viewModel: FavoriteDetailViewModel
    let dispatcher: RequestDispatcher

    private var viewWidth: CGFloat = 0

    public init(viewModel: FavoriteDetailViewModel, dispatcher: RequestDispatcher) {
        self.viewModel = viewModel
        self.dispatcher = dispatcher
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.LarkChat.Lark_Legacy_Detail
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.addNavigationBarRightItem()
        self.viewModel.datasource.asDriver()
            .drive(onNext: { [weak self] (datasource) in
                guard let `self` = self else { return }
                self.datasource = datasource
                self.table.reloadData()
            })
            .disposed(by: self.disposeBag)

        self.viewModel.dataProvider.deleteFavoritesPush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.popSelf()
            })
            .disposed(by: self.disposeBag)

        self.viewModel.dataProvider.refreshObserver
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.table.reloadData()
            }).disposed(by: disposeBag)

        self.viewWidth = self.view.frame.width
    }

    fileprivate func addNavigationBarRightItem() {

        var rightBarButtonItems: [UIBarButtonItem] = []

        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 18

        if self.viewModel.supportDelete() {
            let deleteItem = LKBarButtonItem(image: Resources.deleteFavorite)
            deleteItem.button.addTarget(self, action: #selector(deleteButtonClick), for: .touchUpInside)
            deleteItem.button.contentHorizontalAlignment = .right
            rightBarButtonItems.append(deleteItem)
        }

        if self.viewModel.supportForward() {
            if !rightBarButtonItems.isEmpty { rightBarButtonItems.append(spacer) }

            let forwardItem = LKBarButtonItem(image: Resources.forwardFavorite)
            forwardItem.button.addTarget(self, action: #selector(forwardButtonClick), for: .touchUpInside)
            forwardItem.button.contentHorizontalAlignment = .right
            rightBarButtonItems.append(forwardItem)
        }

        self.navigationItem.rightBarButtonItems = rightBarButtonItems
    }

    @objc
    fileprivate func forwardButtonClick() {
        if let data = self.datasource.first,
            let content = data.content as? MessageFavoriteContent {
            ChatTracker.trackFavouriteForward()
            let body = ForwardMessageBody(message: content.message, type: .favorite(data.favorite.id), from: .favorite, supportToMsgThread: true)
            viewModel.navigator.present(
                body: body,
                from: self,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        }
    }

    @objc
    fileprivate func deleteButtonClick() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChat.Lark_Legacy_SaveBoxDeleteConfirm)
        alertController.addCancelButton()
        alertController.addDestructiveButton(text: BundleI18n.LarkChat.Lark_Legacy_Remove, dismissCompletion: {
            let hud = UDToast.showDefaultLoading(on: self.view, disableUserInteraction: true)
            self.viewModel.deleteFavorite()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    hud.remove()
                    self?.popSelf()
                }, onError: { [weak self] (error) in
                    FavoriteDetailControler.logger.error("delete favorite failed", error: error)
                    if let self = self {
                        hud.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_SaveBoxDeleteFail, on: self.view, error: error)
                    }
                })
                .disposed(by: self.disposeBag)
        })
        viewModel.navigator.present(alertController, from: self)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.dataProvider.audioPlayer.stopPlayingAudio()
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if viewWidth != self.view.frame.width {
            self.table.reloadData()
        }
    }
}

public class FavoriteBaseControler: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {

    public let disposeBag = DisposeBag()

    public var datasource: [FavoriteCellViewModel] = []

    public var cellFactory: FavoriteCellFactory!

    public lazy var table: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.estimatedRowHeight = 68
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UIColor.clear
        return tableView
    }()

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.table.reloadData()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(self.table)
        self.table.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = self.datasource[indexPath.row]
        return cellFactory.dequeueReusableCell(with: viewModel.identifier,
                                               maxContentWidth: view.frame.width,
                                               viewModel: viewModel)
    }
}
