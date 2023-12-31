//
//  ExternalGroupAddMemberContainerViewController.swift
//  LarkContact
//
//  Created by 姜凯文 on 2020/4/23.
//

import Foundation
import UIKit
import LarkUIKit
import LarkSegmentedView
import LKCommonsLogging
import LarkKeyboardKit

// 分享方式类型
enum AddMemberType: String {
    case contact
    case link
    case QRcode
}

final class ExternalGroupAddMemberContainerViewController: BaseUIViewController, JXSegmentedListContainerViewDataSource, JXSegmentedViewDelegate {
    typealias ExternalGroupItemSelectBlock = (_ addMemberTypes: AddMemberType) -> Void
    private let subViewControllers: [JXSegmentedListContainerViewListDelegate]

    private let segmentedDataSource = JXSegmentedTitleDataSource()
    private let segmentedView = JXSegmentedView()
    private let addMemberTypes: [AddMemberType]

    private lazy var listContainerView: JXSegmentedListContainerView = {
        return JXSegmentedListContainerView(dataSource: self)
    }()
    private let navTitleView: UIView?

    public var externalGroupItemSelectBlock: ExternalGroupItemSelectBlock?

    init(subViewControllers: [JXSegmentedListContainerViewListDelegate],
         addMemberTypes: [AddMemberType],
         navTitleView: UIView? = nil) {
        self.subViewControllers = subViewControllers
        self.addMemberTypes = addMemberTypes
        self.navTitleView = navTitleView
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

        self.title = BundleI18n.LarkContact.Lark_Groups_GroupAddMemberTitle
        self.view.backgroundColor = UIColor.ud.bgBody
        if let navTitleView = self.navTitleView {
            self.navigationItem.titleView = navTitleView
        }

        segmentedDataSource.isTitleColorGradientEnabled = false
        segmentedDataSource.titles = addMemberTypes.map { title(with: $0) }
        segmentedDataSource.titleNormalFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        segmentedDataSource.titleNormalColor = UIColor.ud.N900
        segmentedDataSource.titleSelectedColor = UIColor.ud.primaryContentDefault
        segmentedDataSource.itemContentWidth = itemWidth
        // 去除item之间的间距
        segmentedDataSource.itemWidthIncrement = 0
        segmentedDataSource.itemSpacing = 0

        segmentedView.dataSource = segmentedDataSource
        segmentedView.delegate = self

        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorColor = UIColor.ud.primaryContentDefault

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
        return addMemberTypes.count
    }

    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        return subViewControllers[index]
    }

    func segmentedView(_ segmentedView: LarkSegmentedView.JXSegmentedView, didSelectedItemAt index: Int) {
        if self.externalGroupItemSelectBlock != nil {
            self.externalGroupItemSelectBlock?(self.addMemberTypes[index])
        }
    }

    // MARK: - private
    private func title(with type: AddMemberType) -> String {
        switch type {
        case .contact:
            return BundleI18n.LarkContact.Lark_Legacy_AddMembers
        case .link:
            return BundleI18n.LarkContact.Lark_Chat_ShareLink
        case .QRcode:
            return BundleI18n.LarkContact.Lark_Chat_ShareQRCode
        }
    }
}
