//
//  Debug+V3.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/11/11.
//

import UIKit
import RoundedHUD
import RxSwift
import LarkAccountInterface

// swiftlint:disable force_unwrapping
#if ONE_KEY_LOGIN
extension OneKeyLogin {
    static func mockInit(
        loginService: V3LoginService,
        type: OneKeyLoginType,
        number: String = "+8612345678901",
        service: OneKeyLoginService = .mobile,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = OneKeyLoginViewModel(
            type: type,
            number: number,
            oneKeyService: service,
            service: loginService,
            otherLoginAction: nil,
            context: context
        )
        return OneKeyLoginViewController(vm: vm)
    }
}
#endif

extension DebugFactory {

    public func baseVC(
        title: String,
        detail: String
    ) -> UIViewController {
        let vc = BaseViewController(
            viewModel: V3ViewModel(step: "", stepInfo: V3LoginInfo(nextInString: nil), context: UniContext.placeholder))
        vc.configInfo(title, detail: detail)
        return vc
    }

    public func updatePassword(fromNavigation nav: UINavigationController) {
//        launcher.updatePassword(from: nav) { (vc) in
//            if let vc = vc {
//                nav.pushViewController(vc, animated: true)
//            }
//        }
    }

    public func pushToTeamConversion(fromNavigation nav: UINavigationController) {
        launcher.pushToTeamConversion(
            fromNavigation: nav,
            trackPath: "SuiteLogin_debug"
        )
    }

    public func switchUser(presentingViewController: UIViewController) {
        let currentUser = V3UserInfo(id: "123", name: "", i18nName: nil, active: false, frozen: false, c: nil, avatarUrl: "", avatarKey: "", env: "", unit: nil, tenant: nil, status: nil, tip: nil, bIdp: nil, guest: nil, securityConfig: nil, session: nil, sessions: nil, logoutToken: nil)

        let toUser = V3UserInfo(id: "456", name: "", i18nName: nil, active: false, frozen: false, c: nil, avatarUrl: "", avatarKey: "", env: "", unit: nil, tenant: nil, status: nil, tip: nil, bIdp: nil, guest: nil, securityConfig: nil, session: nil, sessions: nil, logoutToken: nil)
        let context = UniContext.placeholder
        switchUserService.switchTo(userID: toUser.id, complete: nil, context: context)
    }

    public func oneKeyLogin(isRegister: Bool) -> UIViewController? {
        #if ONE_KEY_LOGIN
        return OneKeyLogin.mockInit(
            loginService: loginService,
            type: isRegister ? .register : .login,
            context: UniContext.placeholder
        )
        #else
        return nil
        #endif
    }

    public func credentialList() -> UIViewController {
        return loginService.credentialList(context: UniContext.placeholder)
    }

    public func createTeam() -> UIViewController {
        let dataString = """
            {"title":"Mock Title", "subtitle":"Mock Subtitle", "name": "xxx", "enable_fields": 13, "industry_type_list": [{"i18n":"xxx1", "code": "01", "children":[{"i18n":"xxxA", "code": "01"}]},{"i18n":"xxx2", "code": "02", "children":[{"i18n":"xxxAsdlfjlskdjflsjdlfjsldjflsdjfljsdlfjlsdjflsdjflkjdslfjlk", "code": "01"}]}, {"i18n":"xxx3", "code":"03"}], "staff_size_list": [{"i18n":"xxx", "code":"01"}]}
            """
        do {
            let info = try JSONDecoder().decode(V3CreateTenantInfo.self, from: dataString.data(using: .utf8)!)
            let vm = V3TenantCreateViewModel(step: "tenant_create", createInfo: info, api: loginService.passportAPI, context: UniContext.placeholder)
            return V3TenantCreateViewController(vm: vm)
        } catch {
            print(error)
            return UIViewController()
        }
    }
    
    public func magicLink() -> UIViewController {
        let info = V3MagicLinkInfo(
            nextInString: nil,
            title: "Title",
            subtitle: "Subtilesdfsdfsdfsdfsdfsdfkeworuwoelsdjljflsdkjflskjdflsdj xxx@gmail.com",
            contact: "xxx@gmail.com",
            sourceType: nil,
            tip: "xxxxx"
        )
        return MagicLinkViewController(
            vm: MagicLinkViewModel(
                stepInfo: info,
                context: UniContext.placeholder
            )
        )
    }

