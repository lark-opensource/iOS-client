// Warning: Do Not Edit It!
// Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
// Toolchains For EE, be fast
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
        if let image: UIImage = ResourceManager.get(key: "LarkAccount.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkAccountBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    class LarkAccount {
        static let pwd_ClosePreview = BundleResources.image(named: "pwd_ClosePreview")
        static let pwd_Preview = BundleResources.image(named: "pwd_Preview")
        class AccountSafety {
            static let pc_icon = BundleResources.image(named: "pc_icon")
            static let phone_icon = BundleResources.image(named: "phone_icon")
            static let web_icon = BundleResources.image(named: "web_icon")
        }
        class Common {
            static let auth_logo_frame = BundleResources.image(named: "auth_logo_frame")
        }
        class EnterpriseLogin {
            static let enterprise_login_icon = BundleResources.image(named: "enterprise_login_icon")
            static let enterprise_login_icon_highlighted = BundleResources.image(named: "enterprise_login_icon_highlighted")
        }
        class SSOverify {
            static let app_connector = BundleResources.image(named: "app_connector")
            static let sso_close_btn = BundleResources.image(named: "sso_close_btn")
            static let sso_mask_close = BundleResources.image(named: "sso_mask_close")
            static let sso_success_tip = BundleResources.image(named: "sso_success_tip")
        }
        class TeamConversion {
            static let join_tenant_review_bg_left = BundleResources.image(named: "join_tenant_review_bg_left")
            static let join_tenant_review_bg_right = BundleResources.image(named: "join_tenant_review_bg_right")
        }
        class UserCenter {
            static let user_center_create = BundleResources.image(named: "user_center_create")
            static let user_center_create_dark = BundleResources.image(named: "user_center_create_dark")
            static let user_center_join = BundleResources.image(named: "user_center_join")
            static let user_center_join_dark = BundleResources.image(named: "user_center_join_dark")
            static let user_center_personal_use = BundleResources.image(named: "user_center_personal_use")
            static let user_center_personal_use_dark = BundleResources.image(named: "user_center_personal_use_dark")
        }
        class V3 {
            static let appleId = BundleResources.image(named: "appleId")
            static let blue_check = BundleResources.image(named: "blue_check")
            static let checkbox = BundleResources.image(named: "checkbox")
            static let checkbox_disable = BundleResources.image(named: "checkbox_disable")
            static let checkbox_selected = BundleResources.image(named: "checkbox_selected")
            static let checkbox_selected_dark = BundleResources.image(named: "checkbox_selected_dark")
            static let close_dark_gray = BundleResources.image(named: "close_dark_gray")
            static let create_tenant = BundleResources.image(named: "create_tenant")
            static let default_avatar = BundleResources.image(named: "default_avatar")
            static let default_avatar_dark = BundleResources.image(named: "default_avatar_dark")
            static let googleAccount = BundleResources.image(named: "googleAccount")
            static let icon_sso_outlined_24 = BundleResources.image(named: "icon_sso_outlined_24")
            static let idpAccount = BundleResources.image(named: "idpAccount")
            static let join_tenant_input_team_code = BundleResources.image(named: "join_tenant_input_team_code")
            static let join_tenant_scan_qrcode = BundleResources.image(named: "join_tenant_scan_qrcode")
            static let lan_arrow = BundleResources.image(named: "lan_arrow")
            static let lan_icon = BundleResources.image(named: "lan_icon")
            static let login_apple_logo = BundleResources.image(named: "login_apple_logo")
            static let login_google_logo = BundleResources.image(named: "login_google_logo")
            static let otp_icon = BundleResources.image(named: "otp_icon")
            static let qrlogin_scanned = BundleResources.image(named: "qrlogin_scanned")
        }
        class V4 {
            static let tenant_info_background_default = BundleResources.image(named: "tenant_info_background_default")
            static let v4_create_tenant = BundleResources.image(named: "v4_create_tenant")
            static let v4_create_user = BundleResources.image(named: "v4_create_user")
            static let v4_login_new = BundleResources.image(named: "v4_login_new")
            static let v4_register_new = BundleResources.image(named: "v4_register_new")
        }
    }

}
//swiftlint:enable all
