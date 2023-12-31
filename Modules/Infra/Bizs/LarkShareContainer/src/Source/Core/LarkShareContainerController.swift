//
//  LarkShareContainerController.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2020/12/16.
//

import UIKit
import Foundation
import LarkSegmentedView
import LarkKeyboardKit
import LarkUIKit
import RxSwift
import RxCocoa
import LarkSnsShare
import LarkContainer
import LKCommonsLogging
import RoundedHUD
import SnapKit
import UniverseDesignColor

struct ShareMaterial {
    public let title: String
    public let selectedShareTab: ShareTabType
    public let linkCoverter: ((String, ShareTabType) -> Observable<String>)?
    public let contentProvider: (ShareTabType) -> Observable<TabContentMeterial>
    public let tabMaterials: [TabMaterial]
    public init(
        title: String,
        selectedShareTab: ShareTabType,
        linkCoverter: ((String, ShareTabType) -> Observable<String>)? = nil,
        contentProvider: @escaping (ShareTabType) -> Observable<TabContentMeterial>,
        tabMaterials: [TabMaterial]
    ) {
        self.title = title
        self.selectedShareTab = selectedShareTab
        self.linkCoverter = linkCoverter
        self.contentProvider = contentProvider
        self.tabMaterials = tabMaterials
    }
}

final class LarkShareContainerController: BaseUIViewController, JXSegmentedListContainerViewDataSource, JXSegmentedViewDelegate {
    private let lifeCycleObserver: ((LifeCycleEvent, ShareTabType) -> Void)?
    private let material: ShareMaterial
    private let subContainerViews: [JXSegmentedListContainerViewListDelegate]
    private let segmentedDataSource = JXSegmentedTitleDataSource()
    private let segmentedView = JXSegmentedView()
    private var currentTabType: ShareTabType
    private lazy var listContainerView: JXSegmentedListContainerView = {
        return JXSegmentedListContainerView(dataSource: self)
    }()

    init(
        material: ShareMaterial,
        subContainerViews: [JXSegmentedListContainerViewListDelegate],
        lifeCycleObserver: ((LifeCycleEvent, ShareTabType) -> Void)?
    ) {
        self.material = material
        self.subContainerViews = subContainerViews
        self.lifeCycleObserver = lifeCycleObserver
        self.currentTabType = material.selectedShareTab
        super.init(nibName: nil, bundle: nil)
        lifeCycleObserver?(.initial, currentTabType)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutPageSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifeCycleObserver?(.willAppear, currentTabType)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifeCycleObserver?(.didAppear, currentTabType)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifeCycleObserver?(.willDisappear, currentTabType)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifeCycleObserver?(.didDisappear, currentTabType)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let viewWidth = navigationController?.view.bounds.size.width ?? view.bounds.size.width
        let itemWidth = viewWidth / CGFloat(material.tabMaterials.count)
        if segmentedDataSource.itemContentWidth != itemWidth {
            // segment reload 会 remove subviews 丢失 firstResponder 状态
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
        return material.tabMaterials.count
    }

    func listContainerView(
        _ listContainerView: JXSegmentedListContainerView,
        initListAt index: Int
    ) -> JXSegmentedListContainerViewListDelegate {
        if material.tabMaterials[index].type() == .viaChat {
            dependency!.setInputNavigationItem(with: subContainerViews[index], item: navigationItem)
            dependency!.setCloseHandler(with: subContainerViews[index]) { [weak self] in
                guard let `self` = self else { return }
                self.lifeCycleObserver?(.clickClose, self.currentTabType)
            }
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        return subContainerViews[index]
    }

    // MARK: - JXSegmentedViewDelegate
    func segmentedView(_ segmentedView: LarkSegmentedView.JXSegmentedView, didSelectedItemAt index: Int) {
        guard index < material.tabMaterials.count else { return }
        let targetTabType = material.tabMaterials.map { $0.type() }[index]
        lifeCycleObserver?(.switchTab(target: targetTabType), currentTabType)
        currentTabType = targetTabType
    }

    @objc
    override func closeBtnTapped() {
        lifeCycleObserver?(.clickClose, currentTabType)
        dismiss(animated: true, completion: { [weak self] in
            self?.closeCallback?()
        })
    }

    @objc
    override func backItemTapped() {
        lifeCycleObserver?(.clickClose, currentTabType)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Private
private extension LarkShareContainerController {
    func layoutPageSubviews() {
        title = material.title
        view.backgroundColor = UIColor.ud.bgBody
        let viewWidth = navigationController?.view.bounds.size.width ?? view.bounds.size.width
        let itemWidth = viewWidth / CGFloat(subContainerViews.count)

        segmentedDataSource.isTitleColorGradientEnabled = false
        segmentedDataSource.titles = material.tabMaterials.map { $0.title() }
        segmentedDataSource.titleNormalFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        segmentedDataSource.titleNormalColor = UIColor.ud.N900
        segmentedDataSource.titleSelectedColor = UIColor.ud.primaryContentDefault
        segmentedDataSource.itemContentWidth = itemWidth
        segmentedDataSource.titleNumberOfLines = 2

        segmentedDataSource.itemWidthIncrement = 0
        segmentedDataSource.itemSpacing = 0

        segmentedView.dataSource = segmentedDataSource
        segmentedView.delegate = self
        segmentedView.defaultSelectedIndex = material.tabMaterials.firstIndex { $0.type() == material.selectedShareTab } ?? 0

        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorColor = UIColor.ud.primaryContentDefault

        segmentedView.backgroundColor = UIColor.ud.bgBody
        segmentedView.indicators = [indicator]
        segmentedView.isContentScrollViewClickTransitionAnimationEnabled = false

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
}
