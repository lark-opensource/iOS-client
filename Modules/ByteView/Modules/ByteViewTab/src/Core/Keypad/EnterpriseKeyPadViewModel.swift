//
//  EnterpriseKeyPadViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import AVFoundation
import UIKit
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting

final class EnterpriseKeyPadViewModel {
    var maxTextLength: Int = 50

    let viewModel: MeetTabViewModel
    var userId: String { viewModel.userId }
    var httpClient: HttpClient { viewModel.httpClient }
    init(viewModel: MeetTabViewModel) {
        self.viewModel = viewModel
    }

    var lastCalledPhoneNumber: String? {
        get { viewModel.setting.lastCalledPhoneNumber }
        set { viewModel.setting.lastCalledPhoneNumber = newValue }
    }

    func callOut(with phoneNumber: String, from: UIViewController, completion: ((Result<Void, Error>) -> Void)?) {
        let number = phoneNumber.replacingOccurrences(of: " ", with: "")
        getPhoneAttribute(number) { [weak self, weak from] result in
            guard let self = self, let from = from else { return }
            switch result {
            case .success(let resp):
                let body = TabPhoneCallBody(phoneNumber: number, phoneType: resp.isIpPhone ? .ipPhone : .enterprisePhone, calleeId: resp.ipPhoneUserID, calleeName: resp.ipPhoneLarkUserName, calleeAvatarKey: resp.ipPhoneUserAvatarKey)
                self.startPhoneCall(body: body, from: from)
                completion?(.success(Void()))
            case .failure(let error):
                Logger.enterpriseCall.info("call out failure")
                completion?(.failure(error))
            }
        }
        lastCalledPhoneNumber = phoneNumber
    }

    func getPhoneAttribute(_ phoneNumber: String, completion: @escaping (Result<GetPhoneNumberAttributionResponse, Error>) -> Void) {
        let phoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        Logger.enterpriseCall.info("Get phone number request: phoneNumber is Empty: \(phoneNumber.isEmpty)")
        let request = GetPhoneNumberAttributionRequest(enterprisePhoneNumber: phoneNumber)
        httpClient.getResponse(request) { result in
            switch result {
            case .success(let resp):
                Logger.enterpriseCall.info("Get phone number attribute: province \(resp.province), isp \(resp.isp), countryCode \(resp.countryCode)")
            case .failure(let error):
                Logger.enterpriseCall.error("Get phone number attribute error: \(error)")
            }
            completion(result)
        }
    }

    private func startPhoneCall(body: TabPhoneCallBody, from: UIViewController) {
        Util.runInMainThread {
            self.viewModel.router?.startPhoneCall(body: body, from: from)
        }
    }

    func getCountryName(_ resp: GetPhoneNumberAttributionResponse?) -> String? {
        if let resp = resp {
            return viewModel.setting.getMobileCode(for: resp.countryCode)?.name ?? ""
        } else {
            return nil
        }
    }

    func checkQuota(completion: @escaping (CheckEnterprisePhoneQuotaResponse?) -> Void) {
        httpClient.getResponse(CheckEnterprisePhoneQuotaRequest()) { result in
            switch result {
            case .success(let res):
                Logger.enterpriseCall.info("Check enterprise phone quota success")
                if res.availableEnterprisePhoneAmount == 0, res.date.isEmpty {
                    completion(nil)
                    return
                }
                if res.availableEnterprisePhoneAmount == 0, !res.date.isEmpty {
                    ByteViewDialog.Builder()
                        .id(.enterpriseCall)
                        .title(I18n.View_MV_InsufficientBalance_OfficePhonePopUp)
                        .message(I18n.View_MV_NotEnoughBalanceContact_PopExplain)
                        .rightTitle(I18n.View_G_GotItButton)
                        .show()
                }
                completion(res)
            case .failure(let error):
                Logger.enterpriseCall.error("Check enterprise phone quota error: \(error)")
                completion(nil)
            }
        }
    }
}

extension Logger {
    static let enterpriseCall = getLogger("enterpriseCall")
}
