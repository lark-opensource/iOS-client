//
//  AppCenterHomeCategroyViewController.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/10/17.
//

import LarkUIKit
import SnapKit

protocol AppCenterHomeCategroyProtocol: AnyObject {

    /// 点击了分类cell
    /// - Parameter indexPath: 位置
    func didSelectAppCenterHomeCategroyCollectionViewCell(
        categoryVC: AppCenterHomeCategroyViewController,
        at indexPath: IndexPath,
        for group: Int
    )

    /// 点击了空白区域 关闭分类页
    func justCloseAppCenterHomeCategroyViewController(categoryVC: AppCenterHomeCategroyViewController, for group: Int)
}

/// 分类筛选视图间距
let popCategoryPageViewInset: CGFloat = 16.0
let normalCategoryPageViewInset: CGFloat = 20.0
/// 分类筛选视图气泡模式下的item宽度
let categoryItemWidthForPop: CGFloat = 128.0
/// 分类筛选视图气泡模式下的item宽度
let categoryItemHeightForPop: CGFloat = 40.0
/// 分类筛选视图气泡模式下的header高度
let categoryHeaderHeightForPop: CGFloat = 48.0

final class AppCenterHomeCategroyViewController: BaseUIViewController, UICollectionViewDelegate,
                                           UICollectionViewDataSource, UIViewControllerTransitioningDelegate {

    weak var delegate: AppCenterHomeCategroyProtocol?
    /// 数据源
    private let nameArray: [String]
    /// 是否是气泡模式
    private let isPopMode: Bool
    /// 显示分类侧边 哪个应该高亮
    private var selectIndex: Int
    /// 从属于哪个Section
    private var forGroup: Int = 0
    /// 是否是新的分类窗口
    var isNewCategory: Bool = false

    private lazy var headerView: CategoryLabelHeaderView = {
        let vi = CategoryLabelHeaderView()
        vi.backgroundColor = UIColor.ud.bgBody
        vi.refresh(isPopupMode: isPopMode, isNewCategory: isNewCategory)
        return vi
    }()

    private lazy var appCenterHomeCategroyCollectionView: AppCenterHomeCategroyCollectionView = {
        let layout = AppCenterHomeCategroyLayout()
        let insetH = isPopMode ? popCategoryPageViewInset : normalCategoryPageViewInset
        layout.sectionInset = UIEdgeInsets(top: 0, left: insetH, bottom: view.safeAreaInsets.bottom, right: insetH)
        let interitemSpace: CGFloat = 0.5
        // swiftlint:disable line_length
        let calculateWidth = floor((getCollectionViewWidth() - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing) / 2.0) - interitemSpace
        // swiftlint:enable line_length
        let width = isPopMode ? categoryItemWidthForPop : calculateWidth
        layout.itemSize = CGSize(width: width, height: categoryItemHeightForPop)
        let collectionView = AppCenterHomeCategroyCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    /// 背景视图
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(closeCategory))
        view.addGestureRecognizer(tapGes)
        return view
    }()

    init(with nameArray: [String], selectIndex: Int, isPopMode: Bool = false, group: Int = 0) {
        self.nameArray = nameArray
        self.selectIndex = selectIndex
        self.isPopMode = isPopMode
        self.forGroup = group
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        // 1. 在 viewDidLoad 中调用 selectItem 时，其 scrollPosition 设置无效
        // 2. 后续如果需要新增滚动到选中 cell 的功能，需要将 selectItem 移动到 viewDidAppear 中，但是 cell 选中会有视觉延迟
        appCenterHomeCategroyCollectionView.selectItem(
            at: IndexPath(item: selectIndex, section: 0),
            animated: false,
            scrollPosition: .top
        )
    }

    @objc
    func closeCategory(animated: Bool = true) {
        delegate?.justCloseAppCenterHomeCategroyViewController(categoryVC: self, for: forGroup)
        dismiss(animated: animated)
    }

    private func setupViews() {
        view.backgroundColor = .clear
        view.addSubview(backgroundView)
        view.addSubview(headerView)
        view.addSubview(appCenterHomeCategroyCollectionView)

        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let headerH = getCollectionViewHeaderSize().height
        let collectionViewWidth = getCollectionViewWidth()
        if isPopMode,
           let arrowDirection = self.popoverPresentationController?.permittedArrowDirections,
           arrowDirection == .right {
            headerView.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(headerH)
            }
            appCenterHomeCategroyCollectionView.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.left.bottom.equalToSuperview()     // 靠左展示
                make.width.equalTo(collectionViewWidth)
            }
        } else {
            headerView.snp.makeConstraints { make in
                make.top.right.equalToSuperview()
                make.left.equalTo(appCenterHomeCategroyCollectionView)
                make.height.equalTo(headerH)
            }
            appCenterHomeCategroyCollectionView.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.bottom.right.equalToSuperview()    // 靠右展示
                make.width.equalTo(collectionViewWidth)
            }
        }
        view.bringSubviewToFront(appCenterHomeCategroyCollectionView)
    }

    /// 获取collectionView的width
    private func getCollectionViewWidth() -> CGFloat {
        if isPopMode {
            // 按设计（zhudandan）要求，固定展示两列item
            return categoryItemWidthForPop * 2 + popCategoryPageViewInset * 3
        } else {
            // 按设计（huanglijuan）要求，以屏幕宽度为375为基准，等比率宽度为 304.0 / 375 对应的宽度
            return view.frame.width * 304.0 / 375.0
        }
    }

    /// 获取sectionHeader的size
    private func getCollectionViewHeaderSize() -> CGSize {
        if isPopMode {
            return CGSize(width: getCollectionViewWidth(), height: categoryHeaderHeightForPop)
        } else {
            return CGSize(width: getCollectionViewWidth(), height: 68 + UIApplication.shared.statusBarFrame.height)
        }
    }

    /// 获取气泡模式下的内容尺寸
    static func getPopSize(itemCount: Int) -> CGSize {
        let width = categoryItemWidthForPop * 2 + popCategoryPageViewInset * 3
        // swiftlint:disable line_length
        let height = categoryHeaderHeightForPop + ceil(CGFloat(itemCount) / 2.0) * (categoryItemHeightForPop + popCategoryPageViewInset)
        // swiftlint:enable line_length
        return CGSize(width: width, height: height)
    }

    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 和业务逻辑(选中分类Cell后, viewController销毁)解耦
        selectIndex = indexPath.item
        delegate?.didSelectAppCenterHomeCategroyCollectionViewCell(categoryVC: self, at: indexPath, for: forGroup)
        dismiss(animated: true)
    }

    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nameArray.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: appCenterHomeCategroyCollectionView.appCenterHomeCategroyCollectionCellID,
            for: indexPath
        )

        guard let appCenterHomeCategroyCollectionViewCell = cell as? AppCenterHomeCategroyCollectionViewCell,
            indexPath.item < nameArray.count else {
                return cell
        }
        appCenterHomeCategroyCollectionViewCell.updateText(with: nameArray[indexPath.item])
        return cell
    }

    // MARK: 转场动画 - UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        let presentAnimation = AppCenterCatagoryPresentAnimation()
        presentAnimation.isPresenting = true
        return presentAnimation
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentAnimation = AppCenterCatagoryPresentAnimation()
        presentAnimation.isPresenting = false
        return presentAnimation
    }
}
