//
//  AppCenterAllAppHeaderView.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/9/29.
//

import LarkUIKit
import LarkInteraction
import UniverseDesignIcon
import UniverseDesignTheme
import BDWebImage

protocol AppCenterAllAppHeaderViewProtocol: AnyObject {

    /// 点击分类筛选按钮
    func didSelectCategoryButton(sender: UIButton)

    /// 点击横向滑动列表的cell
    /// - Parameter indexPath: 位置
    func didSelectHorizontalLabelCell(headerView: AppCenterAllAppHeaderView, at indexPath: IndexPath)
}

/// 应用中心主页全部应用对应的Header
final class AppCenterAllAppHeaderView: UICollectionReusableView {
    weak var delegate: AppCenterAllAppHeaderViewProtocol?
    /// 最终的全部应用对应的分类数据
    private var nameArray: [String] = [String]()
    /// 横向滑动列表需要的selectIndex
    var selectIndexPath: IndexPath = IndexPath(item: 0, section: 0)

    private var hasShadow: Bool = true
    /// 左上角标题
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AllApp
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        return titleLabel
    }()

    /// 分类筛选按钮
    private lazy var categoryButton: UIButton = {
        let categoryButton = UIButton(type: .custom)
        var image = UDIcon.menuOutlined
        image = image.bd_imageByResize(to: CGSize(width: 24, height: 24)) ?? image
        image = image.ud.withTintColor(UIColor.ud.iconN1)
        categoryButton.setImage(image, for: .normal)
        return categoryButton
    }()

    /// 横向滑动列表
    private lazy var catagroyLabelHorizontalCollectionView: CatagroyLabelHorizontalCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: 1, height: 1)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        let collectionView = CatagroyLabelHorizontalCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.clipsToBounds = true
        return collectionView
    }()

    /// 横向滑动列表左侧的蒙层
    private lazy var leftShadow: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    /// 横向滑动列表右侧的蒙层
    private lazy var rightShadow: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    private lazy var spline: UIView = {
        let vi = UIView()
        vi.isUserInteractionEnabled = false
        vi.backgroundColor = UIColor.ud.lineDividerDefault
        return vi
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(titleLabel)
        addSubview(categoryButton)
        addSubview(catagroyLabelHorizontalCollectionView)
        addSubview(leftShadow)
        addSubview(rightShadow)
        addSubview(spline)
        catagroyLabelHorizontalCollectionView.delegate = self
        catagroyLabelHorizontalCollectionView.dataSource = self
        leftShadow.image = Resources.left_shadow.ud.withTintColor(UIColor.ud.bgBody)
        rightShadow.image = Resources.right_shadow.ud.withTintColor(UIColor.ud.bgBody)
        categoryButton.addTarget(
            self,
            action: #selector(didSelectCategoryButton(sender:)),
            for: .touchUpInside
        )
        categoryButton.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (
                        CGSize(width: size.width + highLightIconWidthMargin, height: highLightIconHeightMargin),
                        highLightCorner
                    )
                }
            )
        )
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview()
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(117)
        }
        categoryButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.right.equalToSuperview().inset(16)
            make.centerY.equalTo(catagroyLabelHorizontalCollectionView)
            make.left.equalTo(catagroyLabelHorizontalCollectionView.snp.right).offset(8)
        }
        catagroyLabelHorizontalCollectionView.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        leftShadow.snp.makeConstraints { (make) in
            make.width.equalTo(16)
            make.height.equalTo(catagroyLabelHorizontalCollectionView)
            make.centerY.equalTo(catagroyLabelHorizontalCollectionView)
            make.left.equalTo(catagroyLabelHorizontalCollectionView)
        }
        rightShadow.snp.makeConstraints { (make) in
            make.width.equalTo(16)
            make.height.equalTo(catagroyLabelHorizontalCollectionView)
            make.centerY.equalTo(catagroyLabelHorizontalCollectionView)
            make.right.equalTo(catagroyLabelHorizontalCollectionView)
        }
        spline.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(WPUIConst.BorderW.pt0_5)
        }
    }

    /// 这个 withTintColor 似乎有 Bug，主题切换时候会出现反色，这里先这样特殊处理下
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            switch UDThemeManager.getRealUserInterfaceStyle() {
            case .light:
                leftShadow.image = Resources.left_shadow.ud.withTintColor(UIColor.ud.bgBody.alwaysLight)
                rightShadow.image = Resources.right_shadow.ud.withTintColor(UIColor.ud.bgBody.alwaysLight)
                break
            case .dark:
                leftShadow.image = Resources.left_shadow.ud.withTintColor(UIColor.ud.bgBody.alwaysDark)
                rightShadow.image = Resources.right_shadow.ud.withTintColor(UIColor.ud.bgBody.alwaysDark)
                break
            default:
                break
            }
        }
    }

    /// 获取分类筛选按钮
    func getCategoryButton() -> UIButton {
        return categoryButton
    }

    /// 更新Header
    /// - Parameter nameArray: 分类名数组
    func updateHeaderView(with nameArray: [String]) {
        //  假设apple的表格视图出Bug，numberOfSections突然不等于1，走后备逻辑
        if catagroyLabelHorizontalCollectionView.numberOfSections != 1 {
            self.nameArray = nameArray
            catagroyLabelHorizontalCollectionView.reloadData()
            return
        }
        if nameArray.isEmpty {
            /// 如果数据源为空，就不要走其他逻辑了，赋值+reload就可以
            self.nameArray = nameArray
            catagroyLabelHorizontalCollectionView.reloadSections([0])
            return
        }

        let numOfItems = catagroyLabelHorizontalCollectionView.numberOfItems(inSection: 0)
        /// 如果array相等，cell数量也等于array的count return掉
        if self.nameArray == nameArray,
            numOfItems == nameArray.count {
            //  再加一层判断，如果cell数量不等于0并且selectIndexPath是小于等于cell数量，才可以去选中，避免尝试去select不存在的Item
            if numOfItems != 0, selectIndexPath.count <= numOfItems {
                catagroyLabelHorizontalCollectionView.selectItem(
                    at: selectIndexPath,
                    animated: false,
                    scrollPosition: .centeredHorizontally
                )
            }
            return
        }
        // swiftlint:disable line_length
        catagroyLabelHorizontalCollectionView.performBatchUpdates({[weak self, weak catagroyLabelHorizontalCollectionView] in
        // swiftlint:enable line_length
                guard let `self` = self,
                    let catagroyLabelHorizontalCollectionView = catagroyLabelHorizontalCollectionView else {
                        return
                }
                self.nameArray = nameArray
                catagroyLabelHorizontalCollectionView.reloadSections([0])
            },
            completion: { [weak self, weak catagroyLabelHorizontalCollectionView] (_) in
                guard let `self` = self,
                    let catagroyLabelHorizontalCollectionView = catagroyLabelHorizontalCollectionView else {
                        return
                }
                let numOfItems = catagroyLabelHorizontalCollectionView.numberOfItems(inSection: 0)
                //  再加一层判断，如果cell数量不等于0并且selectIndexPath是小于等于cell数量，才可以去选中，避免尝试去select不存在的Item
                if numOfItems != 0,
                    self.selectIndexPath.count <= numOfItems {
                    catagroyLabelHorizontalCollectionView.selectItem(
                        at: self.selectIndexPath,
                        animated: false,
                        scrollPosition: .centeredHorizontally
                    )
                }
            }
        )
    }

    @objc
    private func didSelectCategoryButton(sender: UIButton) {
        delegate?.didSelectCategoryButton(sender: sender)
    }

    /// 选中指定索引
    func scrollToIndexPath(indexPath: IndexPath) {
        selectIndexPath = indexPath
        UIView.performWithoutAnimation {
            // swiftlint:disable multiple_closures_with_trailing_closure
            catagroyLabelHorizontalCollectionView.performBatchUpdates({
                catagroyLabelHorizontalCollectionView.scrollToItem(
                    at: indexPath,
                    at: .centeredHorizontally,
                    animated: true
                )
            }) { [weak self] (_) in
                self?.catagroyLabelHorizontalCollectionView.selectItem(
                    at: indexPath,
                    animated: false,
                    scrollPosition: .centeredHorizontally
                )
            }
            // swiftlint:enable multiple_closures_with_trailing_closure
        }
    }
}

