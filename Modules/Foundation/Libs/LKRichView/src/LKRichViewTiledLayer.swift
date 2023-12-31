//
//  LKRichViewTiledLayer.swift
//  LKRichView
//
//  Created by qihongye on 2021/8/15.
//

import UIKit
import Foundation

final class LKRichViewTiledLayer: CALayer {
    func draw() {
        guard let delegate = self.delegate else {
            return
        }
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        self.contents = renderer.image { context in
            delegate.draw?(self, in: context.cgContext)
        }.cgImage
    }
}
