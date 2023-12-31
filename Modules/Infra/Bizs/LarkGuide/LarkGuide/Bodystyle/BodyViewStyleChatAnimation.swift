//
//  BodyViewStyleChatAnimation.swift
//  LarkGuide
//
//  Created by sniperj on 2019/3/7.
//

import UIKit
import Foundation
import LarkUIKit

public enum CutoutViewStyle {
    case `default`
    case circle
}

public struct ChatAnimationPreference {
    public var cutoutStyle: CutoutViewStyle = .default
    public var offset: CGPoint = .zero
    public var startPointOffset: CGFloat = 0
    public init() {}
}

public protocol LineGuideItemInfo: AnyObject {
    var key: String { get }
    var guideView: UIView { get }
    var guideViewSize: CGSize { get }
}

public final class BodyViewStyleChatAnimation: BodyViewClass<GuideLineLayer> {

    required init(focusPoint: CGPoint?, focusArea: CGRect?) {
        super.init(focusPoint: focusPoint, focusArea: focusArea)
        self.bodyView = GuideLineLayer(guideView: UIView(), size: .zero)
    }

    override public func show(to parentView: UIView, mark: GuideMark?, guideMarkController: GuideMarksController?, complete: () -> Void) {
        guard let focusArea = self.focusArea,
            let mark = mark else { complete(); return }
        if case let .chatAnimationView(info, offset, startPointOffset)? = mark.bodyViewParamStyle {
            self.guideMarkController = guideMarkController
            info.guideView.isUserInteractionEnabled = false
            self.bodyView?.update(guideView: info.guideView, size: info.guideViewSize)
            self.bodyView?.startPoint = CGPoint(x: focusArea.minX + offset.x, y: focusArea.minY + offset.y)
            if let startPointOffset = startPointOffset {
                self.bodyView?.startPointOffset = startPointOffset
            }
            self.bodyView?.maskClickBlock = { [weak self] _ in
                self?.guideMarkController?.showNextStep()
            }

            self.bodyView?.show(in: parentView)
            complete()
        }
    }
}
