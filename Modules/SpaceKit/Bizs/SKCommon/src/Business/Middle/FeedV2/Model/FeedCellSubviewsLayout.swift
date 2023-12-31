//
//  FeedCellSubviewsLayout.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/5/22.
//  


import Foundation

protocol FeedCellSubviewsLayout {
    // 头像
    var iconSize: CGSize { get }
    var iconTopMargin: CGFloat { get }
    var redDotDiameter: CGFloat { get }
    var redDotInset: CGFloat { get }
    // 标题
    var titleTopMargin: CGFloat { get }
    var padding: CGFloat { get }
    var iconRightMargin: CGFloat { get }
    // 引文
    var quoteTopMargin: CGFloat { get }
    var quoteHeight: CGFloat { get }
    // 内容
    var contentTopMargin: CGFloat { get }
    var translateTopMargin: CGFloat { get }
    // 时间
    var timeTopMargin: CGFloat { get }
    var timeHeight: CGFloat { get }
    var timeBottomMargin: CGFloat { get }
}

extension FeedMessageStyle {
    
    static var cellSubviewsLayout: FeedCellSubviewsLayout {
        return FeedCellSubviewsNewLayout()
    }
}

private struct FeedCellSubviewsOldLayout: FeedCellSubviewsLayout {
    // 头像
    let iconSize = CGSize(width: 40, height: 40)
    let iconTopMargin: CGFloat = 12
    let redDotDiameter: CGFloat = 12
    let redDotInset: CGFloat = -2
    // 标题
    let titleTopMargin: CGFloat = 10
    let padding: CGFloat = 16
    let iconRightMargin: CGFloat = 12
    // 引文
    let quoteTopMargin: CGFloat = 0
    let quoteHeight: CGFloat = 0
    // 内容
    let contentTopMargin: CGFloat = 4
    let translateTopMargin: CGFloat = 10
    // 时间
    let timeTopMargin: CGFloat = 12
    let timeHeight: CGFloat = 24
    let timeBottomMargin: CGFloat = 8
}

private struct FeedCellSubviewsNewLayout: FeedCellSubviewsLayout {
    // 头像
    let iconSize = CGSize(width: 36, height: 36)
    let iconTopMargin: CGFloat = 12
    let redDotDiameter: CGFloat = 10
    let redDotInset: CGFloat = 0
    // 标题
    let titleTopMargin: CGFloat = 12
    let padding: CGFloat = 16
    let iconRightMargin: CGFloat = 12
    // 引文
    let quoteTopMargin: CGFloat = 8
    let quoteHeight: CGFloat = 20
    // 内容
    let contentTopMargin: CGFloat = 8
    let translateTopMargin: CGFloat = 10
    // 时间
    let timeTopMargin: CGFloat = 16
    let timeHeight: CGFloat = 20
    let timeBottomMargin: CGFloat = 12
}
