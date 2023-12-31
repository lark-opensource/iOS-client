//
//  ImageOCRAction.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/23.
//

import UIKit
import Foundation

public struct ImageOCRAction {
    public var icon: UIImage
    public var title: String
    public var titleColor: UIColor
    public var handler: () -> Void

    public init(
        icon: UIImage,
        title: String,
        titleColor: UIColor,
        handler: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.titleColor = titleColor
        self.handler = handler
    }
}
