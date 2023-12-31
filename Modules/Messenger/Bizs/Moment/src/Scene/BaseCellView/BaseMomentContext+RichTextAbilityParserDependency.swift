//
//  BaseMomentContext+RichTextAbilityParserDependency.swift
//  Moment
//
//  Created by zc09v on 2021/3/1.
//

import UIKit
import Foundation
import LarkMessageBase

extension BaseMomentContext: RichTextAbilityParserDependency {
    var targetVC: UIViewController? {
        return self.pageAPI
    }

    var maxWidth: CGFloat {
        return self.maxCellWidth
    }
}
