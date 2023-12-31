//
//  BTItemViewListHeaderCell.swift
//  SKBitable
//
//  Created by zoujie on 2023/7/17.
//  


import SKFoundation
import UniverseDesignTabs
import UniverseDesignColor

final class BTItemViewListHeaderCell: UICollectionViewCell {
    
    weak var delegate: BTFieldDelegate?
    
    private lazy var tabsView = UDTabsTitleView()
    
    private lazy var bottomLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineBorderCard
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(tabsView)
        addSubview(bottomLine)
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        
        tabsView.delegate = self
        tabsView.indicators = [indicator]
        let config = tabsView.getConfig()
        config.contentEdgeInsetLeft = 16
        config.itemSpacing = 28
        config.isShowGradientMaskLayer = true
        config.isItemSpacingAverageEnabled = false
        tabsView.setConfig(config: config)

        tabsView.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.edges.equalToSuperview()
        }
        
        bottomLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    func setTitles(titles: [String]) {
        tabsView.titles = titles
        tabsView.reloadData()
    }
    
    func setSelectedIndex(index: Int) {
        guard index != tabsView.selectedIndex else { return }
        tabsView.selectItemAt(index: index)
    }
}

extension BTItemViewListHeaderCell: UDTabsViewDelegate {
    func tabsView(_ tabsView: UniverseDesignTabs.UDTabsView, didClickSelectedItemAt index: Int) {
        // 点击选中tabs
        delegate?.didClickTab(index: index)
    }
}
