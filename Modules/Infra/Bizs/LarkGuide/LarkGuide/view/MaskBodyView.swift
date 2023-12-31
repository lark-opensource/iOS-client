//
//  MaskBodyView.swift
//  LarkGuide
//
//  Created by sniperj on 2019/2/20.
//

import Foundation
import UIKit
import LarkUIKit

public enum bodyViewParamStyle {
    case easyHintBubbleView(String, Preferences)
    case chatAnimationView(LineGuideItemInfo, CGPoint, CGFloat?)
    case feedAnimationView(String, String, CGPoint)
    case switchUserGuideView(String, String)
    case feedUpgradeTeamGuideView(String, String)
}

open class BodyViewClass<V>: MaskBodyView {

    public weak var guideMarkController: GuideMarksController?

    public var mark: GuideMark?

    public var parentView: UIView?

    public var bodyView: V?

    public var focusArea: CGRect?

    public var focusPoint: CGPoint?

    required public init(focusPoint: CGPoint?, focusArea: CGRect?) {
        self.focusArea = focusArea
        self.focusPoint = focusPoint
    }

    public func show(to parentView: UIView, mark: GuideMark?, guideMarkController: GuideMarksController?, complete: () -> Void) {}
    public func setup() -> V? { return self.bodyView }
}

public protocol viewClass {

    var focusArea: CGRect? {get set}
    var focusPoint: CGPoint? {get set}
    var parentView: UIView? {get set}
    var mark: GuideMark? {get set}
    var guideMarkController: GuideMarksController? {get set}
    /// if have animation use this method to show your animate
    func show(to parentView: UIView, mark: GuideMark?, guideMarkController: GuideMarksController?, complete: () -> Void)
    func dismiss()
    init(focusPoint: CGPoint?, focusArea: CGRect?)
}

public protocol MaskBodyView: viewClass {

    associatedtype V
    var bodyView: V? {get set}
    /// use this method get bodyView
    ///
    /// - Returns: bodyView
    func setup() -> V?
}

public extension MaskBodyView {

    func setup() -> V? {
        return self.bodyView
    }

    func dismiss() {
        if let bodyView = self.bodyView as? UIView {
            bodyView.removeFromSuperview()
        }
    }
}
