//
//  WebExtensionController.swift
//  Lark
//
//  Created by lichen on 2017/4/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit

/// 更多面板item
public struct WebExtensionItem {
    var name: String
    var image: UIImage?
    var clickCallback: () -> Void
}
