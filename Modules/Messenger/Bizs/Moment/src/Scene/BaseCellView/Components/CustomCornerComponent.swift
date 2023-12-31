//
//  CustomCornerComponent.swift
//  Moment
//
//  Created by bytedance on 1/13/22.
//

import Foundation
import AsyncComponent
import UIKit
import LarkMessageBase

final class CustomCornerComponent<C: ComponentContext>: ASComponent<CustomCornerComponent.Props, EmptyState, UIView, C> {
    final class Props: ASComponentProps {
        var cornerSize: CGSize
        var corners: CACornerMask
        init(corners: CACornerMask, cornerSize: CGSize) {
            self.corners = corners
            self.cornerSize = cornerSize
        }
    }
    public override func update(view: UIView) {
        super.update(view: view)
        view.lu.addCorner(corners: props.corners, cornerSize: props.cornerSize)
    }
}
