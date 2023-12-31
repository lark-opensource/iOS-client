//
//  QRCodeJoinTeamAnalysisModule.swift
//  LarkQRCode
//
//  Created by Miaoqi Wang on 2020/3/4.
//

import UIKit
import Foundation
import UniverseDesignToast
import EENavigator
import LarkFeatureSwitch
import LarkFeatureGating
import LarkReleaseConfig
import QRCode
import LKCommonsLogging
import CryptoSwift
import LarkAccountInterface
import LarkContainer

private let inviteUrlRegex: String = "^https://([-a-z0-9.]+)/invite/([a-zA-Z0-9]+)(\\?.*)*$"

final class QRCodeJoinTeamAnalysisModule: QRCodeAnalysis, UserResolverWrapper {

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    @ScopedProvider private var passportUserService: PassportUserService?

    static let logger = Logger.log(QRCodeJoinTeamAnalysisModule.self)

    // can be QRCodeViewController or PreviewImageViewController
    func lastVC(from: UIViewController) -> UIViewController? {
        return UIViewController.topMost(of: from, checkSupport: false)
    }

    func handle(code: String, status: QRCodeAnalysisCallBack, from: QRCodeFromType, fromVC: UIViewController) -> Bool {
        guard !ReleaseConfig.isPrivateKA, let passportUserService else { return false }
        guard !passportUserService.user.isIdPUser else { return false }

        guard let url = URL(string: code),
            let regExp = try? NSRegularExpression(
                pattern: inviteUrlRegex,
                options: [.caseInsensitive]) else {
                    return false
        }
        let urlStr = url.absoluteString
        let range = NSRange(location: 0, length: urlStr.count)
        if regExp.matches(in: urlStr, options: [], range: range).isEmpty {
            QRCodeJoinTeamAnalysisModule.logger.debug("url not match invite url")
            return false
        }

        if let lastVC = lastVC(from: fromVC),
            passportUserService.joinTeam(
                withQRUrl: urlStr,
                fromVC: lastVC,
                result: { success in
                    if !success {
                        QRCodeJoinTeamAnalysisModule.logger.warn("qrcode join team not success")
                        // if current is  QRCode view retry scan, otherwise maybe in preview image view, dont need rescan
                        // error will be handle in AccountService
                        if let qrVC = lastVC as? ScanCodeViewController {
                            DispatchQueue.main.async {
                                qrVC.startScanning()
                            }
                        }
                    } else {
                        QRCodeJoinTeamAnalysisModule.logger.info("qrcode join team success")
                    }
                }) {
            return true
        } else {
            QRCodeJoinTeamAnalysisModule.logger.error("qrcode join team anaylsis failed",
                                                      additionalData: ["urlMD5": url.absoluteString.md5(),
                                                                       "lastVC is nil": "\(lastVC(from: fromVC) == nil)"])
            return false
        }
    }
}
