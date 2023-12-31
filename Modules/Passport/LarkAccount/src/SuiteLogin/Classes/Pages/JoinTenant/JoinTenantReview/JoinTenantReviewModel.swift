//
//  JoinTenantReviewModel.swift
//  LarkAccount
//
//  Created by bytedance on 2021/7/8.
//

import Foundation
import RxSwift
import LarkContainer
import EENavigator

class JoinTenantReviewModel: V3ViewModel {
    @InjectedLazy private var loginService: V3LoginService

    let joinTenantReviewInfo: V4JoinTenantReviewInfo

    init(
        step: String,
        stepInfo: V4JoinTenantReviewInfo,
        context: UniContextProtocol
    ) {
        self.joinTenantReviewInfo = stepInfo
        super.init(step: step, stepInfo: stepInfo, context: context)
    }

    var code: String = ""

    public func getParams() -> (teamCode: String?, qrUrL: String?, flowType: String?) {
        return (code, nil, self.joinTenantReviewInfo.flowType)
    }

    private func toLoginVC(vc: UIViewController) {
        Self.logger.info("pop to login page")
        let loginVC = loginService.createLoginVC(context: self.context)
        Navigator.shared.push(loginVC, from: vc) // user:checked (navigator)
    }
    
    private func toFeedVC(vc: UIViewController) {
        Navigator.shared.navigation?.popToRootViewController(animated: true) // user:checked (navigator)
    }

}

extension JoinTenantReviewModel {
    var title: String {
        return joinTenantReviewInfo.title
    }

    var subtitle: NSAttributedString {
        return attributedString(for: joinTenantReviewInfo.subtitle)
    }

    var button: String {
        return joinTenantReviewInfo.button?.text ?? ""
    }
}
