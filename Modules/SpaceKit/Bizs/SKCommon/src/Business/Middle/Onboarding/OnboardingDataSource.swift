// 
// Created by duanxiaochen.7 on 2019/11/13.
// Affiliated with SpaceKit.
// 
// Description: OnboardingDataSource is the root protocol of all onboarding data sources.
// This file also aggregates all onboarding data sources.

import RxSwift
import Lottie
import SKUIKit
import SKResource

public typealias OnboardingFlowDataSources = OnboardingDataSource & OnboardingFlowDataSource
public typealias OnboardingCardDataSources = OnboardingDataSource & OnboardingCardDataSource


public protocol OnboardingDataSource: AnyObject {

    /// The type of the onboarding view. Cases are `.text`, `.flow` and `.card`.
    ///
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingType(of id: OnboardingID) -> OnboardingType

    /// If the onboarding should show depending on a target view's appearance.
    ///
    /// If you return `true`, you must call `targetView(for:updatedExistence:)` to notify the onboarding manager
    /// whether a target view has appeared or disappeared.
    ///
    /// The default return is `false`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingIsAsynchronous(for id: OnboardingID) -> Bool

    /// Whether can the onboarding view cqontroller rotate to another interface orientation.
    ///
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingSupportedInterfaceOrientations(for id: OnboardingID) -> UIInterfaceOrientationMask

    /// The behavior when the user touches down on transparent region of the onboarding view **outside the onboarding bubble**.
    ///
    /// For `.text` typed onboardings, you can switch between `.disappearWithoutPenetration` and `.disappearAndPenetrate` to
    /// obtain a modal/non-modal behavior when touching the screen.
    ///
    /// For `.flow` typed onboardings with mask on, you can switch between `.nothing`, `.disappearWithoutPenetration` and `.disappearAndPenetrate` to
    /// configure the transparent focus area touch action. If you opt out of the mask, the penetrable area extends to the window bounds.
    ///
    /// For `.card` typed onboardings, you can only use `.nothing` to force an interaction with the card.
    ///
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingTapBubbleOutsideBehavior(of id: OnboardingID) -> OnboardingStyle.TapBubbleOutsideBehavior

    /// In what way the onboarding view is going to disppear.
    ///
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingDisappearStyle(of id: OnboardingID) -> OnboardingStyle.DisappearStyle

    /// The container view controller that contains the onboarding view controller and hosts the onboarding view.
    ///
    /// OnboardingManager will add the onboarding view to the root `view` of this `hostViewController`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingHostViewController(for id: OnboardingID) -> UIViewController

    /// The image at the top of the onboarding bubble or card.
    ///
    /// The default return is `nil`. You may also set `lottieView` instead.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingImage(for id: OnboardingID) -> UIImage?

    /// The lottie view at the top of the onboarding bubble or card.
    ///
    /// The default return is `nil`. You may also set `image` instead.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingLottieView(for id: OnboardingID) -> LOTAnimationView?

    /// The title. Explicitly set this to `nil` if you are sure that this onboarding item has no title.
    ///
    /// The default return is `nil`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingTitle(for id: OnboardingID) -> String?

    /// The subtitle.
    ///
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingHint(for id: OnboardingID) -> String

    /// The frame of the interested view which the onboarding bubble is pointing to.
    /// Make sure the coordination system is `hostViewController` based, that is, the origin is that
    /// of the `hostViewController.view`.
    ///
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingTargetRect(for id: OnboardingID) -> CGRect

    /// The direction of the onboarding view pointing to the target you specified.
    ///
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingArrowDirection(for id: OnboardingID) -> OnboardingStyle.ArrowDirection

    /// If `false`, onboarding manager will not be checking the dependencies of this onboarding item before displaying.
    ///
    /// The default return is `true`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingShouldCheckDependencies(for id: OnboardingID) -> Bool

    /// The dependencies of a certain onboarding item.
    ///
    /// The default return is `[]`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingDependencies(for id: OnboardingID) -> [OnboardingID]

    /// If you are showing a series of onboardings and you want to make sure the series get played strictly in order,
    /// set this to the ID of the following onboarding to be displayed. The manager will record this ID and
    /// double check if the next onboarding task has this ID.
    ///
    /// If set, it only takes effect **ONCE**.
    /// That is to say, the manager will check the next onboarding item's ID, but no matter the result, it won't check it
    /// again for the following onboardings.
    ///
    /// The default return is `nil`. Set this to `nil` if you don't want to block other businesses' onboardings
    /// or it is the end of the series.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingNextID(for id: OnboardingID) -> OnboardingID?
    
