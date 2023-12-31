//
//  RedPacketCoverDetailController.swift
//
//  Created by JackZhao on 2021/10/29.
//  Copyright © 2021 JACK. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import UniverseDesignIcon
import LarkMessengerInterface
import CoreGraphics

// a controller to display redpacket detail
final class RedPacketCoverDetailController: BaseUIViewController,
                                      UICollectionViewDelegateWrapper,
                                      UICollectionViewDataSource, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    private let viewModel: RedPacketCoverDetailViewModel

    // layout variable
    private lazy var viewSize: CGSize = view.bounds.size {
        didSet {
            if oldValue != viewSize {
                itemSize = caculateItemSize(viewSize)
                self.collectionView.setInlineScrollViewWidth(itemSize.width + minimumLineSpacing)
                (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset = collectionViewSectionInset
                (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = itemSize
                self.collectionView.snp.updateConstraints { make in
                    make.height.equalTo(itemSize.height)
                }
                self.collectionView.reloadData()
            }
        }
    }
    // the width of edge cell displayed on the screen
    var edgeCellVisibleWidth: CGFloat {
        (viewSize.width - itemSize.width - 2 * minimumLineSpacing) / 2
    }
    var collectionViewSectionInset: UIEdgeInsets {
        UIEdgeInsets(top: 0, left: edgeCellVisibleWidth + minimumLineSpacing, bottom: 0, right: edgeCellVisibleWidth + minimumLineSpacing)
    }
    // collection cell size
    lazy var itemSize: CGSize = {
        caculateItemSize(viewSize)
    }()

    // layout constant
    let maxItemWidth: CGFloat = 320
    // the value of height divided by width
    let aspectRatio: CGFloat = 1.65
    let minimumLineSpacing: CGFloat = 20
    let defaultCutCellWidth: CGFloat = 20
    let collectionTopMargin: CGFloat = 118
    let confirmButtonMinimumTopMargin: CGFloat = 20
    let confrimButtonHeight: CGFloat = 40
    let confrimBottomMargin: CGFloat = 42

    // redpacket cover list
    private lazy var collectionView: RedPacketCoverDetailCollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = minimumLineSpacing
        flowLayout.itemSize = itemSize
        flowLayout.sectionInset = collectionViewSectionInset

        let collectionView = RedPacketCoverDetailCollectionView(frame: .zero,
                                                                scrollViewWidth: itemSize.width + minimumLineSpacing,
                                                                collectionViewLayout: flowLayout)
        collectionView.wrapperDelegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.bounces = true
        collectionView.layer.masksToBounds = true
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(RedPacketCoverDetailCell.self, forCellWithReuseIdentifier: NSStringFromClass(RedPacketCoverDetailCell.self))
        return collectionView
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton()
        let icon = UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        button.setImage(icon, for: .normal)
        button.setImage(icon, for: .selected)
        return button
    }()

    lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.titleLabel?.textColor = UIColor.ud.Y200
        button.layer.cornerRadius = 6
        button.setTitle(BundleI18n.LarkFinance.Lark_RedPacket_Button_Use, for: .normal)
        button.backgroundColor = UIColor.ud.colorfulRed
        return button
    }()

    init(viewModel: RedPacketCoverDetailViewModel,
         userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.9)

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(collectionTopMargin)
            make.left.right.equalToSuperview()
            make.height.equalTo(itemSize.height)
        }
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(54)
            make.width.height.equalTo(44)
            make.left.equalTo(10)
        }
        closeButton.addTarget(self, action: #selector(closeButtonOnTapped), for: .touchUpInside)

        view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(collectionView.snp.bottom).offset(confirmButtonMinimumTopMargin)
            make.left.equalTo(16).priority(.low)
            make.right.equalTo(-16).priority(.high)
            make.centerX.equalToSuperview().priority(.required)
            make.width.lessThanOrEqualTo(400).priority(.required)
            make.height.equalTo(confrimButtonHeight)
            make.bottom.equalToSuperview().offset(-confrimBottomMargin)
        }
        confirmButton.addTarget(self, action: #selector(confirmButtonOnTapped), for: .touchUpInside)
        self.view.layoutIfNeeded()
        // In order to make the collectionView scroll to a specific cell, set the scrollView offset
        self.collectionView.setInlineScrollViewContentOffset(CGPoint(x: viewModel.tapIndex * Int(itemSize.width + minimumLineSpacing), y: 0))

        // track
        // get tapCover from datas
        let tapCover = viewModel.datas.first(where: { $0.cover.id == viewModel.tapCoverId })?.cover
        // the cover without id have a recommended themeType value
        let themeType = tapCover?.hasID == true ? (viewModel.coverIdToThemeTypeMap["\(viewModel.tapCoverId)"] ?? "") : "recommend"
        FinanceTracker.imHongbaoThemeViewTrack(coverId: "\(viewModel.tapCoverId)", themeType: themeType)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard Display.pad else { return }
        self.viewSize = view.bounds.size
        // 兼容ipad, 取到正确的view宽度需要重新设置下偏移, 否则滚不到合适的位置
        self.collectionView.setInlineScrollViewContentOffset(CGPoint(x: viewModel.tapIndex * Int(itemSize.width + minimumLineSpacing), y: 0))
    }

    private func caculateItemSize(_ viewSize: CGSize) -> CGSize {
        // 最大的卡片高度
        let maxItemHeight = viewSize.height - collectionTopMargin - confirmButtonMinimumTopMargin - confrimButtonHeight - confrimBottomMargin
        let size: CGSize
        let width = viewSize.width - 2 * minimumLineSpacing - 2 * defaultCutCellWidth
        if width < maxItemWidth {
            if width * aspectRatio + 36 < maxItemHeight {
                size = CGSize(width: width, height: width * aspectRatio + 36)
            } else {
                size = CGSize(width: (maxItemHeight - 36) / aspectRatio, height: maxItemHeight)
            }
        } else {
            if maxItemWidth * aspectRatio + 36 < maxItemHeight {
                size = CGSize(width: maxItemWidth, height: maxItemWidth * aspectRatio + 36)
            } else {
                size = CGSize(width: (maxItemHeight - 36) / aspectRatio, height: maxItemHeight)
            }
        }
        return size
    }

    // MARK: delegate impl
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let width: CGFloat = itemSize.width + minimumLineSpacing
        self.collectionView.setInlineScrollViewContentSize(CGSize(width: Int(width) * viewModel.datas.count, height: 0))
        return viewModel.datas.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < viewModel.datas.count else {
            assertionFailure("dataSource out of range")
            return UICollectionViewCell()
        }
        let cellVM = viewModel.datas[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellVM.reuseIdentify, for: indexPath) as? RedPacketCoverDetailCell else { return UICollectionViewCell() }
        cell.model = cellVM

        // adjust all visible cell alpha while reusing
        let cellFrame = collectionView.convert(cell.frame, to: self.view)
        let cellVisibleWidth: CGFloat
        if cellFrame.maxX < cellFrame.width {
            cellVisibleWidth = cellFrame.maxX
        } else if cellFrame.maxX < collectionView.frame.width {
            cellVisibleWidth = cellFrame.width
        } else {
            cellVisibleWidth = collectionView.frame.width - cellFrame.origin.x
        }
        // minium alpha value is 0.5
        cell.contentView.alpha = max(0.5, cellVisibleWidth / cellFrame.width)

        return cell
    }

    // MARK: event
    @objc
    func closeButtonOnTapped() {
        self.dismiss(animated: true)
    }

    @objc
    func confirmButtonOnTapped() {
        let selectedRow = lround(self.collectionView.contentOffset.x / (itemSize.width + minimumLineSpacing))
        guard Int(selectedRow) < viewModel.datas.count else { return }
        let cellVM = viewModel.datas[Int(selectedRow)]
        // send notification to inform of changes
        viewModel.pushCenter.post(PushRedPacketCoverChange(cover: cellVM.cover))
        // the cover without id have a recommended themeType value
        let themeType = cellVM.cover.hasID ? (viewModel.coverIdToThemeTypeMap["\(cellVM.cover.id)"] ?? "") : "recommend"
        FinanceTracker.imHongbaoThemeClickTrack(click: "confirm",
                                                target: "im_hongbao_send_view",
                                                coverId: String(cellVM.cover.id),
                                                themeType: themeType)
        self.dismiss(animated: true) { [weak self] in
            self?.viewModel.confirmHandler?()
        }
    }
}

final class RedPacketCoverDetailViewModel {
    // the index was selected by user
    let tapCoverId: Int64
    let datas: [RedPacketCoverDetailCellModel]
    var tapIndex: Int {
        datas.firstIndex(where: { $0.cover.id == tapCoverId }) ?? 0
    }
    var confirmHandler: (() -> Void)?
    let coverIdToThemeTypeMap: [String: String]
    let pushCenter: PushNotificationCenter

    init(tapCoverId: Int64,
         confirmHandler: (() -> Void)? = nil,
         pushCenter: PushNotificationCenter,
         coverIdToThemeTypeMap: [String: String] = [:],
         datas: [RedPacketCoverDetailCellModel] = []) {
        self.tapCoverId = tapCoverId
        self.confirmHandler = confirmHandler
        self.coverIdToThemeTypeMap = coverIdToThemeTypeMap
        self.pushCenter = pushCenter
        self.datas = datas
    }
}
