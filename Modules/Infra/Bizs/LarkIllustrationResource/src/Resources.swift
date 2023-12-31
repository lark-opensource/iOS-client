import Foundation
import UIKit

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

//swiftlint:disable all
open class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkIllustrationResource.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkIllustrationResourceBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    public static let ccmOnboardingHorizontalMobile = BundleResources.LarkIllustrationResource.ccmOnboardingHorizontalMobile
    public static let ccmOnboardingWelcomeSheetMobile = BundleResources.LarkIllustrationResource.ccmOnboardingWelcomeSheetMobile
    public static let emailInitializationFunctionWelcomeAndLink = BundleResources.LarkIllustrationResource.emailInitializationFunctionWelcomeAndLink
    public static let imInitializationFunctionNoSubscriptionContent = BundleResources.LarkIllustrationResource.imInitializationFunctionNoSubscriptionContent
    public static let imSpecializedAddTeamMembers = BundleResources.LarkIllustrationResource.imSpecializedAddTeamMembers
    public static let imSpecializedAllowAccessToAddressBook = BundleResources.LarkIllustrationResource.imSpecializedAllowAccessToAddressBook
    public static let imSpecializedGuidePosting = BundleResources.LarkIllustrationResource.imSpecializedGuidePosting
    public static let imSpecializedNotificationClosed = BundleResources.LarkIllustrationResource.imSpecializedNotificationClosed
    public static let imSpecializedPassportSignInPc = BundleResources.LarkIllustrationResource.imSpecializedPassportSignInPc
    public static let imSpecializedUpgradeToATeam = BundleResources.LarkIllustrationResource.imSpecializedUpgradeToATeam
    public static let initial = BundleResources.LarkIllustrationResource.initial
    public static let initializationFunctionCalendar = BundleResources.LarkIllustrationResource.initializationFunctionCalendar
    public static let initializationFunctionCcm = BundleResources.LarkIllustrationResource.initializationFunctionCcm
    public static let initializationFunctionEmail = BundleResources.LarkIllustrationResource.initializationFunctionEmail
    public static let initializationFunctionIm = BundleResources.LarkIllustrationResource.initializationFunctionIm
    public static let initializationFunctionOpenPlatform = BundleResources.LarkIllustrationResource.initializationFunctionOpenPlatform
    public static let initializationFunctionVc = BundleResources.LarkIllustrationResource.initializationFunctionVc
    public static let initializationVibeCooperation = BundleResources.LarkIllustrationResource.initializationVibeCooperation
    public static let initializationVibeEfficientJoyful = BundleResources.LarkIllustrationResource.initializationVibeEfficientJoyful
    public static let initializationVibeWelcome = BundleResources.LarkIllustrationResource.initializationVibeWelcome
    public static let initializationFunctionSensor = BundleResources.LarkIllustrationResource.initializationFunctionSensor
    public static let initializationFunctionTelephoneconference = BundleResources.LarkIllustrationResource.initializationFunctionTelephoneconference
    public static let passportInitializationFunctionInvite = BundleResources.LarkIllustrationResource.passportInitializationFunctionInvite
    public static let specializedAdminCertification = BundleResources.LarkIllustrationResource.specializedAdminCertification
    public static let specializedEmailDisplayOrderSettingBottom = BundleResources.LarkIllustrationResource.specializedEmailDisplayOrderSettingBottom
    public static let specializedEmailDisplayOrderSettingTop = BundleResources.LarkIllustrationResource.specializedEmailDisplayOrderSettingTop
    public static let specializedEmailLayoutListMode = BundleResources.LarkIllustrationResource.specializedEmailLayoutListMode
    public static let specializedEmailLayoutPreviewMode = BundleResources.LarkIllustrationResource.specializedEmailLayoutPreviewMode
    public static let specializedPassportIpadSignIn = BundleResources.LarkIllustrationResource.specializedPassportIpadSignIn
    public static let specializedPassportPcSignIn = BundleResources.LarkIllustrationResource.specializedPassportPcSignIn
    public static let specializedPassportUploadPositive = BundleResources.LarkIllustrationResource.specializedPassportUploadPositive
    public static let vcSpecializedOnboardingMinutesMobile = BundleResources.LarkIllustrationResource.vcSpecializedOnboardingMinutesMobile
    public static let vcSpecializedOnboardingMinutesPc = BundleResources.LarkIllustrationResource.vcSpecializedOnboardingMinutesPc
    public static let vcSpecializedCopylink = BundleResources.LarkIllustrationResource.vcSpecializedCopylink
    public static let vcSpecializedNoContent = BundleResources.LarkIllustrationResource.vcSpecializedNoContent
    public static let vcSpecializedNoWifi = BundleResources.LarkIllustrationResource.vcSpecializedNoWifi
    public static let vcOnboardingMinutesMobile = BundleResources.LarkIllustrationResource.vcOnboardingMinutesMobile
    public static let vcOnboardingMinutesPc = BundleResources.LarkIllustrationResource.vcOnboardingMinutesPc
    public static let vcOnboardingSuperimposedPortraitMobile = BundleResources.LarkIllustrationResource.vcOnboardingSuperimposedPortraitMobile
    public static let vcOnboardingSuperimposedPortraitPc = BundleResources.LarkIllustrationResource.vcOnboardingSuperimposedPortraitPc
    public static let vcSpecializedOnboardingSuperimposedPortraitMobile = BundleResources.LarkIllustrationResource.vcSpecializedOnboardingSuperimposedPortraitMobile
    public static let vcSpecializedOnboardingSuperimposedPortraitPc = BundleResources.LarkIllustrationResource.vcSpecializedOnboardingSuperimposedPortraitPc
    public static let vcSpecializedPasteIntoObs = BundleResources.LarkIllustrationResource.vcSpecializedPasteIntoObs
    public static let vcSpecializedStartStreaming = BundleResources.LarkIllustrationResource.vcSpecializedStartStreaming
    public static let specializedCtaBannerMobile = BundleResources.LarkIllustrationResource.specializedCtaBannerMobile
}
//swiftlint:enable all