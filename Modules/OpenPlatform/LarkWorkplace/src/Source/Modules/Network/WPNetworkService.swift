//
//  WPNetworkService.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/11/19.
//

import Foundation
import ECOInfra
import LarkContainer
import RxSwift
import SwiftyJSON
import LarkOPInterface
import LKCommonsLogging

protocol WPNetworkService: AnyObject {
    func request<Config: ECOInfra.ECONetworkRequestConfig, ParamsType, ResultType>(
        _ configType: Config.Type, params: ParamsType, context: WPNetworkContext
    ) -> Single<ResultType> where ParamsType == Config.ParamsType, ResultType == Config.ResultType
}

final class WPNetworkServiceImpl: WPNetworkService {
    static let logger = Logger.log(WPNetworkService.self)

    private let userResolver: UserResolver
    private let service: ECOInfra.ECONetworkService

    private static let defaultSubscriptionQueue = DispatchQueue(label: "com.workplace.WPNetworkService", attributes: .concurrent)

    init(userResolver: UserResolver, service: ECOInfra.ECONetworkService) {
        self.userResolver = userResolver
        self.service = service
    }

    func request<Config: ECOInfra.ECONetworkRequestConfig, ParamsType, ResultType>(
        _ configType: Config.Type, params: ParamsType, context: WPNetworkContext
    ) -> Single<ResultType> where ParamsType == Config.ParamsType, ResultType == Config.ResultType {
        // swiftlint:disable closure_body_length
        return Single.create { [weak self] single in
            guard let `self` = self else {
                let opError = OPError.createTaskWithWrongParams(detail: "create task fail for nil self, \(configType.description())")
                let err = Self.mapError(ECONetworkError.innerError(opError), logId: nil)
                single(.error(err))
                return Disposables.create()
            }

            Self.logger.info("start request", additionalData: [
                "config": configType.description(),
                "path": configType.path
            ])
            context.setUserResolver(self.userResolver)

            var task: ECOInfra.ECONetworkServiceTask<ResultType>?
            let completionHandler: (ECOInfra.ECONetworkResponse<ResultType>?, ECOInfra.ECONetworkError?) -> Void = { response, error in
                defer { task = nil }

                Self.logger.info("did finish request", additionalData: [
                    "path": configType.path,
                    "hasResponse": "\(response != nil)",
                    "error": "\(error?.localizedDescription ?? "")"
                ])

                if let responseError = error {
                    let err = Self.mapError(responseError, logId: context.logId)
                    single(.error(err))
                    return
                }

                guard let result = response?.result else {
                    let opError = OPError.requestCompleteWithUnexpectResponse(detail: "response with no result")
                    let error = Self.mapError(ECOInfra.ECONetworkError.responseError(opError), logId: context.logId)
                    single(.error(error))
                    return
                }

                // ResultType接入标准化数据解析后去掉json转换
                if var jsonResult = result as? JSON {
                    jsonResult["logId"].string = context.logId
                    if let networkResponse = response {
                        jsonResult["httpCode"].int = networkResponse.statusCode
                    }
                    if let responseResult = jsonResult as? ResultType {
                        single(.success(responseResult))
                    } else {
                        single(.success(result))
                    }
                } else {
                    single(.success(result))
                }
            }

            task = self.service.createTask(
                context: context,
                config: configType,
                params: params,
                callbackQueue: .main,
                requestCompletionHandler: completionHandler
            )

            guard let task = task else {
                let opError = OPError.createTaskWithWrongParams(detail: "create task fail \(configType.description())")
                let err = Self.mapError(ECOInfra.ECONetworkError.innerError(opError), logId: nil)
                single(.error(err))
                return Disposables.create()
            }

            self.service.resume(task: task)
            return Disposables.create()
        }.subscribeOn(ConcurrentDispatchQueueScheduler(queue: Self.defaultSubscriptionQueue))
        // swiftlint:enable closure_body_length
    }

    private static func mapError(_ ecoNetworkError: ECOInfra.ECONetworkError, logId: String?) -> NSError {
        let errorInfo = WPNetworkErrorInfo(error: ecoNetworkError)
        var userInfo = errorInfo.errorUserInfo
        if let requestLogId = logId {
            userInfo["logId"] = requestLogId
        }
        return NSError(domain: errorInfo.domain, code: errorInfo.errorCode, userInfo: userInfo)
    }
}
