//
//  ExtendedButton.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/20.
//

import Foundation
import UIKit

final class ExtendedButton: UIButton {

    var extendInsets: UIEdgeInsets = .zero

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newArea = CGRect(
            x: bounds.origin.x - extendInsets.left,
            y: bounds.origin.y - extendInsets.top,
            width: bounds.size.width + extendInsets.left + extendInsets.right,
            height: bounds.size.height + extendInsets.top + extendInsets.bottom
        )
        return newArea.contains(point)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
