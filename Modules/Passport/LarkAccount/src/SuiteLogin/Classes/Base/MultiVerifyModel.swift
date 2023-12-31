//
//  MultiVerifyModel.swift
//  LarkAccount
//
//  Created by zhaoKejie on 2023/8/14.
//

import Foundation

typealias MultiVerifyBaseStepInfo = MultiVerifyBaseInfo<PassportStep>

class MultiVerifyBaseInfo<Step: RawRepresentable>: ServerInfo where Step.RawValue == String {

    var flowType: String?
    var usePackageDomain: Bool?
    var nextInString: String?

    let defaultType: MultiVerifyType
    let verifyMobileCodeInfo: VerifyCodeInfo?
    let verffyEmailCodeInfo: VerifyCodeInfo?
    let verifyPwdInfo: VerifyPwdInfo?
    let verifyOtpInfo: VerifyCodeInfo?
    let verifyCodeSpareInfo: VerifyCodeInfo?
    let verifyMoInfo: VerifyMoInfo?
    let verifyFidoInfo: VerifyCommonInfo?
    let verifyGoogleInfo: VerifyCommonInfo?
    let verifyAppleInfo: VerifyCommonInfo?
    let verifyBIDPInfo: VerifyCommonInfo?
    let verifyAuthnMethods: VerifyMethodTable?

    //是否使用本地存储的验证方式
    var enableClientLoginMethodMemory: Bool?
    //返回的时候是否回到 feed 页面;
    //https://meego.bytedance.net/larksuite/issue/detail/2768937?#detail
    let backToFeed: Bool?

//    let defaultVerifyItem: String?

    enum CodingKeys: String, CodingKey {

        case verifyMobileCodeInfo = "verify_code_mobile"
        case verffyEmailCodeInfo = "verify_code_email"
        case verifyPwdInfo = "verify_pwd"
        case verifyOtpInfo = "verify_otp"
        case verifyCodeSpareInfo = "verify_code_spare"
        case verifyMoInfo = "verify_mo"
        case verifyFidoInfo = "verify_fido"
        case verifyGoogleInfo = "verify_google"
        case verifyAppleInfo = "verify_apple"
        case verifyBIDPInfo = "verify_b_idp"
        case verifyAuthnMethods = "verify_authn_methods"
        case defaultType = "default_verify_item"
        case flowType = "flow_type"
        case usePackageDomain = "use_package_domain"
        case backToFeed = "back_to_feed"
        case enableClientLoginMethodMemory = "enable_client_login_method_memory"
    }

}

struct VerifyMethodTable: Codable {
    let title: String?
    let subtitle: String?
    let authMethods: [Menu]

    enum CodingKeys: String, CodingKey {
        case title, subtitle
        case authMethods = "authn_methods"
    }
}

// - MARK: new verify page info

protocol VerifyTypeInfo: ServerInfo, Codable {

    var title: String { get }

    var subtitle: String { get }

    var nextButton: V4ButtonInfo? { get }

    var inputBox: InputInfo? { get }

    var switchButton: V4ButtonInfo? { get }

    var retrieveButton: V4ButtonInfo? { get }

    var flowType: String? { get }

    var usePackageDomain: Bool? { get }

}

struct VerifyCommonInfo: VerifyTypeInfo {

    var nextInString: String?

    var title: String

    var subtitle: String

    var nextButton: V4ButtonInfo?

    var inputBox: InputInfo?

    var switchButton: V4ButtonInfo?

    var retrieveButton: V4ButtonInfo?

    var flowType: String?

    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subtitle = "subtitle"
        case nextButton = "next_button"
        case inputBox = "input_box"
        case retrieveButton = "retrieve_button"
        case switchButton = "switch_button"
        case usePackageDomain = "use_package_domain"
        case flowType = "flow_type"
    }

}

struct VerifyListInfo: Codable {

    var title: String

    var subtitle: String

}

struct VerifyCodeInfo: VerifyTypeInfo {

    var nextInString: String?

    var title: String

    var subtitle: String

    var nextButton: V4ButtonInfo?

    var inputBox: InputInfo?

    var switchButton: V4ButtonInfo?

    var retrieveButton: V4ButtonInfo?

    var flowType: String?

    var usePackageDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case retrieveButton = "retrieve_button"
        case title = "title"
        case subtitle = "subtitle"
        case nextButton = "next_button"
        case inputBox = "input_box"
        case switchButton = "switch_button"
        case usePackageDomain = "use_package_domain"
        case flowType = "flow_type"
    }
}

struct VerifyPwdInfo: VerifyTypeInfo {

    var nextInString: String?

    var title: String

    var subtitle: String

    var nextButton: V4ButtonInfo?

    var inputBox: InputInfo?

    var switchButton: V4ButtonInfo?

    var retrieveButton: V4ButtonInfo?

    var flowType: String?

    var usePackageDomain: Bool?

    let rsaInfo: RSAInfo

    enum CodingKeys: String, CodingKey {
        case rsaInfo = "rsa_info"
        case title = "title"
        case subtitle = "subtitle"
        case nextButton = "next_button"
        case inputBox = "input_box"
        case switchButton = "switch_button"
        case retrieveButton = "retrieve_button"
        case usePackageDomain = "use_package_domain"
        case flowType = "flow_type"
    }

}

struct VerifyMoInfo: VerifyTypeInfo {

    var nextInString: String?

    var title: String

    var subtitle: String

    var nextButton: V4ButtonInfo?

    var inputBox: InputInfo?

    var switchButton: V4ButtonInfo?

    var retrieveButton: V4ButtonInfo?

    var flowType: String?

    var usePackageDomain: Bool?

    let sendMoButton: V4ButtonInfo?

    let moTextList: [moTextBox]?

    enum CodingKeys: String, CodingKey {
        case sendMoButton = "send_mo_button"
        case moTextList = "mo_text"
        case title = "title"
        case subtitle = "subtitle"
        case nextButton = "next_button"
        case inputBox = "input_box"
        case switchButton = "switch_button"
        case retrieveButton = "retrieve_button"
        case usePackageDomain = "use_package_domain"
        case flowType = "flow_type"
    }

}