    public func joinTenantCode() -> UIViewController {
//        let data: [String: String] = [
//            "title": "Mock Title",
//            "subtitle": "Mock Subtitle",
//            "subtitle_switch_scan_text": "<p>也可<span style=\"color: rgb(51, 112, 255); font-weight: bold;\"><a href=\"//join_tenant_scan\" target=\"_blank\">扫描二维码加入团队</a></span><br></p>"
//            ]
//
//        do {
//            let d = try data.asData()
//            let info = try JSONDecoder().decode(V3JoinTenantCodeInfo.self, from: d)
//            return loginService.createJoinTenantCode(
//                info,
//                additionalInfo: nil,
//                api: loginService.passportAPI,
//                useHUDLoading: false,
//                context: UniContext.placeholder
//            )
//        } catch {
//            print(error)
//            return UIViewController()
//        }
        return UIViewController()
    }

    public func turing() {
//        TuringService.shared.verify { (success) in
//            print("turing service success: \(success)")
//        }
    }

    public func setNameVC() -> UIViewController {
//        let info = V3SetNameInfo(title: "", subtitle: "", nameInput: nil, flowType: "", nextButton: nil)
//        let vm = V3SetNameViewModel(step: "", setNameInfo: info, context: UniContext.placeholder)
//        return V3SetNameViewController(vm: vm)
        return UIViewController()
    }

    public func pendingApprove() -> UIViewController {
//        let vm = V3PendingApproveModel(context: UniContext.placeholder) { (_) in
//        }
//        return V3PendingApproveViewController(vm: vm)
        return UIViewController()
    }

