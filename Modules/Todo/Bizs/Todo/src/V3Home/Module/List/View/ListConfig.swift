//
//  ListConfig.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/22.
//

import Foundation
import UIKit
import UniverseDesignFont

// MARK: - Config

enum ListConfig {}

// MARK: - Cell

extension ListConfig {

    enum Cell {
        // time
        static let timeIconSize: CGSize = CGSize(width: 12.0, height: 12.0)
        static let timeIconTextSpace: CGFloat = 6.0
        static let timeHeight: CGFloat = 20.0

        static let separateWidth: CGFloat = 1.0
        static let separateHeight: CGFloat = 12.0
        static let separateSpace: CGFloat = 12.0

        // extension
        static let extensionIconSize = timeIconSize
        static let extensionHeight: CGFloat = 20.0
        static let extensionIconTextSpace: CGFloat = 4.0
        static let extensionSpace: CGFloat = 8.0

        //
        static let titleFont: UIFont = UDFont.systemFont(ofSize: 16)
        static let detailFont: UIFont = UDFont.systemFont(ofSize: 14)

        // check box
        static let checkBoxSize: CGSize = CGSize(width: 16.0, height: 16.0)
        static let checkBoxTop: CGFloat = 4.0

        // padding
        static let topPadding: CGFloat = 13.0
        static let leftPadding: CGFloat = 16.0
        static let rightPadding: CGFloat = 16.0
        static let bottomPadding: CGFloat = 13.0
        static let verticalSpace: CGFloat = 5.0
        static let horizontalSpace: CGFloat = 8.0
        // 单行标题的高度填充
        static let singleSpace: CGFloat = 2.0

        // title
        static let minTitleHeight: CGFloat = 22.0
        static let maxTitleHeight: CGFloat = 50.0

        // user
        static let userHeight: CGFloat = 24.0

        // height
        static let minHeight: CGFloat = 48.0
        static let middleHeight: CGFloat = 70.0

        // background color
        static let bgColor: UIColor = UIColor.ud.bgBody
    }

    enum Section {
        static let verticalPadding: CGFloat = 12.0
        static let horizontalPadding: CGFloat = 16.0
        static let horizontalSpace: CGFloat = 8.0
        static let rHorizontalSpace: CGFloat = 16.0

        // leading icon
        static let leadingIconSize: CGSize = CGSize(width: 12.0, height: 12.0)
        // title
        static let titleIconSize: CGSize = CGSize(width: 16.0, height: 16.0)
        static let titleIconSpace: CGFloat = 6.0

        static let contentHeight: CGFloat = 24.0

        static let badgeHeight: CGFloat = 16.0

        // font
        static let titleFont: UIFont = UDFont.systemFont(ofSize: 16, weight: .medium)
        static let mainFont: UIFont = UDFont.systemFont(ofSize: 14)
        static let badgeFont: UIFont = UDFont.systemFont(ofSize: 12)

        // user
        static let userLeftPadding: CGFloat = 2.0
        static let userSize: CGSize = CGSize(width: 20.0, height: 20.0)
        static let userSpace: CGFloat = 4.0
        static let userRightPadding: CGFloat = 8.0

        // trailing icon
        static let trailingIconSize: CGSize = CGSize(width: 20.0, height: 20.0)

        static let footerLeftPadding: CGFloat = 40.0

        static let headerHeight: CGFloat = 36.0
        static let footerTitleHeight: CGFloat = 48.0
        static let footerSpaceHeight: CGFloat = 12.0
    }
}
