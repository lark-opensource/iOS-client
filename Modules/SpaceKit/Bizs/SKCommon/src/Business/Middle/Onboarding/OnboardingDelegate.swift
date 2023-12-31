// 
// Created by duanxiaochen.7 on 2019/11/13.
// Affiliated with SpaceKit.
// 
// Description: OnboardingDelegate is the root protocol of all onboarding delegate.
// This file also aggregates all onboarding delegates.

import UIKit


public protocol OnboardingDelegate: AnyObject {

    /// This method will be called if the administrator has configured a blocklist in Mina that contains this onboarding item.
    ///
    /// If this method is called, then onboarding view will definitely not be displayed.
    ///
    /// The default implementation is doing nothing.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingDisabledInMinaConfiguration(for id: OnboardingID)

    /// This method will be called if someone tells the onboarding manager to temporarily reject all onboarding tasks.
    ///
    /// If this method is called, then onboarding view will definitely not be displayed.
    /// By calling
    /// ```
    /// OnboardingManager.shared.setTemporarilyRejectsUpcomingOnboardings()
    /// ```
    /// you can stop the manager from showing all upcoming onboardings.
    /// The default implementation is doing nothing.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingManagerRejectedThisTime(_ id: OnboardingID)

    /// This method will be called if the previous shown onboarding has designated an onboarding item to show
    /// but this onboarding does not have a matching ID.
    ///
    /// - Parameters:
    ///   - id: The `ID` of the onboarding item planned to show.
    ///   - expectedID: The `ID` of the expected onboarding item to show set by the previous finished onboarding.
    func onboardingNotExpected(for id: OnboardingID, expecting expectedID: OnboardingID)

    /// This method will be called if the onboarding item has already been shown.
    ///
    /// If this method is called, then onboarding view will definitely not be displayed. Because an onboarding will **NOT** be shown twice.
    ///
    /// The default implementation is doing nothing.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingAlreadyFinished(_ id: OnboardingID)

    /// This method will be called before the onboarding is displayed by the manager if it has dependencies that are not displayed yet.
    ///
    /// If this method is called, then onboarding view will definitely not be displayed.
    ///
    /// The default implementation is doing nothing.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingDependenciesUnfinished(for id: OnboardingID)

    /// This method will be called if the onboarding can't be displayed by the manager because
    /// data source failed to provide valid data for generating an onboarding view.
    ///
    /// If this method is called, then onboarding view will definitely not be displayed.
    ///
    /// The default implementation is doing nothing.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingMaterialNotEnough(for id: OnboardingID)

    /// This method will be called when the onboarding manager has just registered the onboarding
    /// task. Note that registering does not lead to immediate display of onboardings. It just means
    /// the task is pushed to the queue. It may take a while for the onboarding to be shown.
    ///
    /// The default implementation is doing nothing.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingDidRegister(_ id: OnboardingID)

    /// This method wil be called before the view is added to the view hierarchy.
    /// You can add other accessory views such as additional animations to the view.
    /// The added subviews will disappear along with the onboaring view itself.
    ///
    /// - Parameters:
    ///   - view: The view which is about to show.
    ///   - id: The `ID` of the onboarding item.
    func onboardingWillAttach(view: UIView, for id: OnboardingID)

    /// This method will be called after the onboarding item did appear but the user has not yet interacted with it.
    ///
    /// This method will be called before `onboardingAcknowledge(_:)` and `skip(_:)`.
    ///
    /// The default implementation is doing nothing.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingDidAppear(_ id: OnboardingID)

    /// This method will be called **before** the onboarding window's size is changed when showing, leading to removing the onboarding view.
    /// Whether the onboarding is acknowledged or skipped is determined by your return of `OnboardingStyle.DisappearBehavior`.
    /// This method can be triggered by an orientation change or an split view size changing event while multitasking on an iPad.
    ///
    /// The default inplementation is doing nothing and returning `.acknowledge`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingWindowSizeWillChange(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior

    /// This method gets called only when you have explicitly set the onboarding to be asynchronous and you just
    /// called `targetView(for:updatedExistence:)` to notice that the target view just disappeared.
    /// Whether the asynchronous onboarding is acknowledged or skipped is determined by your return of
    /// `OnboardingStyle.DisappearBehavior`.
    ///
    /// The default inplementation is doing nothing and returning `.acknowledge`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingTargetViewDidDisappear(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior

    /// This method will be called after the user has touched outside of the onboarding bubble. This will be called **before** the onboarding
    /// view disappears.
    /// Whether the onboarding is acknowledged or skipped is determined by your return of `OnboardingStyle.DisappearBehavior`. Thus this is
    /// also called **before** your `onboardingAcknowledge(_:)` and `onboardingSkip(_:)`.
    ///
    /// The default inplementation is doing nothing and returning `.acknowledge`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingDidTapBubbleOutside(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior

    /// This method will be called after the user acknowledged.
    ///
    /// The user acknowledges the onboarding by touching down on the screen.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingAcknowledge(_ id: OnboardingID)

    /// This method will be called after the user skipped the current and following onboardings.
    ///
    /// For `.flow` typed onboarding, the user skips the onboardings by hitting the skip button whose text color is dimmed.
    /// For `.card` typed onboarding, the user hits the "X" button at the upper right corner of the card.
    /// The default implementation is doing nothing.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingSkip(_ id: OnboardingID)
    
    func onboardingSwipeDisappearCallBack(_ id: OnboardingID, sender: UIPanGestureRecognizer)
}

public extension OnboardingDelegate {

    func onboardingDisabledInMinaConfiguration(for id: OnboardingID) {
    }

    func onboardingManagerRejectedThisTime(_ id: OnboardingID) {
    }

    func onboardingNotExpected(for id: OnboardingID, expecting expectedID: OnboardingID) {
    }

    func onboardingAlreadyFinished(_ id: OnboardingID) {
    }

    func onboardingDependenciesUnfinished(for id: OnboardingID) {
    }

    func onboardingMaterialNotEnough(for id: OnboardingID) {
    }

    func onboardingDidRegister(_ id: OnboardingID) {
    }

    func onboardingWillAttach(view: UIView, for id: OnboardingID) {
    }

    func onboardingDidAppear(_ id: OnboardingID) {
    }

    func onboardingWindowSizeWillChange(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        return .acknowledge
    }

    func onboardingTargetViewDidDisappear(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        return .acknowledge
    }

    func onboardingDidTapBubbleOutside(for id: OnboardingID) -> OnboardingStyle.DisappearBehavior {
        return .acknowledge
    }

    func onboardingSkip(_ id: OnboardingID) {
    }
    
    func onboardingSwipeDisappearCallBack(_ id: OnboardingID, sender: UIPanGestureRecognizer) {
    }
}
