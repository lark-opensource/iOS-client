//
//  SheetToolkitPageView.swift
//  SpaceKit
//
//  Created by Webster on 2019/11/11.
//

import UIKit

class SheetToolkitPageView: UIScrollView {
    override var contentOffset: CGPoint {
        didSet {
            if contentOffset.y != oldValue.y {
                if privateAgent.syncScrollContext.innerOffset.y > 0 {
                    contentOffset.y = privateAgent.syncScrollContext.maxOffsetY
                }
                privateAgent.syncScrollContext.outerOffset = contentOffset
            }
        }
    }

    override var frame: CGRect {
        didSet {
            if !frame.size.equalTo(oldValue.size) {
                customLayoutSubviews()
            }
        }
    }

    override var bounds: CGRect {
        didSet {
            if !bounds.size.equalTo(oldValue.size) {
                customLayoutSubviews()
            }
        }
    }

    override var contentInset: UIEdgeInsets {
        didSet {
            customLayoutSubviews()
        }
    }

    var headerView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let headerView = headerView {
                addSubview(headerView)
            }
            customLayoutSubviews()
        }
    }

    var tabBarView: (UIView & SheetToolkitPageViewDelegate)? {
        didSet {
            oldValue?.removeFromSuperview()
            if let tabBarView = tabBarView {
                addSubview(tabBarView)
            }
            customLayoutSubviews()
            privateAgent.delegate = tabBarView
        }
    }

    func jumpToItem(index: Int, animated: Bool) {
        let count = self.collectionView.numberOfItems(inSection: 0)
        guard 0..<count ~= index else { return }
        self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                         at: UICollectionView.ScrollPosition.centeredHorizontally,
                                         animated: animated)
    }

    var privateAgent: SheetToolkitPageViewPrivateAgent = SheetToolkitPageViewPrivateAgent()
    private let flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.headerReferenceSize = CGSize.zero
        flowLayout.footerReferenceSize = CGSize.zero
        flowLayout.sectionInset = UIEdgeInsets.zero
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        return flowLayout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.dataSource = privateAgent
        collectionView.delegate = privateAgent
        collectionView.bounces = false
        collectionView.bouncesZoom = false
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(SheetToolkitPageItemCell.self, forCellWithReuseIdentifier: "SheetToolkitPageItemCell")
        addSubview(collectionView)
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        defaultConfig()
    }

    func setVCDelegate(delegate: SheetToolkitPageViewControllerDelegate?) {
        privateAgent.vcDelegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        defaultConfig()
    }

    func reloadCollectionView() {
        self.customLayoutSubviews()
        self.collectionView.reloadData()
        self.collectionView.layoutSubviews()
        self.customLayoutSubviews()
    }

    private func defaultConfig() {
        contentInsetAdjustmentBehavior = .never
        bounces = false
        bouncesZoom = false
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }

    private func customLayoutSubviews() {      
        var offsetY: CGFloat = 0
        if let headerView = headerView {
            headerView.frame = CGRect(x: 0, y: offsetY, width: bounds.width, height: headerView.frame.height)
            offsetY += headerView.frame.height
            privateAgent.syncScrollContext.maxOffsetY = headerView.frame.height - contentInset.top
        }
        if let tabBarView = tabBarView {
            tabBarView.frame = CGRect(x: 0, y: offsetY, width: bounds.width, height: tabBarView.frame.height)
            offsetY += tabBarView.frame.height
        }
        let tabBarViewHeight: CGFloat = tabBarView?.frame.height ?? 0
        collectionView.frame = CGRect(x: 0, y: offsetY, width: bounds.width, height: bounds.height - tabBarViewHeight - contentInset.top)
        flowLayout.itemSize = collectionView.bounds.size
        collectionView.reloadData()
        contentSize = CGSize(width: bounds.width, height: collectionView.frame.maxY)
        contentOffset.y = -contentInset.top
    }
}

/// 隐藏部分实现
///
/// 此处UICollectionView的协议不采用扩展写法，否则会暴露在头文件中
class SheetToolkitPageViewPrivateAgent: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {

    typealias ScrollViewScrollBlock = (UIScrollView) -> Void

    var scrollViewDidScrollBlock: ScrollViewScrollBlock?
    var scrollViewWillBeginDraggingBlock: ScrollViewScrollBlock?
    var scrollViewDidEndDeceleratingBlock: ScrollViewScrollBlock?

    weak var delegate: SheetToolkitPageViewDelegate?
    weak var vcDelegate: SheetToolkitPageViewControllerDelegate?
    var syncScrollContext: SyncScrollContext = SyncScrollContext()

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = delegate?.numberOfItems() ?? 0
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SheetToolkitPageItemCell", for: indexPath)
        if let tabCell = cell as? SheetToolkitPageItemCell,
            let parent = vcDelegate?.parentViewController(),
            let child = vcDelegate?.childViewController(atIndex: indexPath.item) {
            tabCell.show(child, parent: parent)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let tabCell = cell as? SheetToolkitPageItemCell,
            let parent = vcDelegate?.parentViewController(),
            let child = vcDelegate?.childViewController(atIndex: indexPath.item),
            child.view.superview == nil {
            tabCell.show(child, parent: parent)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.vcScrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.vcScrollViewDidEndScrollAnimation(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.vcScrollViewDidEndDecelerating(scrollView)
    }

}


class SheetToolkitPageItemCell: UICollectionViewCell {

    weak var showingViewController: UIViewController?

    func show(_ child: UIViewController, parent: UIViewController) {
        showingViewController?.removeFromParent()
        showingViewController?.willMove(toParent: nil)
        showingViewController?.view.snp.removeConstraints()
        showingViewController?.view.removeFromSuperview()
        parent.addChild(child)
        child.view.frame = bounds
        contentView.addSubview(child.view)
        child.didMove(toParent: parent)
        child.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        showingViewController = child
    }
}
