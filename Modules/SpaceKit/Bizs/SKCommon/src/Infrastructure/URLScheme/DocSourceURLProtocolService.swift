//  Created by Songwen Ding on 2018/5/9.

import SKFoundation

final public class DocSourceURLProtocolService: URLProtocol {
    public static var scheme = "docsource"
    private var dataSession: CustomSchemeDataSession?
    private static let handledKey = String(describing: DocSourceURLProtocolService.self) + "_handleKey"
    override public init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }
}

extension DocSourceURLProtocolService {
    override final public class func canInit(with request: URLRequest) -> Bool {
        if let handled = URLProtocol.property(forKey: handledKey, in: request) as? Bool, handled { return false }
        if request.url?.scheme?.lowercased() == self.scheme { return true }
        return false
    }

    override final public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override final public func startLoading() {
        self.dataSession = CustomSchemeDataSession(request: request, delegate: self)
//        DocsLogger.info("start loading \(request.url?.absoluteString ?? "")")
        self.dataSession?.start(completionHandler: { [weak self] (data1, response, error) in
            guard let strongSelf = self else {
                DocsLogger.info("self has been deinited")
                return
            }
            if let error = error {
//                DocsLogger.error("customUrl protocol load fail with error", extraInfo: ["url": "\(String(describing: strongSelf.request.url))"], error: error, component: nil)
                strongSelf.client?.urlProtocol(strongSelf, didFailWithError: error)
            } else {
                guard let data = data1, let originalUrl = strongSelf.request.url else {
//                    DocsLogger.error("customUrl protocol load fail ", extraInfo: ["url": "\(String(describing: strongSelf.request.url))"], error: nil, component: nil)
                    return
                }
                if let response = response {
//                    DocsLogger.info("loading \(strongSelf.request.url?.absoluteString ?? "") succ with response")
                    strongSelf.client?.urlProtocol(strongSelf, didReceive: response, cacheStoragePolicy: .allowed)
                } else {
//                    DocsLogger.info("loading \(strongSelf.request.url?.absoluteString ?? "") succ with data")
                    let response1 = URLResponse(url: originalUrl, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
                    strongSelf.client?.urlProtocol(strongSelf, didReceive: response1, cacheStoragePolicy: .allowed)
                }
                strongSelf.client?.urlProtocol(strongSelf, didLoad: data)
                strongSelf.client?.urlProtocolDidFinishLoading(strongSelf)
            }
        })
    }

//    private func createResponseForWeb(request: URLRequest, originUrl: URL, data: Data) -> URLResponse {
//
//        let defaultResponse = URLResponse(url: originUrl, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
//        let shouldAddCustomHeader: Bool = {
//            if let webUrl = request.url,
//                let docType = DocsUrlUtil.getFileType(from: webUrl), docType == .mindnote,
//                request.url?.path.hasPrefix("/file/f/") ?? false {
//                return true
//            } else {
//                return false
//            }
//        }()
//        if shouldAddCustomHeader,
//            let originHeaders = request.allHTTPHeaderFields, originHeaders.keys.contains("Origin") {
//            var headers: [String: String] = SpaceHttpHeaders.common
//            if let originHeaderUrl = URL(string: originHeaders["Origin"] ?? "*") {
//                headers.merge(other: [DocsCustomHeader.accessCredentials.rawValue: "true",
//                                      DocsCustomHeader.accessMethods.rawValue: "POST, GET, OPTIONS, PUT, DELETE",
//                                      DocsCustomHeader.accessOrigin.rawValue: originHeaderUrl.absoluteString])
//            }
//            let mindnoteResponse = HTTPURLResponse(url: originUrl, statusCode: 200, httpVersion: nil, headerFields: headers)
//            return mindnoteResponse ?? defaultResponse
//        } else {
//            return defaultResponse
//        }
//    }

    override final public func stopLoading() {
        self.dataSession?.stop()
    }
}

extension DocSourceURLProtocolService: CustomSchemeDataSessionDelegate {
    public func session(_ session: CustomSchemeDataSession, didBeginWith newRequest: NSMutableURLRequest) {
        URLProtocol.setProperty(true, forKey: DocSourceURLProtocolService.handledKey, in: newRequest)
    }
}
