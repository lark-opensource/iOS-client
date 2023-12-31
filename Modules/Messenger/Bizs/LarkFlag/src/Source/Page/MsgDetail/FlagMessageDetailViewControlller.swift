//
//  FlagMessageDetailViewControlller.swift
//  Lark
//
//  Created by zc09v on 2018/5/18.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RxSwift
import LarkMessageBase
import LarkMessageCore
import LarkInteraction
import LarkFeatureGating
import RichLabel
import UniverseDesignColor
import RxCocoa

protocol RightBarButtonItemsGenerator {
    func rightBarButtonItems() -> [UIBarButtonItem]
}

final class FlagMessageDetailViewControlller: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let contentTitle: String
    private let viewModel: FlagMessageDetailContentViewModel
    private let disposeBag = DisposeBag()
    private var itemsGenerator: RightBarButtonItemsGenerator?
    private var chat: BehaviorRelay<Chat> {
        return self.viewModel.chatWrapper.chat
    }

    private var viewDidAppeared: Bool = false

    private lazy var tableView: FlagMessageDetailTableView = {
        let tableView = FlagMessageDetailTableView()
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        tableView.uiDataSourceDelegate = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 9, right: 0)
        _ = tableView.lu.addLongPressGestureRecognizer(action: #selector(bubbleLongPressed(_:)), duration: 0.2, target: self)
        let rightClick = RightClickRecognizer(target: self, action: #selector(bubbleLongPressed(_:)))
        tableView.addGestureRecognizer(rightClick)
        return tableView
    }()

    public lazy var label: UILabel = {
        let labelView = UILabel()
        labelView.textColor = UIColor.ud.textPlaceholder
        labelView.font = UIFont.systemFont(ofSize: 16)
        labelView.textAlignment = .center
        labelView.numberOfLines = 0
        return labelView
    }()

    public lazy var bottomView: UIView = {
        let bottomView = UIView()
        bottomView.backgroundColor = UIColor.ud.bgBodyOverlay
        return bottomView
    }()

    public init(contentTitle: String,
                viewModel: FlagMessageDetailContentViewModel,
                itemsGenerator: RightBarButtonItemsGenerator? = nil) {
        self.contentTitle = contentTitle
        self.viewModel = viewModel
        self.itemsGenerator = itemsGenerator
        super.init(nibName: nil, bundle: nil)
        self.viewModel.context.pageContainer.pageInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.viewModel.context.pageContainer.pageDeinit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewDidAppeared {
            resizeVMIfNeeded(navigationController?.view.bounds.size ?? view.bounds.size)
        }
        self.viewModel.context.pageContainer.pageWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppeared = true
        self.viewModel.context.pageContainer.pageDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.context.pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.context.pageContainer.pageDidDisappear()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        self.title = self.contentTitle
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.label.text = self.viewModel.reason
        self.view.addSubview(self.bottomView)
        self.bottomView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(96)
        }
        self.bottomView.addSubview(self.label)
        self.label.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(62)
        }

        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        self.viewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )

        self.driveViewModel()
        self.viewModel.setupData()
        self.viewModel.getURLPreviews()
        if let itemsGenerator = itemsGenerator {
            self.navigationItem.rightBarButtonItems = itemsGenerator.rightBarButtonItems()
        }
        self.viewModel.context.pageContainer.pageViewDidLoad()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resizeVMIfNeeded(size)
    }

    private func resizeVMIfNeeded(_ size: CGSize) {
        if size != viewModel.hostUIConfig.size {
            viewModel.hostUIConfig.size = size
            viewModel.onResize()
        }
    }

    private func driveViewModel() {
        self.viewModel.tableRefreshDriver.drive(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        self.viewModel.enableUIOutputDriver.filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            }).disposed(by: self.disposeBag)
    }

    @objc
    public func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
    }

    private func triggerVisibleCellsDisplay() {
        for cell in self.tableView.visibleCells {
            if let indexPath = self.tableView.indexPath(for: cell) {
                self.willDisplay(cell: cell, indexPath: indexPath)
            }
        }
    }

    private func willDisplay(cell: UITableViewCell, indexPath: IndexPath) {
        let cellVM = viewModel.uiDataSource[indexPath.row]
        // 在屏幕内的才触发vm的willDisplay
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            cellVM.willDisplay()
        }
    }

    private func didEndDisplay(cell: UITableViewCell, indexPath: IndexPath) {
        let cellVM = viewModel.uiDataSource[indexPath.row]
        // 在屏幕内的才触发vm的didEndDisplay
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            cellVM.didEndDisplay()
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellVM = self.viewModel.uiDataSource[indexPath.row]
        var cellId = ""
        if indexPath.row < self.viewModel.messages.count {
            cellId = self.viewModel.messages[indexPath.row].id
        }
        return cellVM.dequeueReusableCell(tableView, cellId: cellId)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.willDisplay(cell: cell, indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.didEndDisplay(cell: cell, indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let cellVM = self.viewModel.uiDataSource[indexPath.row]
        cellVM.didSelect()
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.uiDataSource[indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.uiDataSource[indexPath.row].renderer.size().height
    }
}

extension FlagMessageDetailViewControlller: FlagMsgPageAPI {
    func reloadRows(current: String, others: [String]) {
        self.tableView.reloadData()
    }
}

extension FlagMessageDetailViewControlller: FlagMessageDetailTableViewDataSourceDelegate {
    var uiDataSource: [FlagMessageDetailCellViewModel] {
        return self.viewModel.uiDataSource
    }
}
