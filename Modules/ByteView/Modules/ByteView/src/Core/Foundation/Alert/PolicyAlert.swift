//
//  PolicyAlert.swift
//  ByteView
//
//  Created by 李凌峰 on 2020/3/18.
//

import Foundation
import RxSwift
import RxCocoa
import LarkLocalizations
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting

private let log = Logger.policy

extension LivePrivilege: ChoiceItem {

    static var validCases: [LivePrivilege] {
        return [employee, custom, anonymous]
    }

    public var content: String {
        switch self {
        case .employee:
            return I18n.View_M_PermissionsOnlySameCompany
        case .custom:
            return I18n.View_MV_SpecificViewer_Option
        case .anonymous:
            return I18n.View_MV_AllViewer_Option
        case .other:
            return I18n.View_G_Others
        default:
            return ""
        }
    }
}

enum Policy: Int {

    case privacy = 0
    case userTermsOfService = 1
    case startLivePolicy = 2

    private static func openLink(of policy: Policy, policyUrl: PolicyURL, completion: ((Bool) -> Void)? = nil) {
        // 针对中文特殊处理
        let url: URL?
        let abbreviation = BundleI18n.currentLanguage.localeIdentifier.lowercased()
        let nonChineselanguage = BundleI18n.isChinese() ? Lang.en_US : BundleI18n.currentLanguage
        let nonChineseAbbreviation = nonChineselanguage.localeIdentifier.lowercased()
        let replaceKey = "{key}"
        switch policy {
        case .privacy: // 隐私协议
            let privacyStr = policyUrl.vcPrivacyPolicyUrl.replacingOccurrences(of: replaceKey, with: nonChineseAbbreviation)
            url = URL(string: privacyStr)
        case .userTermsOfService: // 用户协议
            let serviceStr = policyUrl.vcTermsServiceUrl.replacingOccurrences(of: replaceKey, with: nonChineseAbbreviation)
            url = URL(string: serviceStr)
        case .startLivePolicy: // 开播协议
            let liveStr = policyUrl.vcLivePolicyUrl.replacingOccurrences(of: replaceKey, with: abbreviation)
            url = URL(string: liveStr)
        }
        if let url = url {
            log.debug("open policy link: \(policy)")
            completion?(true)
            UIApplication.shared.open(url)
        } else {
            completion?(false)
        }
    }

    static func showLivestreamRequestFromHostAlert(policyUrl: PolicyURL,
                                                   handler: @escaping (Bool) -> Void,
                                                   completion: ((Result<ByteViewDialog, VCError>) -> Void)? = nil) {
        log.debug("will show asking attendee live policy alert")
        Util.runInMainThread {
            let title = I18n.View_M_HostLivestreamRequestTitle
            let linkText = LinkTextParser.parsedLinkText(from: I18n.View_M_HostLivestreamRequestInfo)
            let linkHandler: (Int, LinkComponent) -> Void = { (index, _) in
                guard let policy = Policy(rawValue: index) else {
                    return
                }

                openLink(of: policy, policyUrl: policyUrl) { _ in
                    switch policy {
                    case .privacy:
                        LiveTracks.trackPrivacyPolicyFromHostAlert()
                    case .userTermsOfService:
                        LiveTracks.trackUserTermsFromHostAlert()
                    default:
                        break
                    }
                }
            }
            let configuration = ByteViewDialogConfig.CheckboxConfiguration(
                content: I18n.View_G_ReadPrivacyPolicy,
                isChecked: false,
                affectLastButtonEnabled: true
            )
            ByteViewDialog.Builder()
                .id(.requestLivingFromHost)
                .title(title)
                .linkText(linkText, handler: linkHandler)
                .checkbox(configuration)
                .adaptsLandscapeLayout(true)
                .leftTitle(I18n.View_G_DontAllowButton)
                .leftHandler({ _ in
                    log.debug("attendees refuse host live policy alert")
                    LiveTracks.trackRefuseFromHostAlert()
                    handler(false)
                })
                .rightTitle(I18n.View_G_AllowButton)
                .rightHandler({ _ in
                    log.debug("attendees agree host live policy alert")
                    LiveTracks.trackAgreeFromHostAlert()
                    handler(true)
                })
                .show { completion?(.success($0)) }
        }
    }

