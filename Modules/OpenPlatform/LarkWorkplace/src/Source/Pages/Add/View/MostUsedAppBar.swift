//
//  MostUsedAppBar.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/6/19.
//

import UIKit
import LarkInteraction
import LKCommonsLogging

/// 常用应用横向icon列表
/// 添加应用页面顶部的显示常用应用的bar
final class MostUsedAppIconCell: UICollectionViewCell {
    static let identifier = "MostUsedAppIconCell"

    /// 是否是展示更多ICON图标的标记位
    var showMoreIcon: Bool = false {
        didSet {
            if showMoreIcon {
                appIcon.hideMask().image = Resources.more_app
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(appIcon)
        appIcon.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 单个常用应用图标
    private lazy var appIcon: WPMaskImageView = {
        let vi = WPMaskImageView()
        vi.clipsToBounds = true
        vi.sqRadius = WPUIConst.AvatarRadius.xs6
        vi.sqBorder = WPUIConst.BorderW.pt1
        return vi
    }()

    func setIconKey(iconKey: String) {
        appIcon.hideMask(false).bt.setLarkImage(with: .avatar(
            key: iconKey,
            entityID: "",
            params: .init(sizeType: .size(avatarSideL))
        ))
    }
}

final class HoriziontalLayout: UICollectionViewFlowLayout {

    static let appIconEdge: CGFloat = 24.0
    static let appIconSize = CGSize(width: appIconEdge, height: appIconEdge)
    /// app icon 中心之间的间距
    static let appCenterInteritemWidth: CGFloat = 28.0
    /// app icon 列表距离左边的边距
    static let appMarginLeft: CGFloat = 8.0
    /// app icon 列表距离右边的边距
    static let appMarginRight: CGFloat = 8.0
    /// when bouds change, then relayout
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    /// calculate all item's layout attributes
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attrArray: [UICollectionViewLayoutAttributes] = []
        if let itemCount = self.collectionView?.numberOfItems(inSection: 0) {
            for i in 0..<itemCount {
                let indexPath = IndexPath(item: i, section: 0)
                if let attr = self.layoutAttributesForItem(at: indexPath) {
                    attrArray.append(attr)
                }
            }
        }
        return attrArray
    }

    /// calculate specify item's layout attributes
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let iconSize = HoriziontalLayout.appIconSize
        let offset = HoriziontalLayout.appMarginLeft
        let interitemWidth = HoriziontalLayout.appCenterInteritemWidth
        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        if let collectionView = self.collectionView {
            attr.center = CGPoint(
                x: offset + CGFloat(indexPath.row) * interitemWidth + iconSize.width / 2.0,
                y: collectionView.bdp_height / 2.0
            )
            attr.size = iconSize
            attr.zIndex = indexPath.row
        }
        return attr
    }
    /// 找到最多展示的icon，包含更多
    func calcuteMaxCanDisplayApps(width: CGFloat, start: Int = 0) -> Int {
        let iconSize = HoriziontalLayout.appIconSize
        let offset = HoriziontalLayout.appMarginLeft
        let interitemWidth = HoriziontalLayout.appCenterInteritemWidth
        for i in start...Int(width) {
            let centerX = offset + CGFloat(i) * interitemWidth + iconSize.width / 2.0
            let right = centerX + iconSize.width / 2.0
            if right > width {
                return i
            }
        }
        return Int(width)
    }
}

final class MostUsedAppHoriziontalList: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    static let logger = Logger.log(MostUsedAppHoriziontalList.self)

    /// 最大展示的app个数
    var maxDisplayLimit: Int = 0
    private lazy var layout: HoriziontalLayout = {
        let horiziontalLayout = HoriziontalLayout()
        horiziontalLayout.itemSize = HoriziontalLayout.appIconSize
        horiziontalLayout.minimumLineSpacing = 0
        horiziontalLayout.minimumInteritemSpacing = 0
        return horiziontalLayout
    }()
    /// 横向的collection view
    private lazy var horiziontalList: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            MostUsedAppIconCell.classForCoder(),
            forCellWithReuseIdentifier: MostUsedAppIconCell.identifier
        )
        collectionView.backgroundColor = UIColor.ud.bgBody
        return collectionView
    }()

    // MARK: UICollectionView DataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageList.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MostUsedAppIconCell.identifier,
            for: indexPath
        ) as? MostUsedAppIconCell else {
            Self.logger.error("collectionView dequeueReusableCell is not MostUsedAppIconCell")
            return UICollectionViewCell()
        }
        cell.showMoreIcon = false
        if indexPath.row >= maxDisplayLimit - 1 {
            cell.showMoreIcon = true
        } else {
            cell.setIconKey(iconKey: imageList[indexPath.row])
        }
        return cell
    }

    var imageList: [String] = [] {
        didSet {
            /// 只有数据不一样的时候才刷新
            if !oldValue.elementsEqual(imageList) {
                horiziontalList.reloadData()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(horiziontalList)
        horiziontalList.snp.remakeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func getElementsLimit() -> Int {
        return layout.calcuteMaxCanDisplayApps(width: horiziontalList.bounds.width)
    }
}

/// 添加应用页面顶部的显示常用应用的bar
final class MostUsedAppBar: UIView {
    /// 点击设置
    var settingClick: (() -> Void)?
    /// app list
    var itemList: [WPCategoryItemViewModel] = [] {
        didSet {
            totalAppsLabel.text = getTitleContent(count: itemList.count)
            totalAppsLabel.sizeToFit()
            appsBar.maxDisplayLimit = appsBar.getElementsLimit()
            appsBar.imageList = Array(
                itemList.map({ (model) -> String in
                    return model.item.iconKey
                }).prefix(appsBar.maxDisplayLimit)
            )
        }
    }
    private func getTitleContent(count: Int) -> String {
        return BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AddedTitle(count)
    }
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
    /// 左边的标题
    private lazy var totalAppsLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        // 初始化数据
        titleLabel.text = getTitleContent(count: 0)
        // swiftlint:disable init_font_with_token
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12.0, weight: .regular)
        // swiftlint:enable init_font_with_token
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()

    /// 中间应用的bar
    private lazy var appsBar: MostUsedAppHoriziontalList = {
        let bar = MostUsedAppHoriziontalList()
        let tap = UITapGestureRecognizer(target: self, action: #selector(settingClick(sender:)))
        bar.addGestureRecognizer(tap)
        return bar
    }()

    /// 右边的设置按钮
    private lazy var settingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_SettingsBttn, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.titleLabel?.textAlignment = .right
        button.addTarget(self, action: #selector(settingClick(sender:)), for: .touchUpInside)
        return button
    }()

    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(totalAppsLabel)
        addSubview(appsBar)
        addSubview(settingButton)
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        settingButton.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (
                        CGSize(width: size.width + highLightTextWidthMargin, height: highLightCommonTextHeight),
                        highLightCorner
                    )
                }
            )
        )
    }

    override func updateConstraints() {
        totalAppsLabel.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        settingButton.snp.remakeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        appsBar.snp.remakeConstraints { (make) in
            make.left.equalTo(totalAppsLabel.snp.right)
            make.right.equalTo(settingButton.snp.left).offset(-8)
            make.centerY.height.equalToSuperview()
        }

        super.updateConstraints()
    }

    // MARK: Action
    @objc
    func settingClick(sender: UIButton) {
        settingClick?()
    }
}
