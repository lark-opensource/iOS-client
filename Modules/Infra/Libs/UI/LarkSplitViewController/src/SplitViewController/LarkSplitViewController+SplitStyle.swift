//
//  LarkSplitViewController+SplitStyle.swift
//  LarkSplitViewController
//
//  Created by shin on 2023/5/5.
//

import Foundation

extension SplitViewController {
    /// 分屏样式，默认是 side 固定宽度
    public enum SplitStyle: Int {
        /// primary 和 supplementary 可设置固定宽度，默认 320
        case sideFixed = 0
        /// 按比例展示，primary 和 supplementary 作为整体的 sideContent，和 secondaryContent 按照比例展示，
        /// 可以按照 3:1，2:2，1:3 预设比例展示
        //case ratio = 1
        /// secondary 设置固定宽度，默认 375
        case secondaryFixed = 2
    }

    /// 分屏比例，默认 sideMayjority，仅在非 sideOnly 和 secondaryOnly 下有效
    /*
    public enum SplitRatio: Int {
        /// unset ratio
        case unset = 0
        /// side : secondary = 2:1
        case sideMayjority = 1
        /// side : secondary = 1:1
        case half = 2
        /// side : secondary = 1:2
        case secondaryMayjority = 3

        var ratio: CGFloat {
            switch self {
            case .unset:
                return 0.0
            case .sideMayjority:
                return 2.0 / 3.0
            case .half:
                return 0.5
            case .secondaryMayjority:
                return 1.0 / 3.0
            }
        }
    }
     */
}
