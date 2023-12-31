//
//  SketchDrawable.swift
//
//
//  Created by 刘建龙 on 2020/3/8.
//

import Foundation
import CoreGraphics

public protocol SketchDrawable {
    func drawIn(context: CGContext)
}
