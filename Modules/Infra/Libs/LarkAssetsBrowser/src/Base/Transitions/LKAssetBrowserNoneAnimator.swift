//
//  LKAssetBrowserNoneAnimator.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit

/// 使用本类以实现不出现转场动画的需求
open class LKAssetBrowserNoneAnimator: LKAssetBrowserFadeAnimator {

    public override init() {
        super.init()
        showDuration = 0
        dismissDuration = 0
    }
}
