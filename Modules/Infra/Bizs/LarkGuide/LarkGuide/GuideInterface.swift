//
//  GuideInterface.swift
//  LarkGuide
//
//  Created by sniperj on 2019/3/8.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor

public final class GuideInterface {
    private static func startGuide(bearViewController: UIViewController, marks: [GuideMark], backgroundColor: UIColor = UIColor.ud.color(0, 0, 0, 0.4), dismissBlock: (() -> Void)? = nil) {
        if bearViewController.guideController == nil {
            bearViewController.guideController = GuideMarksController()
        }
        bearViewController.guideController!.start(by: bearViewController, guideMarks: { () -> [GuideMark] in
            return marks
        }, color: backgroundColor, dismissBlock: dismissBlock)
    }

    /// show Guide use ChatAnimation and cutout area is cutoutView
    ///
    /// - Parameters:
    ///   - buttonTitle: button title
    ///   - contentText: content text
    ///   - preference: some basic preference in Guide's animation location
    ///   - bearViewController: bear viewController
    ///   - cutoutView: cutout view
    ///   - bodyViewClick: If the bodyView is clicked will excute the block
    ///   - willStart: What you need to do before guide execution, return value is action time
    ///   - willEnd: What you need to do before guide execution, return value is action time
    ///   - dismiss: What you need to do after the guide disappears
    public static func startFeedAnimationGuide(buttonTitle: String,
                                               contentText: String,
                                               preference: FeedAnimationPreference = FeedAnimationPreference(),
                                               bearViewController: UIViewController,
                                               cutoutView: @escaping () -> UIView?,
                                               bodyViewClick: (() -> Void)? = nil,
                                               willStart: (() -> Double)? = nil,
                                               willEnd: (() -> Double)? = nil,
                                               dismiss: (() -> Void)? = nil) {
        var mark = GuideMark(initWith: cutoutView, bodyViewClass: BodyViewStyleFeedAnimation.self)
        mark.willStartActionNeedTime = willStart
        mark.willEndActionNeedTime = willEnd
        mark.bodyViewClick = bodyViewClick
        mark.bodyViewParamStyle = .feedAnimationView(buttonTitle, contentText, preference.offset)
        if preference.cutoutStyle == .circle {
            if let cutoutview = cutoutView() {
                mark.cutoutCornerRadii = CGSize(width: cutoutview.frame.width / 2, height: cutoutview.frame.height / 2)
            }
        }
        GuideInterface.startGuide(bearViewController: bearViewController, marks: [mark], backgroundColor: UIColor.ud.rgb("212121").withAlphaComponent(0.3), dismissBlock: dismiss)
    }

    /// show Guide use bubbleView
    ///
    /// - Parameters:
    ///   - text: content text
    ///   - preference: bubbleView preference eg:EasyhintBubbleViewPreference.globalPreferences
    ///   - bearViewController: bear viewController
    ///   - guideMarkController: manager guideMark's controller
    ///   - cutoutView: cutout view
    ///   - willStart: What you need to do before guide execution, return value is action time
    ///   - willEnd: What you need to do before guide execution, return value is action time
    ///   - dismiss: What you need to do after the guide disappears
    public static func startBubbleGuide(text: String,
                                        preference: Preferences = EasyhintBubbleView.globalPreferences,
                                        bearViewController: UIViewController,
                                        cutoutView: @escaping () -> UIView?,
                                        willStart: (() -> Double)? = nil,
                                        willEnd: (() -> Double)? = nil,
                                        dismiss: (() -> Void)? = nil) {
        var mark = GuideMark(initWith: cutoutView, bodyViewClass: BodyViewBubbleStyle.self)
        mark.willStartActionNeedTime = willStart
        mark.willEndActionNeedTime = willEnd
        mark.bodyViewParamStyle = .easyHintBubbleView(text, preference)
        GuideInterface.startGuide(bearViewController: bearViewController, marks: [mark], backgroundColor: UIColor.clear, dismissBlock: dismiss)
    }

    public static func startSwitchUserGuide(infos: [[String: String]],
                                     bearViewController: UIViewController,
                                     cutoutView: @escaping () -> UIView?,
                                     lazycutoutPathOne: @escaping () -> UIBezierPath?,
                                     lazycutoutPathTwo: @escaping () -> UIBezierPath?,
                                     willStart: (() -> Double)? = nil,
                                     dismiss: (() -> Void)? = nil) {
        if let contentTextOne = infos[0]["contentText"],
            let buttonTextOne = infos[0]["buttonText"],
            let contentTextTwo = infos[1]["contentText"],
            let buttonTextTwo = infos[1]["buttonText"] {
            var marks: [GuideMark] = []
            var markFirst = GuideMark(initWith: cutoutView, bodyViewClass: BodyViewStyleSwitchUserGuide.self)
            markFirst.lazyCutoutPath = lazycutoutPathOne
            markFirst.cutoutView = cutoutView
            markFirst.bodyViewParamStyle = .switchUserGuideView(contentTextOne, buttonTextOne)

            var markSecond = GuideMark(initWith: {nil}, bodyViewClass: BodyViewStyleSwitchUserGuide.self)
            markSecond.bodyViewParamStyle = .switchUserGuideView(contentTextTwo, buttonTextTwo)
            markSecond.lazyCutoutPath = lazycutoutPathTwo
            markSecond.willStartActionNeedTime = willStart

            marks.append(markFirst)
            marks.append(markSecond)

            GuideInterface.startGuide(bearViewController: bearViewController, marks: marks, backgroundColor: UIColor.ud.rgb("212121").withAlphaComponent(0.3), dismissBlock: dismiss)
        }
    }

