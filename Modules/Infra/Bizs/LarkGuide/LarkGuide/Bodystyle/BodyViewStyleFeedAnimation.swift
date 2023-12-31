//
//  BodyViewStyleFeedAnimation.swift
//  LarkGuide
//
//  Created by sniperj on 2019/3/11.
//

import UIKit
import Foundation
import LarkUIKit

public struct FeedAnimationPreference {
    public var cutoutStyle: CutoutViewStyle = .default
    public var offset: CGPoint = .zero
    public init() {}
}

public final class BodyViewStyleFeedAnimation: BodyViewClass<GuideAtUserView> {

    required init(focusPoint: CGPoint?, focusArea: CGRect?) {
        super.init(focusPoint: focusPoint, focusArea: focusArea)
    }

    override public func show(to parentView: UIView, mark: GuideMark?, guideMarkController: GuideMarksController?, complete: () -> Void) {
        guard let focusArea = self.focusArea,
            let mark = mark else { complete(); return }
        if case let .feedAnimationView(buttonTitle, contentText, offset)? = mark.bodyViewParamStyle {
            self.guideMarkController = guideMarkController
            self.bodyView = GuideAtUserView(buttonText: buttonTitle)
            self.bodyView?.show(text: contentText, startPoint: CGPoint(x: focusArea.minX + offset.x, y: focusArea.minY + offset.y), superView: parentView)
            complete()
        }
    }
}
