//
//  BodyViewFeedUpgradeTeamGuide.swift
//  LarkGuide
//
//  Created by mochangxing on 2020/4/14.
//

import UIKit
import Foundation

public final class BodyViewFeedUpgradeTeamGuide: BodyViewClass<FeedUpgradeTeamGuideView> {

    required init(focusPoint: CGPoint?, focusArea: CGRect?) {
        super.init(focusPoint: focusPoint, focusArea: focusArea)
    }

    override public func show(to parentView: UIView, mark: GuideMark?, guideMarkController: GuideMarksController?, complete: () -> Void) {
        guard let focusArea = self.focusArea,
            let mark = mark else { complete(); return }
        if case let .feedUpgradeTeamGuideView(titleText, contentText)? = mark.bodyViewParamStyle {
            self.guideMarkController = guideMarkController
            self.bodyView = FeedUpgradeTeamGuideView(titleText: titleText, contentText: contentText)
            self.bodyView?.show(focus: focusArea, toView: parentView)
            complete()
        }
    }
}
