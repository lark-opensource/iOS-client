//
//  InlineAIVoiceTabsView.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/10/13.
//

import Foundation
import UniverseDesignTabs
import UniverseDesignFont
import UniverseDesignColor

class InlineAIVoiceTabsView: UIView {
    
    /// 选中索引切换
    var indexChanged: ((Int) -> Void)?
    
    private lazy var tabsTitleView: UDTabsTitleView = {
        let titleSelectedFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let tabsView = UDTabsTitleView()
        tabsView.delegate = self
        tabsView.widthForTitleClosure = { str in
            return NSString(string: str)
                .boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity),
                              options: [.usesFontLeading, .usesLineFragmentOrigin],
                              attributes: [.font: titleSelectedFont],
                              context: nil)
                .size.width
        }
        
        // 指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorWidth = 20
        indicator.indicatorHeight = 3
        indicator.verticalOffset = 6
        indicator.indicatorColor = self.aiPrimaryColor(width: 20, height: 3)
        indicator.indicatorMaskedCorners = .all
        
        // 设置页签视图
        tabsView.backgroundColor = .clear
        tabsView.indicators = [indicator]
        
        // 设置页签外观配置
        let config = tabsView.getConfig()
        config.layoutStyle = .custom()
        config.isShowGradientMaskLayer = true
        config.maskWidth = 20
        config.titleNormalColor = UDColor.textCaption
        config.titleNormalFont = .systemFont(ofSize: 14, weight: .regular)
        config.titleSelectedFont = .systemFont(ofSize: 14, weight: .semibold)
        config.itemSpacing = 16
        tabsView.setConfig(config: config)
        return tabsView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        updateInitialCellStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        
        self.addSubview(tabsTitleView)
        tabsTitleView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension InlineAIVoiceTabsView {
    
    func setTitles(_ titles: [String]) {
        tabsTitleView.titles = titles
    }
}

extension InlineAIVoiceTabsView: UDTabsViewDelegate {
    
    func tabsView(_ tabsView: UniverseDesignTabs.UDTabsView, didSelectedItemAt index: Int) {
        let cell = tabsView.tabsView(cellForItemAt: index)
        updateSelectedStyle(cellSize: cell.frame.size)
        
        indexChanged?(index)
    }
}

extension InlineAIVoiceTabsView {
    
    private func aiPrimaryColor(width: CGFloat, height: CGFloat) -> UIColor {
        let size = CGSize(width: width, height: height)
        return UDColor.AIPrimaryContentDefault(ofSize: size) ?? UDColor.textCaption
    }
    
    private func updateInitialCellStyle() {
        let cell = tabsTitleView.tabsView(cellForItemAt: 0)
        updateSelectedStyle(cellSize: cell.frame.size)
    }
    
    private func updateSelectedStyle(cellSize: CGSize) {
        let size = cellSize
        let config = tabsTitleView.getConfig()
        config.titleSelectedColor = self.aiPrimaryColor(width: size.width, height: size.height)
        tabsTitleView.setConfig(config: config)
    }
}