    /// show Guide use ChatAnimation and cutout area is cutoutView
    ///
    /// - Parameters:
    ///   - info: Guide's resource eg: LineGuideItemInfo.image size and key
    ///   - preference: some basic preference in Guide's animation location
    ///   - bearViewController: bear viewController
    ///   - guideMarkController: guideMark controller
    ///   - cutoutView: cutout view
    ///   - willStart: What you need to do before guide execution, return value is action time
    ///   - willEnd: What you need to do before guide execution, return value is action time
    ///   - dismiss: What you need to do after the guide disappears
    public static func startChatAnimationGuide(info: LineGuideItemInfo,
                                               preference: ChatAnimationPreference = ChatAnimationPreference(),
                                               bearViewController: UIViewController,
                                               cutoutView: @escaping () -> UIView?,
                                               willStart: (() -> Double)? = nil,
                                               willEnd: (() -> Double)? = nil,
                                               dismiss: (() -> Void)? = nil) {
        var mark = GuideMark(initWith: cutoutView, bodyViewClass: BodyViewStyleChatAnimation.self)
        mark.willStartActionNeedTime = willStart
        mark.willEndActionNeedTime = willEnd
        mark.bodyViewParamStyle = .chatAnimationView(info, preference.offset, preference.startPointOffset)
        if preference.cutoutStyle == .circle {
            if let cutoutview = cutoutView() {
                mark.cutoutCornerRadii = CGSize(width: cutoutview.frame.width / 2, height: cutoutview.frame.height / 2)
            }
        }
        GuideInterface.startGuide(bearViewController: bearViewController, marks: [mark], dismissBlock: dismiss)
    }

    /// show Guide use ChatAnimation and cutout area is cutoutPath => UIBezierPath
    ///
    /// - Parameters:
    ///   - info: Guide's resource eg: LineGuideItemInfo.image size and key
    ///   - preference: some basic preference in Guide's animation location
    ///   - bearViewController: bear viewController
    ///   - guideMarkController: guideMark controller
    ///   - cutoutPath: cutout path
    ///   - willStart: What you need to do before guide execution, return value is action time
    ///   - willEnd: What you need to do before guide execution, return value is action time
    ///   - dismiss: What you need to do after the guide disappears
    public static func startChatAnimationGuide(info: LineGuideItemInfo,
                                               preference: ChatAnimationPreference = ChatAnimationPreference(),
                                               bearViewController: UIViewController,
                                               cutoutPath: UIBezierPath?,
                                               willStart: (() -> Double)? = nil,
                                               willEnd: (() -> Double)? = nil,
                                               dismiss: (() -> Void)? = nil) {
        var mark = GuideMark(initWith: { return nil }, bodyViewClass: BodyViewStyleChatAnimation.self)
        mark.willStartActionNeedTime = willStart
        mark.willEndActionNeedTime = willEnd
        mark.cutoutPath = cutoutPath
        mark.bodyViewParamStyle = .chatAnimationView(info, preference.offset, preference.startPointOffset)
        GuideInterface.startGuide(bearViewController: bearViewController, marks: [mark], dismissBlock: dismiss)
    }

    public static func startFeedUpgradeTeamGuide(titleText: String,
                                                 contentText: String,
                                                 bearViewController: UIViewController,
                                                 cutoutView: @escaping () -> UIView?,
                                                 cutoutPath: UIBezierPath?,
                                                 willStart: (() -> Double)? = nil,
                                                 dismiss: (() -> Void)? = nil) {
        var mark = GuideMark(initWith: cutoutView, bodyViewClass: BodyViewFeedUpgradeTeamGuide.self)
        mark.bodyViewParamStyle = .feedUpgradeTeamGuideView(titleText, contentText)
        mark.cutoutPath = cutoutPath
        mark.cutoutView = cutoutView
        GuideInterface.startGuide(bearViewController: bearViewController, marks: [mark], backgroundColor: UIColor.clear, dismissBlock: dismiss)
    }
}

internal extension UIViewController {
    struct Static {
        static var guideKey = "guideController"
    }
    var guideController: GuideMarksController? {
        get {
            return objc_getAssociatedObject( self, &Static.guideKey ) as? GuideMarksController
        }
        set {
            objc_setAssociatedObject(self, &Static.guideKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
