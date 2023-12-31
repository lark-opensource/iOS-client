//
//  QuickTabBarConfig.swift
//  AnimatedTabBar
//
//  Created by 夏汝震 on 2021/6/4.
//

import Foundation
import UIKit

struct QuickTabBarConfig {
    enum Layout {
        static let cornerRadius: CGFloat = 12.0
        static let topViewHeight: CGFloat = 56.0
        static let lineHeight: CGFloat = 1.0 / UIScreen.main.scale
        static let topViewInset: CGFloat = 16.0
        static let itemSpacing: CGFloat = 0
        static let collectionSectionInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 16, right: 8)
        static let quickSectionInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 16, right: 8)
        static let mainSectionInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        static let itemSize: CGSize = CGSize(width: 88, height: 104)
        static let mainItemSize: CGSize = CGSize(width: 65, height: 65)
        static let emptyViewHeight: CGFloat = 232
        static let maxTabBarItems: Int = 5

        // iPad might be more.
        static var collectionMaxLineCount: Int {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return 4
            } else {
                return 4
            }
        }

        static func maxHeight(for itemCount: Int) -> CGFloat {
            guard itemCount > 0 else {
                return topViewHeight + emptyViewHeight
            }
            let lines = (itemCount - 1) / collectionMaxLineCount + 1
            let contentHeight = CGFloat(lines) * itemSize.height + CGFloat(lines - 1) * QuickTabBarConfig.Layout.itemSpacing
            return topViewHeight
                + collectionSectionInset.top
                + contentHeight
                + collectionSectionInset.bottom
        }

        static func realItemSize(forWidth width: CGFloat) -> CGSize {
            // 限制一行 4 个，根据 collectionView 的宽度调整大小
            let allCellWidth = width
                - Layout.collectionSectionInset.left
                - Layout.collectionSectionInset.right
            let itemWidth = allCellWidth / CGFloat(Layout.collectionMaxLineCount)
            return CGSize(width: itemWidth, height: Layout.itemSize.height)
        }
    }

    enum Style {
        static let bgColor: UIColor = UIColor.ud.N00
        static let autoAnimationPercent: CGFloat = 0.75
        static let alphaPercent: CGFloat = 0.4
        static let lineColor: UIColor = UIColor.ud.N300
        static let editButtonColor: UIColor = UIColor.ud.primaryContentDefault
        static let editButtonFont: UIFont = UIFont.systemFont(ofSize: 16)
        static let editTitleFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .medium)
        static let editTitleColor: UIColor = UIColor.ud.textTitle
    }
}
