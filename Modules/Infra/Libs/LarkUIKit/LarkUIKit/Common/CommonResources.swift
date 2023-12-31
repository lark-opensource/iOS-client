//
//  CommonResources.swift
//  LarkUIKit
//
//  Created by chengzhipeng-bytedance on 2018/3/29.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

public final class CommonResources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkUIKitBundle, compatibleWith: nil) ?? UIImage()
    }
}