// MARK: UICollectionViewDelegate
extension AppCenterAllAppHeaderView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /// 点击了某分类，通知首页全部应用section刷新数据源
        selectIndexPath = indexPath
        delegate?.didSelectHorizontalLabelCell(headerView: self, at: indexPath)
    }
}

// MARK: UICollectionViewDataSource
extension AppCenterAllAppHeaderView: UICollectionViewDataSource,
                                     UICollectionViewDelegateFlowLayout,
                                     UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nameArray.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let deFaultCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CatagroyLabelHorizontalCollectionView.cellID,
            for: indexPath
        )
        guard let cell = deFaultCell as? HorizontalLabelCell,
            indexPath.item < nameArray.count else {
                return deFaultCell
        }
        /// 必须有一个分类是select状态
        cell.isSelected = indexPath.item == selectIndexPath.item
        cell.refreshViews(
            text: nameArray[indexPath.item],
            avatarURLStr: nil,
            selectedFont: .systemFont(ofSize: 14, weight: .medium),
            unselectedFont: .systemFont(ofSize: 14),
            cellLeftPadding: 10,
            cellRightPadding: 10
        )
        return cell
    }

    /// cell宽度需要自行计算，毕竟标签的长度不一样嘛
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard indexPath.item < nameArray.count else { return .zero }
        let textfont = UIFont.systemFont(ofSize: 14)
        var size = nameArray[indexPath.item].size(withAttributes: [.font: textfont])
        size.height = max(40, size.height)
        size.width = CGFloat(ceil(Double(size.width + 20)))
        return size
    }
}
