//
//  DocsDownloadRequest.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/1/23.
//

import Foundation
import Alamofire
import LarkContainer

/// 包含一次下载请求
public final class DocsDownloadRequest: DocsRequest<Any> {
    public typealias DownloadProgressBlock = (_ progress: Double) -> Void
    public typealias DownloadResponse = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void

    /// 用于保存正在下载的任务。完成后，从里面移除
    private static var requestsToRemove = Set<DocsDownloadRequest>()

    private var downloadProgressBlock: DownloadProgressBlock?
    private var downloadRequest: DownloadRequest?
    private var destinationPath: SKFilePath

    public init(sourceURL: URL, destination: SKFilePath) {
        destinationPath = destination
        super.init(url: sourceURL.absoluteString, params: nil)
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let netConfig = userResolver.docs.netConfig ?? NetConfig.shared
        context = netConfig.sessionFor(.default, trafficType: .download)
        requestConfig.method = .GET
    }
    
    required convenience init(skRequest: URLRequest) {
        fatalError("init(skRequest:) has not been implemented")
    }

    @discardableResult
    public func set(downloadProgressBlock: DownloadProgressBlock?) -> DocsDownloadRequest {
        self.downloadProgressBlock = downloadProgressBlock
        return self
    }

    @discardableResult
    public func startDownload(rawResult: @escaping DownloadResponse) -> DocsDownloadRequest {
        contructInternalRequest()
        downloadRequest?.downloadProgress { [weak self] (progress) in
            self?.downloadProgressBlock?(progress.fractionCompleted)
        }.response { [weak self] response in
            guard let `self` = self else { return }
            defer {
                DocsDownloadRequest.requestsToRemove.remove(self)
            }
            self.retryHander.removeRetryFor(self.downloadRequest?.request)
            rawResult(nil, response.response, response.error)
        }
        return self
    }

    internal override func contructInternalRequest() {
        let headersForRequest = requestConfig.headersWith(context.session.requestHeader)
        let destinationPath = self.destinationPath
        downloadRequest = context.session.manager.download(requestConfig.url,
                                                           method: requestConfig.method.toAlamofire,
                                                           parameters: nil,
                                                           encoding: requestConfig.encodeType.toAlamofire,
                                                           headers: headersForRequest) {  (_, _)  in
            return (destinationPath.pathURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        retryHander.addRetryFor(downloadRequest?.request)
    }

}

extension DocsDownloadRequest {

    /// 创建一个下载任务，自己引用自己，外面不需要保存对任务的引用
    public static func download(_ url: URL, to destination: SKFilePath) -> DocsDownloadRequest {
        let request = DocsDownloadRequest(sourceURL: url, destination: destination)
        requestsToRemove.insert(request)
        return request
    }
}

extension DocsDownloadRequest: Hashable {
    public static func == (lhs: DocsDownloadRequest, rhs: DocsDownloadRequest) -> Bool {
        return lhs.requestConfig.requestId == rhs.requestConfig.requestId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(requestConfig.requestId)
    }
}

extension DocsDownloadRequest: CustomStringConvertible {
    public var description: String {
        return "source:\(String(describing: requestConfig.url)), dest: \(destinationPath), requestid: \(requestConfig.requestId)"
    }
}
