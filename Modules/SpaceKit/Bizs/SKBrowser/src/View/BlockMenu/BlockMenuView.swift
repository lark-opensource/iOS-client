//
//  BlockMenuView.swift
//  SKBrowser
//
//  Created by zoujie on 2020/8/12.
//  
import SKFoundation
import WebKit
import SKResource
import SKUIKit
import UniverseDesignColor
import SKInfra
import SKCommon

public final class BlockMenuView: BlockMenuBaseView {
  
    public let itemHeigth: CGFloat = 70
    //Block菜单item的宽度,根据当前菜单的宽度和菜单项的个数来设置
    public var itemWidth: CGFloat = 0
    private var minItemWidth: CGFloat = 56
    //iPad分屏下Block菜单父view的最小宽度
    private let minSplitScreenWidth: CGFloat = 320
    //iPad下菜单宽度大于320时，Block菜单item的宽度
    private let iPadNormalItemWidth: CGFloat = 78
    //Block菜单每行之间的距离
    private let lineSpace: Int = 1
    private var viewModel: BlockMenuViewModel?
    private(set) var data: [BlockMenuItem]?
    private var cellHeight: [Int: CGFloat] = [:]
    
    private let layout = UICollectionViewFlowLayout()
    private(set) var collectionView: UICollectionView
    private let reuseIdentifier: String = "com.bytedance.ee.docs.blockmenu"
    
    private var blockMenuScrollEnable: Bool = false {
        didSet {
            collectionView.isScrollEnabled = blockMenuScrollEnable
            collectionView.showsVerticalScrollIndicator = blockMenuScrollEnable
        }
    }

    public override init(shouldShowDropBar: Bool = false, isNewMenu: Bool = false) {
        layout.minimumLineSpacing = CGFloat(lineSpace)
        layout.minimumInteritemSpacing = BlockMenuConst.minimumInteritemSpacing
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(IconWithTextCell.self, forCellWithReuseIdentifier: reuseIdentifier)
       
        super.init(shouldShowDropBar: shouldShowDropBar, isNewMenu: isNewMenu)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.bounces = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if isNewMenu {
            menuPadding = 12
            collectionView.contentInset = UIEdgeInsets(top: 2, left: 4, bottom: 8, right: 4)
        }
        _addsubView()

        viewModel = BlockMenuViewModel(isIPad: SKDisplay.pad,
                                       data: data ?? [])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _addsubView() {
//        self.layer.ud.setShadowColor(UDColor.N1000)
//        self.layer.shadowOpacity = 0.1
//        self.layer.shadowOffset = CGSize(width: 4, height: 6)
        backgroundColor = UDColor.bgBody
        collectionView.backgroundColor = UDColor.bgBody

        contentView.addSubview(collectionView)

        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    public override func setMenus(data: [BlockMenuItem]) {
        viewModel?.data = data
        var needUpdat: Bool = false
        if let origlData = self.data,
           origlData.count == data.count {
            for (i, item) in data.enumerated() where item != origlData[i] {
                needUpdat = true
            }
        } else {
            needUpdat = true
        }
        guard !isShow || needUpdat else { return }
        self.data = data
        countMenuSize()
        reloadItems()
    }

    public override func showMenu() {
        countMenuSize()
        layout.invalidateLayout()
        super.showMenu()
        //重新打开时，重置blockMenu的滚动进度
        collectionView.setContentOffset(.zero, animated: false)
        //菜单可滚动时，显示滚动条作提醒
        collectionView.flashScrollIndicators()
    }

    private func reloadItems() {
        UIView.performWithoutAnimation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            CATransaction.commit()
        }
    }

    /// 根据菜单项的个数以及父view的宽度来动态的计算当前view的宽高
    override func countMenuSize() {
        guard let superview = self.superview,
              let data = self.data,
              let viewModel = viewModel else {
            return
        }

        //菜单项的个数
        let menuItemsCount = data.count

        //Block菜单最大宽度为与文档左右8pt的间距
        let maxMenuWidth = superview.frame.width -
        2 * menuMargin -
        2 * offsetLeft -
        (delegate?.getCommentViewWidth ?? 0)
        var currentMenuWidth = maxMenuWidth
        
        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
            currentMenuWidth = 500
        }
        
        //iPad适配
        if UIDevice.current.userInterfaceIdiom == .pad && self.isMyWindowRegularSize() {
            var estimateWidth: CGFloat = CGFloat(menuItemsCount) * iPadNormalItemWidth + menuPadding * 2
            estimateWidth += CGFloat(data.count - 1) * BlockMenuConst.minimumInteritemSpacing

            currentMenuWidth = max(estimateWidth, iPadminMenuWidth)
            currentMenuWidth = min(currentMenuWidth, maxMenuWidth)
        }
        menuWidth = currentMenuWidth
        menuWidth = max(prepareSize.width, menuWidth)

        viewModel.menuWidth = menuWidth
        let perLineItemNum = viewModel.getPerLineItemNum()
        guard perLineItemNum > 0 else { return }
        var lineNum = menuItemsCount < perLineItemNum ? 1 : Int(ceil(Double(menuItemsCount) / Double(perLineItemNum)))

        let maxLine = SettingConfig.blockMenuMaxLine ?? 2
        
        blockMenuScrollEnable = lineNum > maxLine ? true : false

        let totalSpace: CGFloat = CGFloat((lineNum - 1) * lineSpace) + menuPadding

        //目前最多3行，超过3行菜单可滚动
        lineNum = min(lineNum, maxLine)

        let totalInteritemSpacing: CGFloat = CGFloat(perLineItemNum - 1) *
            BlockMenuConst.minimumInteritemSpacing
        itemWidth = floor((menuWidth - 2 * menuPadding - totalInteritemSpacing) / CGFloat(perLineItemNum))
        itemWidth = max(minItemWidth, itemWidth)

        cellHeight = viewModel.countItemHeight(itemWidth: itemWidth)

        var totalCellHeight: CGFloat = 0
        cellHeight.forEach { (line, cellHeight) in
            if line < maxLine {
                totalCellHeight += cellHeight
            }
        }

        menuHeight = totalCellHeight + totalSpace
        menuHeight = shouldShowDropBar ? menuHeight + 34 : menuHeight + 12
        menuHeight = min(prepareSize.height, menuHeight)
        super.countMenuSize()
    }

