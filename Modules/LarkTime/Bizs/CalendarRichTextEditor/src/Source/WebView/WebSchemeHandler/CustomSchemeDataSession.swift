//
//  CustomSchemeDataSession.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/9/4.
//

import UIKit
import RxSwift
import LarkEditorJS
import LarkRustHTTP

protocol CustomSchemeDataSessionDelegate: AnyObject {
    func session(_ session: CustomSchemeDataSession, didBeginWith newRequest: NSMutableURLRequest)
}

final class CustomSchemeDataSession: NSObject {
    private static var intercepterMap = NSHashTable<AnyObject>(options: NSPointerFunctions.Options.weakMemory)
    private static let requestQueue = DispatchQueue(label: "com.calendar.CustomSchemeDataSession")

    let request: URLRequest
    let disposeBag: DisposeBag = DisposeBag()

    private var sessionTask: URLSessionDataTask?
    let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [RustHttpURLProtocol.self]
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        config.httpCookieStorage = HTTPCookieStorage.shared
        let urlSession = URLSession(configuration: config)
        return urlSession
    }()
    private weak var sessionDelegate: CustomSchemeDataSessionDelegate?
    var webviewUrl: URL?

    init(request: URLRequest, delegate: CustomSchemeDataSessionDelegate?) {
        self.request = request
        self.sessionDelegate = delegate
        super.init()
    }

    func start(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let originUrl = self.request.url else {
            DispatchQueue.global().async {
                let error = NSError(domain: "url error", code: -1, userInfo: nil)
                completionHandler(nil, nil, error)
            }
            assertionFailure()
            return
        }

        CustomSchemeDataSession.requestQueue.async {
            if let data = CommonJSUtil.getData(resPath: originUrl.absoluteString) {
                DispatchQueue.global().async {
                    completionHandler(data, nil, nil)
                }
            } else {
                let modifiedUrl = self.changeUrl(originUrl, schemeTo: "https")

                guard let request = (self.request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
                    DispatchQueue.global().async {
                        let error = NSError(domain: "url error", code: -1, userInfo: nil)
                        completionHandler(nil, nil, error)
                    }
                    assertionFailure()
                    return
                }

                request.url = modifiedUrl
                guard let resultRequst = request as? URLRequest else { return }

                self.sessionDelegate?.session(self, didBeginWith: request)

                self.sessionTask = self.urlSession.dataTask(with: resultRequst, completionHandler: { [weak self] (data, response, error) in
                    guard let self = self else { return }
                    if let data = data, error == nil {
                        completionHandler(data, response, nil)
                    } else {
                        completionHandler(nil, nil, error)
                    }
                })
                self.sessionTask?.resume()
            }
        }
    }

    func stop() {
        self.sessionTask?.cancel()
        self.sessionTask = nil
    }

    private func changeUrl(_ url: URL, schemeTo scheme: String) -> URL {
        guard var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Logger.info("changeUrl Failed")
            return url
        }
        urlComponent.scheme = scheme
        return urlComponent.url ?? url
    }
}

extension CommonJSUtil {
    class func getData(resPath: String) -> Data? {
        guard let resName = resPath.components(separatedBy: "/").last else {
            return nil
        }
        let executePath = CommonJSUtil.getExecuteJSPath()
        let executeUrl = URL(fileURLWithPath: executePath)
        let fullPath = executeUrl.appendingPathComponent(resName).path

        let url = URL(fileURLWithPath: fullPath)
        do {
            Logger.info("calendar.res 加载\(fullPath)")
            return try Data.read(from: url.asAbsPath(), options: .mappedIfSafe)
        } catch {
            Logger.info("calendar.res 获取失败")
            return nil
        }
    }
}
