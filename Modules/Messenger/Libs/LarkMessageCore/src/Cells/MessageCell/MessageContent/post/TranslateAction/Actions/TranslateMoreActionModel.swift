//
//  TranslateMoreActionModel.swift
//  LarkMessageCore
//
//  Created by Patrick on 3/8/2022.
//

import UIKit
import Foundation

public final class TranslateMoreActionModel {
    let icon: UIImage
    let title: String
    let tapHandler: (() -> Void)

    public init(icon: UIImage,
         title: String,
         tapHandler: @escaping (() -> Void)) {
        self.icon = icon
        self.title = title
        self.tapHandler = tapHandler
    }
}
