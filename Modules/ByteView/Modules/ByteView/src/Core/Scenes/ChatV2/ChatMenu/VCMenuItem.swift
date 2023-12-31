//
//  VCMenuItem.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit

protocol VCMenuItem {
    var name: String { get }
    var image: UIImage { get }
    func menuItemDidClick()
}
