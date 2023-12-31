//
//  LabEffectService+Utils.swift
//  ByteView
//
//  Created by wangpeiran on 2021/11/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxRelay
import RxSwift


// MARK: - 是否开启某个特效+关闭某个特效，目前提供给降级

extension EffectPretendService {

    var isAnyEffectOn: Bool {
        isAnimojiOn() || isFilterOn() || isBeautyOn()
    }

    func isAnimojiOn() -> Bool {
        if !animojiArray.isEmpty {
            for item in animojiArray where (item.isSelected && item.bgType == .set ) {
                return true
            }
        }
        return false
    }

    func isFilterOn() -> Bool {
        if !filterArray.isEmpty {
            for item in filterArray where (item.isSelected && item.bgType == .set && item.currentValue ?? 0 > 0 ) {
                return true
            }
        }
        return false
    }

    func isBeautyOn() -> Bool {
        switch beautyCurrentStatus {
        case .none:
            return false
        case .auto:
            return true
        default:
            var sum = 0
            if !retuschierenArray.isEmpty {
                for item in retuschierenArray {
                    sum += item.currentValue ?? 0
                }
            }
            return sum != 0
        }
    }

    func cancelAnimoji() {
        guard let model = currentAnimojiModel else {
            return
        }
        cancelPretend(model: model)
        animojiArray.forEach({ model in
            model.isSelected = false
        })
        noneAnimojiModel?.isSelected = true
    }

    // 暴露给外界，未经过测试，暂时没人调用
    func cancelFilter() {
        guard let model = currentFilterModel else {
            return
        }
        cancelPretend(model: model)
        filterArray.forEach({ model in
            model.isSelected = false
        })
        noneFilterModel?.isSelected = true
        saveEffectSetting(effectModel: noneFilterModel)
    }

    // 暴露给外界，未经过测试，暂时没人调用
    func cancelBeauty() {
        guard !retuschierenSettingArray.isEmpty, let noneModel = noneBeautySettingModel else {
            return
        }
        cancelPretend(model: noneModel)
        retuschierenSettingArray.forEach({ model in
            model.isSelected = false
        })
        noneModel.isSelected = true
        saveEffectSetting(effectModel: noneModel)
    }
}
