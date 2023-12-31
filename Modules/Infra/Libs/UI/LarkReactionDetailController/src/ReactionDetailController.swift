//
//  ReactionDetailController.swift
//  Action
//
//  Created by kongkaikai on 2018/12/11.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import LarkUIKit
import LarkPageController
import UniverseDesignColor

final class ReactionDetailController: PageViewController {
    private var disposeBag = DisposeBag()
    private var viewModel: ReactionDetailViewModel
    private var loadingView = LoadingPlaceholderView()
    private lazy var loadingFail: LoadFaildRetryView = {
        let view = LoadFaildRetryView()
        view.isHidden = true
        emptyCoverView.addSubview(view)
        view.snp.makeConstraints({ (maker) in
            maker.edges.equalToSuperview()
        })
        view.retryAction = { [weak self] in
            self?.tryToReloadData()
        }
        view.accessibilityIdentifier = "reaction.detail.failed.retry"
        return view
    }()
    private let headerMaxHeightRatio: CGFloat = 0.32

    private var viewDidAppeared: Bool = false

    private var currentIndex: Int = 0

    init(viewModel: ReactionDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.controller = self
        self.pageBackgroundColor = UIColor.ud.bgBody

        viewModel.reloadData.drive(onNext: { [weak self] startIndex in
            guard let `self` = self else { return }
            self.reloadData(false)
            if let index = startIndex {
                self.startIndex = index
                if self.viewDidAppeared {
                    self.switchPage(to: index)
                }
            }
            self.setCoverViewStatus()
        }).disposed(by: disposeBag)

        viewModel.startLoadMessage()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewDidAppeared = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self

        // 注册Table重用
        self.register(
            ReactionDetailTableController.self,
            forControllerWithReuseIdentifier: NSStringFromClass(ReactionDetailTableController.self)
        )

        customInitHeader()
        customInitSegmentControl()
        customInitLoading()
    }

    private func customInitHeader() {
        let headerView = ReactionDetailHeaderView()

        headerView.onTapClose = { [weak self] _ in
            self?.playDisApperAnimation(autoDismiss: true, completion: nil)
        }
        headerView.onTap = headerView.onTapClose

        self.headerMinHeight = ReactionDetailHeaderView.defaultHeight
        self.headerMaxHeight = headerMaxHeightRatio * view.bounds.height + ReactionDetailHeaderView.defaultHeight

        self.headerView = headerView

        headerView.accessibilityIdentifier = "reaction.detail.header"
    }

    private func customInitSegmentControl() {
        let segmentControl = PageSegmentControl()
        let segmentHeight: CGFloat = 50
        let segmentItemHeight: CGFloat = 28
        let itemDefaultMinHeight: CGFloat = 50
        let itemTopPaddiing: CGFloat = 6

        segmentControl.backgroundColor = UIColor.ud.bgBody

        self.segmentHeight = segmentHeight
        self.segmentControl = segmentControl

        segmentControl.register(
            ReactionPageSegmentCell.self,
            forCellWithReuseIdentifier: NSStringFromClass(ReactionPageSegmentCell.self)
        )
        segmentControl.dataSource = self

        let topOffset = itemTopPaddiing - (itemDefaultMinHeight - segmentItemHeight) / 2
        segmentControl.itemsView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(topOffset)
            maker.height.equalTo(itemDefaultMinHeight)
            maker.left.right.equalToSuperview()
        }
        segmentControl.itemsView.backgroundColor = UIColor.ud.bgBody
        segmentControl.accessibilityIdentifier = "reaction.detail.segmentControl"
    }

    private func customInitLoading() {
        emptyCoverView.addSubview(loadingView)
        loadingView.accessibilityIdentifier = "reaction.detail.loading"

        loadingView.snp.makeConstraints({ (maker) in
            maker.edges.equalToSuperview()
        })

        if self.viewModel.reactions.isEmpty {
            emptyCoverView.isHidden = false
            loadingView.animationView.play()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let height = headerMaxHeightRatio * size.height + ReactionDetailHeaderView.defaultHeight
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.headerMaxHeight = height
        }
    }

    deinit {
        loadingView.animationView.stop()
    }
}

// MARK: - PageViewControllerDataSource
extension ReactionDetailController: PageViewControllerDataSource {
    public func numberOfPage(in segmentController: PageViewController) -> Int {
        return viewModel.reactions.count
    }

    public func segmentController(
        _ controller: PageViewController,
        controllerAt index: Int
    ) -> PageViewController.InnerController? {
        if let pre = viewModel.reaction(at: currentIndex), let cur = viewModel.reaction(at: index) {
            self.viewModel.dependency.reactionDetailClickTab(index: index, preReaction: pre, currentReaction: cur)
        }
        // 获取Controller
        let tableController = controller.dequeueReusableConrtoller(
            withReuseIdentifier: NSStringFromClass(ReactionDetailTableController.self)
        )

        if let detailTableController = tableController as? ReactionDetailTableController {
            // 重设detailTableController的数据
            viewModel.configDetailTableController(detailTableController, at: index)
        }
        tableController.view.accessibilityIdentifier = "reaction.detail.page.\(index)"
        currentIndex = index
        return tableController
    }
}

// MARK: - SegmentControlDataSource
extension ReactionDetailController: SegmentControlDataSource {
    public func numberOfPage(in control: PageSegmentControl) -> Int {
        return viewModel.reactions.count
    }

    public func segmentControl(_ control: PageSegmentControl, cellAt index: Int) -> PageSegmentCell {
        let cell = control.dequeueReusableCell(
            withReuseIdentifier: NSStringFromClass(ReactionPageSegmentCell.self),
            for: index
        )

        if let reactionCell = cell as? ReactionPageSegmentCell,
            let reaction = viewModel.reaction(at: index) {
            reactionCell.reactionImageFetcher = {
                [weak self] (reaction: String, callback: @escaping (UIImage) -> Void) in
                self?.viewModel.dependency.reactionDetailImage(reaction, callback: callback)
            }
            let count = reaction.totalCount ?? reaction.chatterIds.count
            reactionCell.set(reactionKey: reaction.type, count: count)
        }
        cell.accessibilityIdentifier = "reaction.detail.segment.\(index)"
        return cell
    }
}

// MARK: error & empty()
extension ReactionDetailController {
    fileprivate func setCoverViewStatus() {

        guard viewModel.error != nil || viewModel.reactions.isEmpty else {
            loadingView.animationView.stop()
            emptyCoverView.isHidden = true
            return
        }

        emptyCoverView.isHidden = false
        if viewModel.error != nil {
            loadingView.animationView.stop()
            loadingFail.isHidden = false
            loadingView.isHidden = true
        } else {
            loadingFail.isHidden = true
            loadingView.isHidden = false
            if !loadingView.animationView.isAnimationPlaying {
                loadingView.animationView.play()
            }
        }
    }

    fileprivate func tryToReloadData() {
        viewModel.startLoadMessage()
        loadingFail.isHidden = true
        loadingView.isHidden = false
        loadingView.animationView.play()
    }
}
