//Warning: Do Not Edit It!
//Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
//Toolchains For EE, be fast
/*
*
*
*  ______ ______ _____        __
* |  ____|  ____|_   _|      / _|
* | |__  | |__    | |  _ __ | |_ _ __ __ _
* |  __| |  __|   | | | '_ \|  _| '__/ _` |
* | |____| |____ _| |_| | | | | | | | (_| |
* |______|______|_____|_| |_|_| |_|  \__,_|
*
*
*/

import Foundation
import UIKit

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

//swiftlint:disable all
final class BundleResources {
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
    final class LarkIllustrationResource {
        static let ccmOnboardingHorizontalMobile = BundleResources.image(named: "ccmOnboardingHorizontalMobile")
        static let ccmOnboardingWelcomeSheetMobile = BundleResources.image(named: "ccmOnboardingWelcomeSheetMobile")
        static let emailInitializationFunctionWelcomeAndLink = BundleResources.image(named: "emailInitializationFunctionWelcomeAndLink")
        static let imInitializationFunctionNoSubscriptionContent = BundleResources.image(named: "imInitializationFunctionNoSubscriptionContent")
        static let imSpecializedAddTeamMembers = BundleResources.image(named: "imSpecializedAddTeamMembers")
        static let imSpecializedAllowAccessToAddressBook = BundleResources.image(named: "imSpecializedAllowAccessToAddressBook")
        static let imSpecializedGuidePosting = BundleResources.image(named: "imSpecializedGuidePosting")
        static let imSpecializedNotificationClosed = BundleResources.image(named: "imSpecializedNotificationClosed")
        static let imSpecializedPassportSignInPc = BundleResources.image(named: "imSpecializedPassportSignInPc")
        static let imSpecializedUpgradeToATeam = BundleResources.image(named: "imSpecializedUpgradeToATeam")
        static let initial = BundleResources.image(named: "initial")
        static let initializationFunctionCalendar = BundleResources.image(named: "initializationFunctionCalendar")
        static let initializationFunctionCcm = BundleResources.image(named: "initializationFunctionCcm")
        static let initializationFunctionEmail = BundleResources.image(named: "initializationFunctionEmail")
        static let initializationFunctionIm = BundleResources.image(named: "initializationFunctionIm")
        static let initializationFunctionOpenPlatform = BundleResources.image(named: "initializationFunctionOpenPlatform")
        static let initializationFunctionVc = BundleResources.image(named: "initializationFunctionVc")
        static let initializationVibeCooperation = BundleResources.image(named: "initializationVibeCooperation")
        static let initializationVibeEfficientJoyful = BundleResources.image(named: "initializationVibeEfficientJoyful")
        static let initializationVibeWelcome = BundleResources.image(named: "initializationVibeWelcome")
        static let initializationFunctionSensor = BundleResources.image(named: "initializationFunctionSensor")
        static let initializationFunctionTelephoneconference = BundleResources.image(named: "initializationFunctionTelephoneconference")
        static let passportInitializationFunctionInvite = BundleResources.image(named: "passportInitializationFunctionInvite")
        static let specializedAdminCertification = BundleResources.image(named: "specializedAdminCertification")
        static let specializedEmailDisplayOrderSettingBottom = BundleResources.image(named: "specializedEmailDisplayOrderSettingBottom")
        static let specializedEmailDisplayOrderSettingTop = BundleResources.image(named: "specializedEmailDisplayOrderSettingTop")
        static let specializedEmailLayoutListMode = BundleResources.image(named: "specializedEmailLayoutListMode")
        static let specializedEmailLayoutPreviewMode = BundleResources.image(named: "specializedEmailLayoutPreviewMode")
        static let specializedPassportIpadSignIn = BundleResources.image(named: "specializedPassportIpadSignIn")
        static let specializedPassportPcSignIn = BundleResources.image(named: "specializedPassportPcSignIn")
        static let specializedPassportUploadPositive = BundleResources.image(named: "specializedPassportUploadPositive")
        static let vcOnboardingMinutesMobile = BundleResources.image(named: "vcOnboardingMinutesMobile")
        static let vcOnboardingMinutesPc = BundleResources.image(named: "vcOnboardingMinutesPc")
        static let vcOnboardingSuperimposedPortraitMobile = BundleResources.image(named: "vcOnboardingSuperimposedPortraitMobile")
        static let vcOnboardingSuperimposedPortraitPc = BundleResources.image(named: "vcOnboardingSuperimposedPortraitPc")
        static let vcSpecializedCopylink = BundleResources.image(named: "vcSpecializedCopylink")
        static let vcSpecializedNoContent = BundleResources.image(named: "vcSpecializedNoContent")
        static let vcSpecializedNoWifi = BundleResources.image(named: "vcSpecializedNoWifi")
        static let vcSpecializedOnboardingMinutesMobile = BundleResources.image(named: "vcSpecializedOnboardingMinutesMobile")
        static let vcSpecializedOnboardingMinutesPc = BundleResources.image(named: "vcSpecializedOnboardingMinutesPc")
        static let vcSpecializedOnboardingSuperimposedPortraitMobile = BundleResources.image(named: "vcSpecializedOnboardingSuperimposedPortraitMobile")
        static let vcSpecializedOnboardingSuperimposedPortraitPc = BundleResources.image(named: "vcSpecializedOnboardingSuperimposedPortraitPc")
        static let vcSpecializedPasteIntoObs = BundleResources.image(named: "vcSpecializedPasteIntoObs")
        static let vcSpecializedStartStreaming = BundleResources.image(named: "vcSpecializedStartStreaming")
        static let vcSpecializedStreamingSuccessfully = BundleResources.image(named: "vcSpecializedStreamingSuccessfully")
        static let specializedCtaBannerMobile = BundleResources.image(named: "specializedCtaBannerMobile")
    }

}
//swiftlint:enable all
