//
//  TemplateCellLayoutInfo.swift
//  SKCommon
//
//  Created by litao_dev on 2020/12/3.
//

import SKUIKit

enum TemplateCellLayoutInfo {
    private static let inCenterDefault = CGSize(width: 164, height: 152)
    private static let suggestDefault = CGSize(width: 128, height: 124)
    static let baseScreenWidth: CGFloat = 375.0 // UI设计图的屏幕宽度,根据要求,用来做cell的等比缩放计算
    static var isRegularSize: Bool = false
    
    static let inCenterBottomContainerHeight: CGFloat = 53
    static let inCenterBottomContainerHeightWithNoSubTitle: CGFloat = 38
    static let suggestBottomContainerHeight: CGFloat = 48
    static let inCenterCollectionLeftPadding: CGFloat = 16
    private static let inCenterCellPadding: CGFloat = 15
    static let themeImageWidthDefault: CGFloat = 164
    static let themeImageHeightDefault: CGFloat = 100

    /// 根据当前VC的宽度来计算cell的size，进行等比缩放
    /// - Parameter hostViewWidth: 当前VC或者collectionView的宽度
    /// - Returns: 动态计算的size
    static func inCenter(with hostViewWidth: CGFloat, withSubTitle: Bool = true) -> CGSize {
        guard hostViewWidth > 0.001 else { return inCenterDefault }
        var count: CGFloat = 2
        if SKDisplay.pad {
            // 125.0 <= [hostViewWidth-16*2-15*(n-1)]/n
            count = max(floor((hostViewWidth - 17.0) / 140.0), 2.0)
        }
        let width = (hostViewWidth - 2 * inCenterCollectionLeftPadding - inCenterCellPadding * (count - 1)) / count
        let bottomHeight = withSubTitle ? inCenterBottomContainerHeight : inCenterBottomContainerHeightWithNoSubTitle
        let height = width * themeImageHeightDefault / themeImageWidthDefault + bottomHeight
        return CGSize(width: width, height: height)
    }
    
    /// 根据当前VC的宽度来计算cell的size，进行等比缩放
    /// - Parameter hostViewWidth: 当前VC或者collectionView的宽度
    /// - Returns: 动态计算的size
    static func suggest(with hostViewWidth: CGFloat, defaultSize: CGSize = suggestDefault) -> CGSize {
        guard hostViewWidth > 0.001 else { return defaultSize }
        let width = hostViewWidth * defaultSize.width / baseScreenWidth
        let height = width * defaultSize.height / defaultSize.width
        return CGSize(width: width, height: height)
    }
}