    /// if you want to customize swipe gesture remove onboadring, can use the method
    /// just for text onboarding type
    func onboardingSwipeGestureTapCount(for id: OnboardingID) -> Int?
}

public extension OnboardingDataSource {

    func onboardingIsAsynchronous(for id: OnboardingID) -> Bool { false }

    func onboardingSupportedInterfaceOrientations(for id: OnboardingID) -> UIInterfaceOrientationMask {
        if SKDisplay.pad { return [.all] }
        return [.portrait]
    }

    func onboardingTapBubbleOutsideBehavior(of id: OnboardingID) -> OnboardingStyle.TapBubbleOutsideBehavior {
        switch onboardingType(of: id) {
        case .text: return .disappearAndPenetrate
        case .flow: return .disappearWithoutPenetration
        case .card: return .nothing
        }
    }

    func onboardingDisappearStyle(of id: OnboardingID) -> OnboardingStyle.DisappearStyle { .immediatelyAfterUserInteraction }

    func onboardingImage(for id: OnboardingID) -> UIImage? { nil }

    func onboardingLottieView(for id: OnboardingID) -> LOTAnimationView? { nil }

    func onboardingTitle(for id: OnboardingID) -> String? { nil }

    func onboardingShouldCheckDependencies(for id: OnboardingID) -> Bool { true }

    func onboardingDependencies(for id: OnboardingID) -> [OnboardingID] { [] }

    func onboardingNextID(for id: OnboardingID) -> OnboardingID? { nil }
    
    func onboardingBubbleCustomMaxSize(for id: OnboardingID) -> CGFloat? { nil }
    
    func onboardingSwipeGestureTapCount(for id: OnboardingID) -> Int? { nil }
}









public protocol OnboardingFlowDataSource: AnyObject {

    /// The index string at the bottom left corner in the form of "2/3". 2 is the current index, 3 is the total count.
    ///
    /// The default return is `nil`, meaning that this onboarding item has no pagination.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingIndex(for id: OnboardingID) -> String?

    /// The text on the skip button whose foreground color is white.
    ///
    /// Explicitly set this to `nil` if you are sure that this onboarding item has no skip button.
    /// The default return is `BundleI18n.SKResource.Doc_Facade_Skip`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingSkipText(for id: OnboardingID) -> String?

    /// The text on the bottom right button whose background color is white, often written as "Next" or "Got It".
    ///
    /// The default return is `BundleI18n.SKResource.Doc_Facade_Next`.
    /// You may want to use `BundleI18n.SKResource.Onboarding_Got_It` for the last flow onboarding item.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingAckText(for id: OnboardingID) -> String

    /// Whether to display a mask covering the whole screen but exposing only the target rect of interest.
    /// Only for `flow` typed onboardings.
    ///
    /// The default return is `true`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingHasMask(for id: OnboardingID) -> Bool

    /// The style of the cutout oval in the mask which focuses on the button to be introduced.
    ///
    /// The default return is `.roundedRect(4)` where 4 is the corner radius.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingHollowStyle(for id: OnboardingID) -> OnboardingStyle.Hollow

	/// The bleeding width for the cutout oval in the mask which focuses on the button to be introduced.
    ///
    /// This expands the size of the focus area in case where a bar button is focused. You can set it `.zero` if you are
    /// focusing on a table view cell or a negative `CGFloat` value if you want to shrink the focus area.
    ///
	///
	/// The default return is `8`.
	/// - Parameter id: The `ID` of the onboarding item.
	func onboardingBleeding(for id: OnboardingID) -> CGFloat
}

public extension OnboardingFlowDataSource {

    func onboardingIndex(for id: OnboardingID) -> String? { nil }

    func onboardingSkipText(for id: OnboardingID) -> String? { BundleI18n.SKResource.Doc_Facade_Skip }

    func onboardingAckText(for id: OnboardingID) -> String { BundleI18n.SKResource.Doc_Facade_Next }

    func onboardingHasMask(for id: OnboardingID) -> Bool { true }

    func onboardingHollowStyle(for id: OnboardingID) -> OnboardingStyle.Hollow { .roundedRect(4) }

	func onboardingBleeding(for id: OnboardingID) -> CGFloat { 8 }
}








public protocol OnboardingCardDataSource: AnyObject {

    /// The text on the wide white button, often written as "Start Tour".
    ///
    /// The default return is `BundleI18n.SKResource.Doc_Facade_SeeTutorial`.
    /// - Parameter id: The `ID` of the onboarding item.
    func onboardingStartText(for id: OnboardingID) -> String
}

public extension OnboardingCardDataSource {

    func onboardingStartText(for id: OnboardingID) -> String { BundleI18n.SKResource.Doc_Facade_SeeTutorial }
}
