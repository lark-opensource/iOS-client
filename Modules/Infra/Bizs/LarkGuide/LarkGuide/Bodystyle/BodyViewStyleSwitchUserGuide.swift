//
//  BodyViewStyleNewGuide.swift
//  LarkGuide
//
//  Created by sniperj on 2020/3/1.
//

import UIKit
import Foundation

public final class BodyViewStyleSwitchUserGuide: BodyViewClass<SwitchUserGuideView> {

    required init(focusPoint: CGPoint?, focusArea: CGRect?) {
        super.init(focusPoint: focusPoint, focusArea: focusArea)
    }

    override public func show(to parentView: UIView, mark: GuideMark?, guideMarkController: GuideMarksController?, complete: () -> Void) {
        guard let focusArea = self.focusArea,
            let mark = mark else { complete(); return }
        if case let .switchUserGuideView(contentText, buttonText)? = mark.bodyViewParamStyle {
            self.guideMarkController = guideMarkController
            self.bodyView = SwitchUserGuideView(contentText: contentText, buttonText: buttonText)
            self.bodyView?.show(focus: focusArea, toView: parentView)
            self.bodyView?.clickBlock = { [weak self] in
                self?.guideMarkController?.showNextStep()
            }
            complete()
        }
    }
}
