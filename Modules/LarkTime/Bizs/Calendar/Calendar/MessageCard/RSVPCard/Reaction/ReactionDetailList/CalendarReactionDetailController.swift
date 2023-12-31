//
//  CalendarReactionDetailController.swift
//  Calendar
//
//  Created by pluto on 2023/5/19.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import LarkUIKit
import LarkPageController
import UniverseDesignColor
import LarkContainer

final class ReactionDetailController: PageViewController {
    private let userResolver: UserResolver

    private var viewModel: ReactionDetailViewModel
    private let headerMaxHeightRatio: CGFloat = 0.32
    
    init(viewModel: ReactionDetailViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.viewModel.controller = self
        self.pageBackgroundColor = UIColor.ud.bgBody
        self.startIndex = viewModel.startIndex
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let height = headerMaxHeightRatio * size.height + ReactionDetailHeaderView.defaultHeight
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.headerMaxHeight = height
        }
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
        // 获取Controller
        let tableController = controller.dequeueReusableConrtoller(
            withReuseIdentifier: NSStringFromClass(ReactionDetailTableController.self)
        )

        if let detailTableController = tableController as? ReactionDetailTableController {
            // 重设detailTableController的数据
            detailTableController.userResolver = userResolver
            viewModel.configDetailTableController(detailTableController, at: index)
        }
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
            let count = viewModel.reactionTableDataSource[index].count
            reactionCell.set(reactionKey: reaction, count: count)
            reactionCell.contentSelected = { [weak self] in
                if let select = control.onSelected {
                    control.select(itemAt: index)
                    select(index)
                }
            }
        }
        
        return cell
    }
}
