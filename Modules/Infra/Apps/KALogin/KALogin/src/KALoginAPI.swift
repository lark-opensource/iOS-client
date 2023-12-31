//
//  KALoginAPI.swift
//  KALogin
//
//  Created by Nix Wang on 2021/12/14.
//

import Foundation

struct KALoginResponse<T: Codable>: Codable {
    let code: Int?
    let message: String
    var data: T?
}

struct StepData<T: Codable>: Codable {
    let nextStep: String
    let stepInfo: T

    enum CodingKeys: String, CodingKey {
        case nextStep = "next_step"
        case stepInfo = "step_info"
    }
}

struct AuthURLStepInfo: Codable {
    let url: String
}

struct LandURLStepInfo: Codable {
    let landURL: String

    enum CodingKeys: String, CodingKey {
        case landURL = "land_url"
    }
}

struct EnterAppStepInfo: Codable {
    let frontUserID: String

    enum CodingKeys: String, CodingKey {
        case frontUserID = "front_user_id"
    }
}

class HTTPClient {
    let headers = [
        "Content-Type": "application/json",
        "X-App-Id": "1",
        "X-Api-Version": "1.0.0",
        "x-passport-device-ids": "eu_nc:3967504408916216",
        "x-request-id": "1A67400E-8638-4EE9-88A8-A8AE7E4F6B78",
        "user-agent": "Lark/31555144 CFNetwork/1240.0.4 Darwin/20.6.0",
        "x-passport-unit": "eu_nc",
        "X-Device-Info": "package_name=com.bytedance.ee.lark;device_os=iOS%2014.7.1;channel=saas;device_name=%E7%99%BD%E8%8F%9C;device_model=iPhone%2012;device_id=3967504408916216;lark_version=5.4.0-beta10;tt_app_id=1161;",
        "X-Locale": "zh-CN",
        "X-Terminal-Type": "4",
        "accept-language": "zh-cn",
        "x-sec-captcha-token": "mviL+quRL4397CV9sYV55FCK1dYJo1MyzqpEE6N3JJm93zd9HBevjbG3Oa8QbOuJxxWbAEfz9Jb2Jcv5c70HGIahbtHsguIa0Osg8n7fIOI76GF5FLamueW1+BwvumYFYIVzFa0rGkmnlTzah5KzuQi+hPrUHOyi4ECA4YeIn49hdhCfHVNf06Jfmh64kpXcE2XRLxes6aPiw3C3oAy6rut00o6ghafS50z817z7t86M3rUkE1YtzA99J52qsFzXEIAZrkRK0UXgkcgMhWcedUTxJosHOUmfCvu+0HZTeWugdtbYusm40a8zIFVzNeWjyY0ayiBSplRh1uCFUFm5+CBnU9u3J/Q3romlmxbz8l5AZsnEjP/MfL9e33TRnP6YpF3G4e/fdnUnBrnys7m3Na+4rdaTCrEWWCoWirA8VqvaHON1bgA="
    ]
    static let errorDomain = "cn.feishu.accounts"

    func GET<T: Codable>(url: URL, responseType: T.Type, completion: @escaping (_ result: Result<T, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        sendRequest(request: request, completion: completion)
    }

    func POST<T: Codable>(url: URL, body: [String: Any] = [:], responseType: T.Type, completion: @escaping (_ result: Result<T, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.allHTTPHeaderFields = headers

        sendRequest(request: request, completion: completion)
    }

    private func sendRequest<T: Codable>(request: URLRequest, completion: @escaping (_ result: Result<T, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(KALoginResponse<T>.self, from: data)
                        if (response.code ?? -1) == 0, let data = response.data {
                            completion(.success(data))
                        } else {
                            completion(.failure(NSError(domain: Self.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: response.message])))
                        }
                    } catch {
                        completion(.failure(NSError(domain: Self.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                    }
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        }

        task.resume()
    }

}
@objc
public class KALoginAPI: NSObject {
    static let shared = KALoginAPI()

    private let client = HTTPClient()

    private let loginHost = "accounts.feishu.cn"
    private let feishuHost = "www.feishu.cn"
    private let authURLAPI = "/accounts/idp/auth_url"
    private let idpVerifyAPI = "/suite/passport/idp_server/cas/verify"
    private let dispatchAPI = "/accounts/idp/dispatch"

    private let tenantDomainKey = "tenant_domain"
    private let userNameKey = "username"
    private let passwordKey = "password"
    private let stateKey = "state"

    @objc
    public class func sharedInstance() -> KALoginAPI {
        return KALoginAPI.shared
    }

    func getAuthURL(completion: @escaping (_ result: Result<String, Error>) -> Void) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = loginHost
        urlComponents.path = authURLAPI
        urlComponents.queryItems = [
            URLQueryItem(name: "app_id", value: "1"),
            URLQueryItem(name: "query_scope", value: "all"),
            URLQueryItem(name: "source_type", value: "1"),
            URLQueryItem(name: "tenant_domain", value: "castest1.feishu.cn")
        ]
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: HTTPClient.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to make URL"])))
            return
        }

        client.GET(url: url, responseType: StepData<AuthURLStepInfo>.self) { result in
            switch result {
            case .success(let data):
                completion(.success(data.stepInfo.url))
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    @objc
    public func verifyForOC(redirectURL: String, completion: @escaping (String?, Error?) -> Void) {
        verify(redirectURL: redirectURL) { result in
            switch result {
            case .success(let data):
                completion(data, nil)
                break
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    func verify(redirectURL: String, completion: @escaping (_ result: Result<String, Error>) -> Void) {
        if let cookie = HTTPCookie(properties: [
            .domain: feishuHost,
            .path: idpVerifyAPI,
            .name: "x-cas-redirect-uri",
            .value: redirectURL,
            .secure: "FALSE",
            .discard: "TRUE"
        ]) {
            HTTPCookieStorage.shared.setCookie(cookie)
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = feishuHost
        urlComponents.path = idpVerifyAPI

        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: HTTPClient.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to make URL"])))
            return
        }

        let body = [
            userNameKey: "zhangfei",
            passwordKey: "zhangfei"
        ]
        client.POST(url: url, body: body, responseType: AuthURLStepInfo.self) { result in
            switch result {
            case .success(let data):
                completion(.success(data.url))
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    @objc
    public func validateForOC(url: URL, completion: @escaping (String?, Error?) -> Void) {
        validate(url: url) { result in
            switch result {
            case .success(let data):
                completion(data, nil)
                break
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    func validate(url: URL, completion: @escaping (_ result: Result<String, Error>) -> Void) {
        client.GET(url: url, responseType: StepData<LandURLStepInfo>.self) { result in
            switch result {
            case .success(let data):
                completion(.success(data.stepInfo.landURL))
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func dispatch(state: String, completion: @escaping (_ result: Result<EnterAppStepInfo, Error>) -> Void) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = loginHost
        urlComponents.path = dispatchAPI

        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: HTTPClient.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to make URL"])))
            return
        }

        let body = [
            stateKey: state
        ]
        client.POST(url: url, body: body, responseType: StepData<EnterAppStepInfo>.self) { result in
            switch result {
            case .success(let data):
                completion(.success(data.stepInfo))
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
