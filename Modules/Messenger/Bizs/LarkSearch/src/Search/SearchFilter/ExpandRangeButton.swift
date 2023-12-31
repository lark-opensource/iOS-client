//
//  ExpandRangeButton.swift
//  LarkSearch
//
//  Created by hebonning on 2019/9/23.
//

import Foundation
import UIKit

final class ExpandRangeButton: UIButton {
    var addedTouchArea = CGFloat(0)

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        let newArea = CGRect(
            x: self.bounds.origin.x - addedTouchArea,
            y: self.bounds.origin.y - addedTouchArea,
            width: self.bounds.width + 2 * addedTouchArea,
            height: self.bounds.width + 2 * addedTouchArea
        )
        return newArea.contains(point)
    }
}
