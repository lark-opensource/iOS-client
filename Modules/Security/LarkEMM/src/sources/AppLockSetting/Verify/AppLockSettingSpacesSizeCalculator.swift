//
//  AppLockSettingSpacesSizeCalculator.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/11/8.
//

import Foundation
import LarkSecurityComplianceInfra

// https://bytedance.larkoffice.com/wiki/CCYtw382Ni2g5xkjImzc6FLMnHh 详见整体布局 SpaceCalculator 章节
struct AppLockSettingSpacesSizeCalculator {
    
    static let defaultSpaceHieght: CGFloat = 20
    // 每个 Space 的最大高度
    static let space1MaxSize = 320.0
    static let space2MaxSize = 108.0
    static let space3MaxSize = CGFloat.greatestFiniteMagnitude
    static let space4MaxSize = 40.0
    // 所有 Space 最小能分配到的高度
    static let spacesLeastSizes: CGFloat = 4 * Self.defaultSpaceHieght
    // 区间分隔
    static let intervalBoundMin: CGFloat = 0
    static let intervalBoundMax: CGFloat = CGFloat.greatestFiniteMagnitude
    static let intervalBound1: CGFloat = Self.space4MaxSize * 4 - Self.spacesLeastSizes
    static let intervalBound2: CGFloat = Self.space4MaxSize + Self.space2MaxSize * 3 - Self.spacesLeastSizes
    static let intervalBound3: CGFloat = Self.space4MaxSize + Self.space2MaxSize + Self.space1MaxSize * 2 - Self.spacesLeastSizes

    static func calculateSpaceSizes(currentHeight: CGFloat) -> [CGFloat] {
        let spaceSize1: CGFloat
        let spaceSize2: CGFloat
        let spaceSize3: CGFloat
        let spaceSize4: CGFloat
        let delta = currentHeight - (AppLockSettingVerifyConstKey.baseHeight + AppLockSettingVerifyConstKey.safeAreaInsetsVertical)
        switch delta {
        case intervalBoundMin..<intervalBound1:
            let quota = delta / 4
            spaceSize1 = defaultSpaceHieght + quota
            spaceSize2 = defaultSpaceHieght + quota
            spaceSize3 = defaultSpaceHieght + quota
        case intervalBound1..<intervalBound2:
            let quota = (delta - intervalBound1) / 3
            spaceSize1 = space4MaxSize + quota
            spaceSize2 = space4MaxSize + quota
            spaceSize3 = space4MaxSize + quota
        case intervalBound2..<intervalBound3:
            let quota = (delta - intervalBound2) / 2
            spaceSize1 = space2MaxSize + quota
            spaceSize2 = space2MaxSize
            spaceSize3 = space2MaxSize + quota
        case intervalBound3..<intervalBoundMax:
            let quota = (delta - intervalBound3)
            spaceSize1 = space1MaxSize
            spaceSize2 = space2MaxSize
            spaceSize3 = space1MaxSize + quota
        default:
            return [defaultSpaceHieght, defaultSpaceHieght, defaultSpaceHieght, defaultSpaceHieght]
        }
        // padding 取整，去除 space 的小数点，前三个 space 小数点后的 pt 加到第四个 space 上
        let resultWithDecimalDot = [spaceSize1, spaceSize2, spaceSize3]
        var resultWithoutDecimalDot = resultWithDecimalDot.map { ceil($0) }
        spaceSize4 = delta - resultWithoutDecimalDot.reduce(0, { value, nextValue in return value + nextValue }) + spacesLeastSizes
        resultWithoutDecimalDot.append(spaceSize4)
        return resultWithoutDecimalDot
    }
}
