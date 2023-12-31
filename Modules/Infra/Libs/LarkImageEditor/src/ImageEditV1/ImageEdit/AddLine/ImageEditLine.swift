//
//  ImageEditLine.swift
//  LarkUIKit
//
//  Created by SuPeng on 12/19/18.
//

import UIKit
import Foundation

final class ImageEditLine: UIBezierPath {
    var color: ColorPanelType
    private(set) var points: [CGPoint] = []

    init(color: ColorPanelType) {
        self.color = color
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func add(point: CGPoint) {
        if points.isEmpty {
            move(to: point)
        } else {
            addLine(to: point)
        }
        points.append(point)
    }
}
