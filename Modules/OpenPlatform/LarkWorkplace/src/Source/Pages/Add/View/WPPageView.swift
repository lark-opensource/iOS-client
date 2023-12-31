//
//  WPPageView.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/6/21.
//

import LarkUIKit

protocol WPPageViewDatasource: AnyObject {
    /// return total pages
    func numberOfPagesInPageView(pageView: WPPageView) -> Int
    /// return sepcify pageview
    func pageview(pageView: WPPageView, pageIndex: Int) -> UIView
    /// refresh
    func dataReload(pageView: WPPageView, pageIndex: Int, content: UIView)
}

protocol WPPageViewDelegate: AnyObject {
    /// page scroll to index
    func pageviewDidScrollTo(pageView: WPPageView, pageIndex: UInt)
}

/// 横向滚动的page scroll 容器；展示分类页面的pageView，每一页是个列表视图(collectionView)
final class WPPageView: UIView,
                        UICollectionViewDelegate,
                        UICollectionViewDataSource,
                        UICollectionViewDelegateFlowLayout {

    static let cellIdentifier = "cellIdentifier"
    /// 列表的tag
    static let cellContentTag: Int = 1_001
    /// delegate
    weak var delegate: WPPageViewDelegate?
    /// datasource
    weak var datasource: WPPageViewDatasource?

    private lazy var pageLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionInset = .zero
        collectionViewLayout.scrollDirection = .horizontal
        return collectionViewLayout
    }()
    /// 横向滚动的pageView（collectionView实现），每一页是一个cell，cell里面是一个列表视图
    private lazy var pageCollectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: pageLayout
        )
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(
            UICollectionViewCell.classForCoder(),
            forCellWithReuseIdentifier: WPPageView.cellIdentifier
        )
        return collectionView
    }()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(pageCollectionView)
        pageCollectionView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        setNeedsUpdateConstraints()
    }

    func reloadData() {
        pageCollectionView.reloadData()
    }

    func scrollToPage(pageIndex: Int) {
        pageCollectionView.scrollToItem(
            at: IndexPath(row: pageIndex, section: 0),
            at: .centeredHorizontally,
            animated: false
        )
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return datasource?.numberOfPagesInPageView(pageView: self) ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WPPageView.cellIdentifier,
            for: indexPath
        )
        if let contentView = cell.contentView.viewWithTag(WPPageView.cellContentTag) {
            /// 如果已经存在那么直接复用，reload数据就好了
            if Display.pad {
                for i in 0...indexPath.row {
                    datasource?.dataReload(pageView: self, pageIndex: i, content: contentView)
                }
            } else {
                datasource?.dataReload(pageView: self, pageIndex: indexPath.row, content: contentView)
            }
        } else {
            if let pageContent = datasource?.pageview(pageView: self, pageIndex: indexPath.row) {
                pageContent.tag = WPPageView.cellContentTag
                cell.contentView.addSubview(pageContent)
                pageContent.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
        }
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = round(pageCollectionView.contentOffset.x / self.bdp_width)
        delegate?.pageviewDidScrollTo(pageView: self, pageIndex: UInt(pageIndex))
    }

    override func updateConstraints() {
        super.updateConstraints()
    }

    /// 刷新UICollectionViewFlowLayout
    func refreshPageViewLayout(selectedIndex: Int) {
        self.pageLayout.invalidateLayout()
        delegate?.pageviewDidScrollTo(pageView: self, pageIndex: UInt(selectedIndex))
    }

    /// 设置每个item大小
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return collectionView.bounds.size
    }
}
