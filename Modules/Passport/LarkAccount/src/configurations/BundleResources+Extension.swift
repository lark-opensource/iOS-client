//
//  BundleResouces+extension.swift
//  LarkAccount
//
//  Created by bytedance on 2021/5/28.
//

import Foundation
import LarkResource
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignIcon
import LarkIllustrationResource
import LarkAppResources
import UniverseDesignEmpty

extension BundleResources {
    class PassportDynamic {

        static let default_avatar = UIImage.dynamic(light: Resource.V3.default_avatar, dark: Resource.V3.default_avatar_dark)

        static let user_center_create = Resource.UserCenter.user_center_create

        static let user_center_join = Resource.UserCenter.user_center_join

        static let user_center_personal_use = Resource.UserCenter.user_center_personal_use

        static let checkbox_selected = UIImage.dynamic(light: Resource.V3.checkbox_selected, dark: Resource.V3.checkbox_selected_dark)
    }

    class UDIconResources {
        public static let closeOutlined = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
        public static let refreshOutlined = UDIcon.refreshOutlined
        public static let infoOutlined = UDIcon.getIconByKey(.infoOutlined, size: CGSize(width: 16, height: 16))
        // arrow
        public static let leftOutlined = UDIcon.getIconByKey(.leftOutlined, size: CGSize(width: 24, height: 24))
        public static let rightBoldOutlined = UDIcon.getIconByKey(.rightBoldOutlined, size: CGSize(width: 16, height: 16))
        public static let downBoldOutlined = UDIcon.getIconByKey(.downBoldOutlined, size: CGSize(width: 16, height: 16))
        public static let upBoldOutlined = UDIcon.getIconByKey(.upBoldOutlined, size: CGSize(width: 16, height: 16))
        public static let mailOutlined = UDIcon.getIconByKey(.mailOutlined, iconColor: UDColor.colorfulOrange, size: CGSize(width: 24, height: 24))
        public static let cellphoneOutlined = UDIcon.getIconByKey(.cellphoneOutlined, iconColor: UDColor.primaryContentDefault, size: CGSize(width: 24, height: 24))
        public static let lockOutlined = UDIcon.getIconByKey(.lockOutlined, iconColor: UDColor.W600, size: CGSize(width: 24, height: 24))
        public static let safePassOutlined = UDIcon.getIconByKey(.safePassOutlined, iconColor: UDColor.colorfulGreen, size: CGSize(width: 24, height: 24))
        public static let fidoOutlined = UDIcon.getIconByKey(.fidoOutlined, iconColor: UDColor.T400, size: CGSize(width: 24, height: 24))
        public static let otpOutLined = UDIcon.getIconByKey(.otpOutlined, iconColor: UDColor.I500, size: CGSize(width: 24, height: 24))
        // public static let msgcardRectangleOutlined = UDIcon.getIconByKey(.msgcardRectangleOutlined, size: CGSize(width: 16, height: 16))

    }

    class LarkIllustrationResources {
        public static let initializationVibeWelcome = LarkIllustrationResource.Resources.initializationVibeWelcome
        public static let specializedAdminCertification = LarkIllustrationResource.Resources.specializedAdminCertification
        public static let imSpecializedPassportSignInPc = LarkIllustrationResource.Resources.imSpecializedPassportSignInPc
        public static let initializationFunctionEmail = LarkIllustrationResource.Resources.initializationFunctionEmail
    }

    class AppResourceLogo {
      public static var logo: UIImage {
          AppResources.ios_icon
      }
    }
}

// MARK: - 扩展UDColor，自定义token
extension UDComponentsExtension where BaseType == UIColor {
    static var bgLogin: UIColor {
        return UIColor.ud.bgBody //UIColor.ud.N00 & UIColor.ud.N00
    }

    static var gradientTop: UIColor {
        return UIColor.ud.rgb("#DFE9FF") & UIColor.ud.rgb("#192031")
    }

    static var gradientBottom: UIColor {
        return UIColor.ud.rgb("#FFFFFF").withAlphaComponent(0) & UIColor.ud.rgb("#191A1C")
    }
}
