//
//  Resources.swift
//  larkDebug
//
//  Created by liluobin on 2021/1/7.
//
import UIKit
#if !LARK_NO_DEBUG
import Foundation
/// 图片资源
public final class Resources {
    static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkDebugBundle, compatibleWith: nil) ?? UIImage()
    }
    static let debugDic = Resources.image(named: "lark_dir")
    static let debugFile = Resources.image(named: "lark_file")
    static let backBtn = Resources.image(named: "back_btn")
}
#endif
