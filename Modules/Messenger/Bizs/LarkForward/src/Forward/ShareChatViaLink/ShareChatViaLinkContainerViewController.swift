//
//  ShareChatViaLinkContainerViewController.swift
//  LarkForward
//
//  Created by 姜凯文 on 2020/4/19.
//

import Foundation
import UIKit
import LarkUIKit
import LarkSDKInterface
import RxSwift
import LarkMessengerInterface
import LarkSegmentedView
import LarkKeyboardKit
import LarkFeatureGating

final class ShareChatViaLinkContainerViewController: BaseUIViewController, JXSegmentedListContainerViewDataSource {
    private let subViewControllers: [JXSegmentedListContainerViewListDelegate]
    private let defaultSelected: ShareChatViaLinkType

    private let segmentedDataSource = JXSegmentedTitleDataSource()
    private let segmentedView = JXSegmentedView()
    private let shareChatViaLinkTypes: [ShareChatViaLinkType]
    private let isThreadGroup: Bool

    private lazy var listContainerView: JXSegmentedListContainerView = {
        return JXSegmentedListContainerView(dataSource: self)
    }()

    init(isThreadGroup: Bool,
         subViewControllers: [JXSegmentedListContainerViewListDelegate],
         shareChatViaLinkTypes: [ShareChatViaLinkType],
         defaultSelected: ShareChatViaLinkType) {
        self.isThreadGroup = isThreadGroup
        self.subViewControllers = subViewControllers
        self.shareChatViaLinkTypes = shareChatViaLinkTypes
        self.defaultSelected = defaultSelected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // 三个item实现三等分
        let viewWidth = self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width
        let itemWidth = viewWidth / CGFloat(subViewControllers.count)
        self.title = self.isThreadGroup ? BundleI18n.LarkForward.Lark_Groups_ShareCircle : BundleI18n.LarkForward.Lark_Legacy_ShareGroup
        self.view.backgroundColor = UIColor.ud.commonBackgroundColor
        segmentedDataSource.isTitleColorGradientEnabled = false
        segmentedDataSource.titles = shareChatViaLinkTypes.map { title(with: $0) }
        segmentedDataSource.titleNormalFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        segmentedDataSource.titleNormalColor = UIColor.ud.N900
        segmentedDataSource.titleSelectedColor = UIColor.ud.colorfulBlue
        segmentedDataSource.itemContentWidth = itemWidth
        // 去除item之间的间距
        segmentedDataSource.itemWidthIncrement = 0
        segmentedDataSource.itemSpacing = 0

        segmentedView.dataSource = segmentedDataSource
        segmentedView.defaultSelectedIndex = shareChatViaLinkTypes.firstIndex(of: defaultSelected) ?? 0

        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorColor = UIColor.ud.colorfulBlue

        segmentedView.backgroundColor = UIColor.ud.bgBody
        segmentedView.indicators = [indicator]
        segmentedView.isContentScrollViewClickTransitionAnimationEnabled = false
        // 去除整体内容的左右边距
        segmentedView.contentEdgeInsetLeft = 0
        segmentedView.contentEdgeInsetRight = 0

        view.addSubview(segmentedView)
        segmentedView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(40)
        }

        segmentedView.listContainer = listContainerView
        view.addSubview(listContainerView)
        listContainerView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(segmentedView.snp.bottom)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let viewWidth = self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width
        let itemWidth = viewWidth / CGFloat(subViewControllers.count)
        if segmentedDataSource.itemContentWidth != itemWidth {
            /// segment reload 会 remove subviews 丢失 firstResponder 状态
            DispatchQueue.main.async {
                let first = KeyboardKit.shared.firstResponder
                var needRecover = false
                var next = first?.next
                while next != nil {
                    if next == self {
                        needRecover = true
                        break
                    }
                    next = next?.next
                }

                self.segmentedDataSource.itemContentWidth = itemWidth
                self.segmentedView.reloadData()
                if needRecover {
                    DispatchQueue.main.async {
                        first?.becomeFirstResponder()
                    }
                }
            }
        }
    }

    // MARK: - JXSegmentedListContainerViewDataSource
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int {
        return shareChatViaLinkTypes.count
    }

    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        if index == 0 {
            if let vc = subViewControllers[index] as? NewShareGroupCardViewController {
                vc.inputNavigationItem = self.navigationItem
            }
            if let vc = subViewControllers[index] as? ShareGroupCardForwardComponentViewController {
                vc.inputNavigationItem = self.navigationItem
            }
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        return subViewControllers[index]
    }

    // MARK: - private
    private func title(with type: ShareChatViaLinkType) -> String {
        switch type {
        case .card:
            return self.isThreadGroup ? BundleI18n.LarkForward.Lark_Groups_CircleCard : BundleI18n.LarkForward.Lark_Chat_ShareCard
        case .link:
            return self.isThreadGroup ? BundleI18n.LarkForward.Lark_Groups_CircleLink : BundleI18n.LarkForward.Lark_Chat_ShareLink
        case .QRcode:
            return self.isThreadGroup ? BundleI18n.LarkForward.Lark_Groups_CircleQRCode : BundleI18n.LarkForward.Lark_Chat_ShareQRCode
        }
    }
}
