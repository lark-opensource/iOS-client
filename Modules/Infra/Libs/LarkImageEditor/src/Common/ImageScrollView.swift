//
//  ImageScrollView.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2018/8/6.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

final class ImageScrollView: UIScrollView {
    let imageView: UIImageView

    init(imageView: UIImageView) {
        self.imageView = imageView
        super.init(frame: CGRect.zero)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let point = self.convert(point, to: imageView)
        if imageView.point(inside: point, with: event) {
            return true
        }
        return super.point(inside: point, with: event)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
