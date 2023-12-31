//
//  UDSegmentedControl.swift
//  UniverseDesignTabs
//
//  Created by Hayden on 2023/2/13.
//

import Foundation
import UIKit

public class UDSegmentedControl: UDTabsTitleView {

    public private(set) var configuration: Configuration
    private var indicator: UDTabsIndicatorProtocol?

    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        commonInit()
    }

    public override init(frame: CGRect) {
        self.configuration = Configuration()
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        self.setConfig(config: configuration.toTabsTitleConfig())
        let indicator = configuration.makeIndicator()
        self.indicator = indicator
        self.indicators = [indicator]
        updateAppearance()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }

    private func updateAppearance() {
        self.backgroundColor = configuration.backgroundColor
        self.layer.masksToBounds = true
        self.collectionView.isScrollEnabled = configuration.isScrollEnabled
        self.collectionView.bounces = configuration.isBounceEnabled
        updateCornerRadius()
    }

    private func updateCornerRadius() {
        switch configuration.cornerStyle {
        case .none:
            self.layer.cornerRadius = 0
            indicator?.layer.cornerRadius = 0
        case .rounded:
            self.layer.cornerRadius = bounds.height / 2
            indicator?.layer.cornerRadius = bounds.height / 2 - configuration.contentEdgeInset
        case .fixedRadius(let cornerRadius):
            self.layer.cornerRadius = cornerRadius
            indicator?.layer.cornerRadius = cornerRadius - configuration.contentEdgeInset
        }
        if let indicator = indicator {
            let xPosition = indicator.frame.minX
            let yPosition = configuration.contentEdgeInset
            let width = indicator.frame.width
            let height = bounds.height - configuration.contentEdgeInset * 2
            indicator.frame = CGRect(x: xPosition, y: yPosition, width: width, height: height)
        }
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: getIntrinsicContentWidth(), height: configuration.preferredHeight)
    }

    public override func preferredTabsView(widthForItemAt index: Int) -> CGFloat {
        guard !itemDataSource.isEmpty else {
            return 0
        }
        switch configuration.itemDistributionStyle {
        case .equalWidth:
            var availableWidth = bounds.width
            availableWidth -= config.itemSpacing * CGFloat(itemDataSource.count - 1)
            availableWidth -= (config.contentEdgeInsetLeft + config.contentEdgeInsetRight)
            let availableItemWidth = availableWidth / CGFloat(self.itemDataSource.count)
            let longestItemWidth = titles.map({ title in
                title.getWidth(font: configuration.titleFont) + configuration.titleHorizontalMargin * 2
            }).max() ?? 0
            return min(max(availableItemWidth, longestItemWidth), config.itemMaxWidth)
        case .automatic:
            let preferedItemWidth = titles[index].getWidth(font: configuration.titleFont) + configuration.titleHorizontalMargin * 2
            return min(preferedItemWidth, configuration.itemMaxWidth)
        case .fixedWidth(let width):
            return min(width, configuration.itemMaxWidth)
        }
    }

    /// 在受外部宽度约束时，UDSegmentedControl 的固有宽度
    private func getIntrinsicContentWidth() -> CGFloat {
        guard titles.count > 0 else { return 0 }
        var totalItemWidth: CGFloat = 0
        switch configuration.itemDistributionStyle {
        case .equalWidth:
            let longestItemWidth = titles.map({ title in
                title.getWidth(font: configuration.titleFont) + configuration.titleHorizontalMargin * 2
            }).max() ?? 0
            totalItemWidth = min(longestItemWidth, configuration.itemMaxWidth) * CGFloat(titles.count)
        case .automatic:
            totalItemWidth = titles.map({ title in
                let preferedItemWidth = title.getWidth(font: configuration.titleFont) + configuration.titleHorizontalMargin * 2
                return min(preferedItemWidth, configuration.itemMaxWidth)
            }).reduce(0, +)
        case .fixedWidth(let width):
            totalItemWidth = min(width, configuration.itemMaxWidth) * CGFloat(titles.count)
        }
        let totalSpacing = configuration.itemSpacing *  CGFloat(titles.count - 1)
        let totalWidth = totalItemWidth + totalSpacing + configuration.contentEdgeInset * 2
        return ceil(totalWidth)
    }

    public override func reloadData() {
        super.reloadData()
        updateCornerRadius()
    }

}