    public override func refreshLayout() {
        if isShow {
            layoutIfNeeded()
            countMenuSize()
        }
        super.refreshLayout()
        UIView.performWithoutAnimation {
            layout.invalidateLayout()
        }
    }

    public override func scale(leftOffset: CGFloat, isShrink: Bool = true) {
        offsetLeft = isShrink ? leftOffset : 0
        layoutIfNeeded()
        countMenuSize()
        UIView.performWithoutAnimation {
            layout.invalidateLayout()
        }
        super.scale(leftOffset: leftOffset, isShrink: isShrink)
    }
}

extension BlockMenuView: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let data = self.data else { return }
        guard indexPath.row < data.count else { return }
        let item = data[indexPath.row]
        collectionView.deselectItem(at: indexPath, animated: false)
        item.action?()
    }
}

extension BlockMenuView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
   public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let data = self.data else { return 0 }
        return data.count
    }

   public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       guard let data = self.data,
             indexPath.row < data.count,
             let viewModel = viewModel else { return .zero }
        var height = itemHeigth
        let perLineItemNum = viewModel.getPerLineItemNum()
        guard perLineItemNum > 0 else {
            DocsLogger.error("==BlockMenu== error, block menu perLineItemNum is less than zero, menuWidth is \(viewModel.menuWidth) data count is \(data.count), viewModel data count is \(viewModel.data.count)")
            return .zero 
        }
        let line: Int = indexPath.row / perLineItemNum
        guard line < cellHeight.count else { return CGSize(width: itemWidth, height: height) }
        height = cellHeight[line] ?? itemHeigth

        return CGSize(width: itemWidth, height: height)
    }

   public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let data = self.data, indexPath.row < data.count else { return collectionViewCell }
        let item = data[indexPath.row]
        collectionViewCell.accessibilityIdentifier = BlockMenuConst.cellIdentifierPrefix + item.id

        guard let cell = collectionViewCell as? IconWithTextCell else { return collectionViewCell }
        cell.update(blockMenuItem: data[indexPath.row], isNewMenu: isNewMenu)
        return cell
    }
}