    static func rxShowJoinLivesStreamedMeetingAlert(placeholderId: String,
                                                    policyUrl: PolicyURL,
                                                    colorTheme: ByteViewDialogConfig.ColorTheme? = nil) -> Single<Bool> {
        Single<Bool>.create { cb -> Disposable in
            let sad = SingleAssignmentDisposable()
            showJoinLivestreamedMeetingAlert(placeholderId: placeholderId, policyUrl: policyUrl, handler: { val in
                cb(.success(val))
            }, completion: { alert in
                weak var wAlert = alert
                sad.setDisposable(Disposables.create {
                    if Thread.isMainThread {
                        wAlert?.dismiss()
                    } else {
                        DispatchQueue.main.async {
                            wAlert?.dismiss()
                        }
                    }
                })
            },
            colorTheme: colorTheme)
            return sad
        }
    }

    static func showJoinLivestreamedMeetingAlert(placeholderId: String,
                                                 policyUrl: PolicyURL,
                                                 handler: @escaping (Bool) -> Void,
                                                 completion: ((ByteViewDialog) -> Void)? = nil,
                                                 colorTheme: ByteViewDialogConfig.ColorTheme? = nil) {
        log.debug("will show join live policy alert")
        Util.runInMainThread {
            let title = I18n.View_M_JoinLivestreamedMeetingTitle
            let linkText = LinkTextParser.parsedLinkText(from: I18n.View_M_JoinLivestreamedMeetingInfo)
            let linkHandler: (Int, LinkComponent) -> Void = { (index, _) in
                guard let policy = Policy(rawValue: index) else {
                    return
                }

                openLink(of: policy, policyUrl: policyUrl) { _ in
                    switch policy {
                    case .privacy:
                        LiveTracks.trackPrivacyPolicy(envId: placeholderId)
                    case .userTermsOfService:
                        LiveTracks.trackUserTerms(envId: placeholderId)
                    default:
                        break
                    }
                }
            }
            let configuration = ByteViewDialogConfig.CheckboxConfiguration(
                content: I18n.View_G_ReadPrivacyPolicy,
                isChecked: false,
                affectLastButtonEnabled: true
            )
            ByteViewDialog.Builder()
                .colorTheme(colorTheme ?? .defaultTheme)
                .title(title)
                .checkbox(configuration)
                .linkText(linkText, handler: linkHandler)
                .adaptsLandscapeLayout(true)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    log.debug("refuse join live policy alert")
                    LiveTracks.trackCancelLive(envId: placeholderId)
                    handler(false)
                })
                .rightTitle(I18n.View_M_JoinButton)
                .rightHandler({ _ in
                    log.debug("agree join live policy alert")
                    LiveTracks.trackJoinLive(envId: placeholderId)
                    handler(true)
                })
                .show {
                    LiveTracks.trackDisplayAlert(envId: placeholderId)
                    completion?($0)
                }
        }
    }

    static func startAskLiveStreamRequestAlert(isFollow: Bool,
                                               isInBreakoutRoom: Bool,
                                               requester: String,
                                               handler: @escaping (Bool) -> Void,
                                               completion: ((ByteViewDialog) -> Void)? = nil) {
        log.debug("will show asking host live alert")
        let title = I18n.View_M_RequestToLivestreamNew
        let message: String
        if isInBreakoutRoom {
            message = I18n.View_G_RequestToLivestreamMainRoom(requester)
        } else {
            message = isFollow
                ? I18n.View_M_RequestToLivestreamInfoNoDocBracesNewSettings(requester)
                : I18n.View_M_RequestToLivestreamInfoBracesNewSettings(requester)
        }
        ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .reveiveLiveRequest)
        ByteViewDialog.Builder()
            .id(.requestLiving)
            .title(title)
            .message(message)
            .leftTitle(I18n.View_G_DeclineButton)
            .leftHandler({ _ in
                log.debug("host refuse asking host live alert")
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .reveiveLiveRequest,
                                                         action: "cancel")
                handler(false)
            })
            .rightTitle(I18n.View_G_ApproveButton)
            .rightHandler({ _ in
                log.debug("host agree asking host live alert")
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .reveiveLiveRequest,
                                                         action: "agree")
                handler(true)
            })
            .show(completion: completion)
    }
}
