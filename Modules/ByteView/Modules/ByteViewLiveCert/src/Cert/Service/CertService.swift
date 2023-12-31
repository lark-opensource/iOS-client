//
//  CertService.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/12.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

public final class CertService {
    private let httpClient: HttpClient
    private let dependency: CertDependency
    public init(httpClient: HttpClient, dependency: CertDependency) {
        self.httpClient = httpClient
        self.dependency = dependency
    }

    @RwAtomic
    private var appID: Int32 = 2841
    @RwAtomic
    private var scene: String = "feishu_livestream"

    private weak var networkErrorHandler: NetworkErrorHandler?
    func setDelegate(_ delegate: NetworkErrorHandler?) {
        self.networkErrorHandler = delegate
    }

    private var options: NetworkRequestOptions { [.preErrorHandler(networkErrorHandler)] }

    private func getCertTicket(completion: @escaping (Result<String, Error>) -> Void) {
        httpClient.getResponse(GetVerificationTicketRequest(appId: appID, scene: scene), options: self.options) {
            completion($0.map({ $0.ticket }))
        }
    }

    private func fetchVerificactionInfo(token: String, completion: @escaping (Error?) -> Void) {
        let request = GetVerificationInfoRequest(token: token)
        self.httpClient.getResponse(request, options: self.options) { [weak self] result in
            switch result {
            case .success(let res):
                LiveCertTracks.trackScanSuccess()
                self?.appID = res.appID
                self?.scene = res.scene
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    func verifyTwoElement(name: String, code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let request = VerifyTwoElementRequest(appId: appID, scene: scene, identityCode: code, identityName: name)
        self.httpClient.send(request, options: self.options) { result in
            if case .failure(let error) = result, let errorInfo = error as? RustBizError, let msgInfo = errorInfo.msgInfo {
                let reason = TwoEleFailReason.reason(from: msgInfo)
                LiveCertTracks.trackTwoElementsFailed(reason: reason)
            }
            completion(result)
        }
    }

    func verifyLiveness(completion: @escaping (Result<Void, Error>) -> Void) {
        getCertTicket { [weak self] result in
            switch result {
            case .success(let ticket):
                DispatchQueue.main.async {
                    guard let self = self else {
                        completion(.failure(CertError.noElements))
                        return
                    }
                    self.dependency.doFaceLiveness(appID: String(self.appID), ticket: ticket, scene: self.scene) { (_, errMsg) in
                        if let errMsg = errMsg {
                            Logger.cert.info("liveness cert error with msg: \(errMsg)")
                            LiveCertTracks.trackLivenessResult(isSuccess: false)
                            completion(.failure(CertError.livenessFailed(errorMsg: errMsg)))
                        } else {
                            LiveCertTracks.trackLivenessResult(isSuccess: true)
                            completion(.success(Void()))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func presentCertViewController(from: UIViewController, wrap: UINavigationController.Type? = nil, callback: ((Result<Void, CertError>) -> Void)? = nil) {
        let vm = TwoElementsCertViewModel(certService: self, callback: callback)
        var vc: UIViewController = TwoElementsCertViewController(viewModel: vm)
        vm.hostViewController = vc
        if let wrap = wrap {
            vc = wrap.init(rootViewController: vc)
        }
        from.vc.safePresent(vc, animated: true)
    }

    func fetchLiveCertPolicy(for type: LiveCertPolicyType, completion: @escaping (Result<LinkText, Error>) -> Void) {
        httpClient.getResponse(FetchLivePolicyRequest(), options: self.options) { [weak self] result in
            switch result {
            case .success(let resp):
                switch type {
                case .checkbox:
                    self?.requestI18n(by: resp.certificationCheckbox, completion: completion)
                case .popup:
                    self?.requestI18n(by: resp.certificationPopup, completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func requestI18n(by mega: MegaI18n, completion: @escaping (Result<LinkText, Error>) -> Void) {
        httpClient.i18n.get(mega.key) {
            let result = $0.map { template in
                let regex = try? NSRegularExpression(pattern: "(?<=\\[\\[)[^\\]\\]]*(?=\\]\\])")
                let range = NSRange(template.startIndex..., in: template)
                let matches = regex?.matches(in: template, range: range).compactMap {
                    Range($0.range, in: template).map { String(template[$0]) }
                }

                var msg = template
                var components: [LinkComponent] = []
                let map = mega.data
                for match in matches ?? [] {
                    let key: String
                    var value: String
                    if let index = match.firstIndex(of: ":") {
                        key = String(match.prefix(upTo: index))
                        value = String(match.suffix(from: match.index(after: index)))
                    } else {
                        key = match
                        value = ""
                    }
                    if let data = map[key], data.type == .string {
                        value = data.payload
                    }
                    msg = msg.replacingOccurrences(of: "[[\(match)]]", with: "\(value)")
                    if let data = map[key] {
                        let range = (msg as NSString).range(of: "\(value)")
                        if range.location != NSNotFound {
                            switch data.type {
                            case .link:
                                let url = URL(string: data.payload)
                                let component = LinkComponent(text: value, range: range, url: url)
                                components.append(component)
                            case .click, .em:
                                let component = LinkComponent(text: value, range: range)
                                components.append(component)
                            default:
                                break
                            }
                        }
                    }
                }
                return LinkText(source: template, result: msg, components: components)
            }
            completion(result)
        }
    }

    func openURL(_ url: URL, from: UIViewController) {
        dependency.openURL(url, from: from)
    }
}

public extension CertService {
    func handleLiveCertLink(token: String, from: UIViewController, wrap: UINavigationController.Type?) {
        fetchVerificactionInfo(token: token) { [weak self, weak from] error in
            DispatchQueue.main.async {
                guard let self = self, let from = from, error == nil else {
                    return
                }
                self.presentCertViewController(from: from, wrap: wrap)
            }
        }
    }

    func showLiveCert(from: UIViewController, wrap: UINavigationController.Type?, callback: ((Result<Void, Error>) -> Void)?) {
        self.presentCertViewController(from: from, wrap: wrap) {
            callback?($0.mapError({ $0 }))
        }
    }

}

enum TwoEleFailReason {
    case unknown
    case wrongID
    case linkedID
    case underAge
    case timesOut

    static func reason(from msgInfo: MsgInfo?) -> TwoEleFailReason {
        guard let i18nKey = msgInfo?.msgI18NKey else { return .unknown }
        switch i18nKey.newKey {
        case "View_G_AuthenticationInputError":
            return .wrongID
        case "View_G_AuthenticationMinor":
            return .underAge
        case "View_G_AuthenticationIdAssociated":
            return .linkedID
        case "View_G_TooManyAuthenticationAttempts":
            return .timesOut
        default:
            return .unknown
        }
    }
}
