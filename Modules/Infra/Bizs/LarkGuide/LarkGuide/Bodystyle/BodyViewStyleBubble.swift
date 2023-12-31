//
//  BodyViewStyleBubble.swift
//  LarkGuide
//
//  Created by sniperj on 2019/3/5.
//

import UIKit
import Foundation
import LarkUIKit

public final class BodyViewBubbleStyle: BodyViewClass<EasyhintBubbleView> {

    required init(focusPoint: CGPoint?, focusArea: CGRect?) {
        super.init(focusPoint: focusPoint, focusArea: focusArea)
    }

    override public func show(to parentView: UIView, mark: GuideMark?, guideMarkController: GuideMarksController?, complete: () -> Void) {
        guard let focusArea = self.focusArea,
            let mark = mark else { complete(); return }
        if case let .easyHintBubbleView(text, preference)? = mark.bodyViewParamStyle {
            self.guideMarkController = guideMarkController
            self.bodyView = EasyhintBubbleView(text: text, preferences: preference)
            self.bodyView?.show(forRect: focusArea, withinSuperview: parentView)
            self.bodyView?.clickBlock = { [weak self] in
                self?.guideMarkController?.showNextStep()
            }
            complete()
        }
    }
}