    public func selectUserList() -> UIViewController {
        let button: [String: Any] = [
            "text": "加入团队",
            "action_type": 3
        ]
        let data: [String: Any] = [
            "title": "你可以进入一下团队",
            "join_button": button,
            "register_button": button,
            "flow_key": "fffffffsefef",
            "register_item": [
                "title": "选择操作选择操作选择操作选择操作选择操作选择操作选择操作选择操作选择操作",
                "dispatch_list": [
                    [
                        "text": "创建全新团队",
                        "desc": "为你的团队启用飞书为你的团队启用飞书为你的团队启用飞书为你的团队启用飞书为你的团队启用飞书",
                        "action_type": 6
                    ],
                    [
                        "text": "创建全新团队",
                        "desc": "为你的团队启用飞书为你的团队启用飞书为你的团队启用飞书为你的团队启用飞书为你的团队启用飞书",
                        "action_type": 7
                    ]
                ]
            ],
            "group_list": [
                [
                    "subtitle": "当前手机<strong>+8612345678910</strong>已可以进入以下团队，请选择你要进入的团队",
                    "user_list": [
                        [
                            "status": 0,
                            "type": 0,
                            "user": [
                                "avatar_url": "",
                                "id": "1",
                                "name": "张三",
                                "status": 1,
                                "tenant": [
                                    "icon_url": "",
                                    "name": "字节跳动字节跳动字节跳动字节跳动字节跳动字节跳动字节跳动字节跳动",
                                    "id": "001"
                                ]
                            ]
                        ],
                        [
                            "status": 1,
                            "type": 0,
                            "status_desc": "已封禁",
                            "button": [
                                "text": "申诉"
                            ],
                            "user": [
                                "avatar_url": "",
                                "id": "1",
                                "name": "李四",
                                "status": 1,
                                "tenant": [
                                    "icon_url": "",
                                    "name": "字节跳动字节跳动字节跳动字节跳动字节跳动字节跳动字节跳动字节跳动字",
                                    "id": "001"
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    "subtitle": "当前手机<bold>+86122323523535910</bold>已可以进入以入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下入以下下团队，请选择你要进入的团队",
                    "user_list": [
                        [
                            "status": 2,
                            "type": 0,
                            "status_desc": "已暂停",
                            "user": [
                                "avatar_url": "",
                                "id": "1",
                                "name": "张三",
                                "status": 1,
                                "tenant": [
                                    "icon_url": "",
                                    "name": "字节跳动",
                                    "id": "001"
                                ]
                            ]
                        ],
                        [
                            "status": 3,
                            "type": 0,
                            "status_desc": "新团队",
                            "user": [
                                "avatar_url": "",
                                "id": "1",
                                "name": "试试",
                                "status": 1,
                                "tenant": [
                                    "icon_url": "",
                                    "name": "字节跳动",
                                    "id": "001"
                                ]
                            ]
                        ],
                        [
                            "status": 4,
                            "type": 0,
                            "user": [
                                "avatar_url": "",
                                "id": "1",
                                "name": "李四",
                                "status": 1,
                                "tenant": [
                                    "icon_url": "",
                                    "name": "字节跳动",
                                    "id": "001"
                                ]
                            ]
                        ],
                        [
                            "status": 5,
                            "type": 0,
                            "status_desc": "审核中",
                            "user": [
                                "avatar_url": "",
                                "id": "1",
                                "name": "李四",
                                "status": 1,
                                "tenant": [
                                    "icon_url": "",
                                    "name": "字节跳动",
                                    "id": "001"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        let stepInfo = V3LoginService.jsonToObj(type: V4SelectUserInfo.self, json: data)!
        let vm = V3SelectUserViewModel(step: "", stepInfo: stepInfo, context: UniContext.placeholder)
        return V3SelectUserViewController(vm: vm)
    }

    public func setPassword() -> UIViewController {
        let data: [String: Any] = [
            "title": "设置密码",
            "subtitle": "请设置你的账号密码，密码需同时包含字母和数字，且至少 8 个字符",
            "flow_type": "login",
            "reg_exp": "(?=.*[0-9])(?=.*[a-z])^[0-9A-Za-z]{6,12}$",
            "skip_button": [
                "text": "稍后设置"
            ],
            "next_button": [
                "text": "下一步"
            ],
            "pwd": [
                "placeholder": "请设置密码"
            ],
            "confirm_pwd": [
                "placeholder": "请再次设置密码"
            ]
        ]
        return UIViewController()
//        let stepInfo = V3LoginService.jsonToObj(type: V4SetPwdInfo.self, json: data)!
//        let vm = V4SetPwdViewModel(step: "", setPwdInfo: stepInfo, api: PwdManageAPI(), context: UniContext.placeholder)
//        return V4SetPwdViewController(vm: vm)
    }

    public func recoverAccountCarrier() -> UIViewController {
        let dict: [String: Any] = [
            "rsa_info": [
                "public_key": "",
                "rsa_token": ""
            ],
            "appeal_url": "https://www.feishu.cn"
        ]
        let vm = V3RecoverAccountCarrierViewModel(
            step: PassportStep.recoverAccountCarrier.rawValue,
            api: loginService.passportAPI,
            recoverAccountCarrierInfo: V3LoginService.jsonToObj(type: V3RecoverAccountCarrierInfo.self, json: dict)!,
            from: .login,
            context: UniContext.placeholder
        )
        return V3RecoverAccountCarrierViewController(vm: vm)
    }

    public func authViewController() -> UIViewController {
//        #if LarkAccount_Authorization
//        let vm = SSOBaseViewModel(info: .qrCode("123456789"))
//        let vc = ThirdPartyAuthViewController(
//            vm: vm,
//            authInfo: .init(
//                appName: "扫码大师",
//                subtitle: "请求登录你的飞书账号",
//                scopeTitle: "授权后应用获得以下权限",
//                appIconUrl: "https://sf1-dycdn-tos.pstatp.com/obj/eden-cn/pxvhptnuhd/screenshot-20210301-214432.png",
//                identityTitle: "你将以该身份登录：",
//                permissionScopes: [
//                    .init(key: "个人信息()", text: "个人信息（头像、姓名）", required: true),
//                    .init(key: "dfsfdf", text: "联系信息（手机号、邮箱）", required: true),
//                    .init(key: "fsdjflksdfj", text: "组织信息（企业名称、企业编号）", required: true)
//                ],
//                buttonTitle: "OK")
//        )
//        return vc
//        #else
        return UIViewController()
//        #endif
    }
}

extension DebugFactory {
    func user(id: String) -> AccountUserInfo {
        return AccountUserInfo(
            userID: id,
            tenantID: "",
            name: "",
            enName: "",
            isActive: true,
            isFrozen: false,
            avatarKey: "",
            avatarUrl: "",
            session: "",
            sessions: nil,
            logoutToken: nil,
            tenantCode: "",
            defaultTenantIconUrl: "",
            tenant: nil,
            userEnv: nil,
            userUnit: nil,
            status: nil,
            securityConfig: nil,
            isIdp: nil,
            isGuest: nil,
            upgradeEnabled: nil
        )
    }
}
