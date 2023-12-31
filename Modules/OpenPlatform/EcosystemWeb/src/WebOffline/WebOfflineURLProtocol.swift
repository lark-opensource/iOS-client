import Foundation
/**
 离线化Web应用请求拦截
 只适用于WebBrowser离线化URLProtocol mpass方案
 */
public final class WebOfflineURLProtocol: URLProtocol {
    
    override public class func canInit(with request: URLRequest) -> Bool {
        OfflineResourcesTool.canIntercept(with: request)
    }
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override public func startLoading() {
        OfflineResourcesTool.fetchResources(with: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let responseAndData):
                self.client?.urlProtocol(self, didReceive: responseAndData.0, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: responseAndData.1)
                self.client?.urlProtocolDidFinishLoading(self)
            case .failure(let error):
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }
    
    override public func stopLoading() {
        //  do nothing
    }
}
