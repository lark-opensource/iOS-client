//
//  SendImageRequest.swift
//  ByteWebImage
//
//  Created by kangsiwan on 2022/1/14.
//

import Photos
import RxSwift
import ImageIO
import Foundation
import LarkSetting
import CoreServices
import LarkContainer
import AppReciableSDK
import LKCommonsLogging
import ThreadSafeDataStructure

// MARK: 组件的协议
/// request: 业务方实现
/// 图片信息在context中，业务方调用不同的上传接口，将上传结果返回
/// 内部会强持有业务方
public protocol LarkSendImageUploader {
    associatedtype ResultType
    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<ResultType>
}

/// options: 业务方实现
/// 用于插入执行步骤，业务方可以实现自己的操作，将需要存储的上下文返回
/// 内部会强持有业务方
public protocol LarkSendImageProcessor {
    func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void>
}

/// request: 组件实现
/// 业务方可以通过此协议设置和获取context，以及拿到某些步骤后的结果
// TODO 只保留一个 get result
public protocol LarkSendImageAbstractRequest {
    var requestId: UUID { get }
    func getInput() -> ImageInputType
    func getConfig() -> SendImageConfig
    func setContext(key: String, value: Any)
    func getContext() -> SafeDictionary<String, Any>
    func getCheckResult() -> [CheckResult]?
    func getCompressResult() -> [CompressResult]?
}

// MARK: 组件的数据结构
// 上传阶段
public enum SendImageState {
    case check
    case compress
    case upload
}

public struct LarkSendImageError: Error {
    public enum TypeEnum {
        case check
        case compress
        case upload
        case custom
    }

    public var type: TypeEnum
    public var error: Error
    public init(type: TypeEnum, error: Error) {
        self.type = type
        self.error = error
    }
}

// 业务方自定义Error需要满足此协议，用来上报埋点的error_code
public protocol CustomUploadError: Error {
    var code: Int { get set }
}

public enum CheckError: Error {
    // 文件类型超出限制
    case fileTypeInvalid
    // 文件大小超出限制
    case imageFileSizeExceeded(Int)
    // 图片大小超出限制
    case imagePixelsExceeded(CGSize)

    func transformCheckErrorToCompressError() -> CompressError {
        switch self {
        case .fileTypeInvalid:
            return .fileTypeInvalid
        case .imageFileSizeExceeded(let file):
            return .imageFileSizeExceeded(file)
        case .imagePixelsExceeded(let size):
            return .imagePixelsExceeded(size)
        }
    }
}

// 报错类型
public enum CompressError: Error {
    // 一般情况下是取不到self
    case requestRelease
    // 调用process接口获取不到结果
    case failedToGetProcessResult
    // 取不到check的结果
    case failedToGetCheckResult
    // 文件类型超出限制
    case fileTypeInvalid
    // 文件大小超出限制
    case imageFileSizeExceeded(Int)
    // 图片大小超出限制
    case imagePixelsExceeded(CGSize)

    func code() -> Int {
        // disable-lint: magic number
        switch self {
        case .requestRelease:
            return -45_900_001
        case .failedToGetProcessResult:
            return -45_900_002
        case .failedToGetCheckResult:
            return -45_900_011
        case .fileTypeInvalid:
            return -45_900_010
        case .imageFileSizeExceeded:
            return -45_900_003
        case .imagePixelsExceeded:
            return -45_900_004
        }
        // enable-lint: magic number
    }
}

public enum UploadImageError: Error {
    // 没有结果
    case noResult
}

// 输入类型和参数
public enum ImageInputType {
    case image(UIImage)
    case asset(PHAsset)
    case data(Data)
    case images([UIImage])
    case assets([PHAsset])
    case datas([Data])
}

public typealias PreCompressResultBlock = ((PHAsset) -> ImageSourceResult?)

// 填充context需要的key
public struct SendImageRequestKey {
    // check的结果
    public struct CheckResult {
        public static let CheckResult = "sendImageRequest.CheckResult"
    }

    // compress过程中产生的数据
    public struct CompressResult {
        // 类型：[CompressResult]
        public static let CompressResult = "sendImageRequest.CompressResult"
        /// PHAsset类型，会判断preCompress结果，从而跳过compress
        public static let PreCompressResultBlock = "sendImageRequest.PreCompressResult"
    }

    // upload的结果
    public struct UploadResult {
        // 类型：ResultType
        public static let ResultType = "sendImageRequest.UploadResult.ResultType"
    }

    // init输入时的数据
    public struct InitParams {
        // 类型：SendImageConfig
        public static let SendImageConfig = "sendImageRequest.InitParams.SendImageConfig"
        // 类型：ImageInputType
        public static let InputType = "sendImageRequest.InitParams.InputType"
    }

    public struct Other {
        public static let isCustomTrack = "sendImageRequest.Other.isCustomTrack"
    }
}

private let logger = Logger.log(LarkSendImageAbstractRequest.self, category: "")
// MARK: sendImageRequest
public final class SendImageRequest<T, U: LarkSendImageUploader>: LarkSendImageAbstractRequest {
    public let requestId: UUID = UUID()
    public private(set) var context: SafeDictionary<String, Any> = [:] + .readWriteLock
    let checkProcess: LarkSendImageProcessor
    let compressProcess: LarkSendImageProcessor
    let uploaderProcess: LarkSendImageUploadProcess<U>

    // 初始化输入
    private let input: ImageInputType
    private let sendImageConfig: SendImageConfig

    // 使用方通过addProcessor添加
    var afterCheckProcessorArray: [LarkSendImageProcessor] = []
    var afterCompressProcessorArray: [LarkSendImageProcessor] = []
    var afterUploadProcessorArray: [LarkSendImageProcessor] = []

    // 其他
    private let disposeBag = DisposeBag()

    public init(input: ImageInputType,
         sendImageConfig: SendImageConfig = SendImageConfig(),
         uploader: U
    ) where U.ResultType == T {
        self.input = input
        self.sendImageConfig = sendImageConfig
        self.uploaderProcess = LarkSendImageUploadProcess(uploader: uploader)
        self.checkProcess = LarkSendImageCheckProcess(config: sendImageConfig, input: input)
        self.compressProcess = LarkSendImageCompressProcess(config: sendImageConfig)
        // 将输入的数据放在context中
        self.setContext(key: SendImageRequestKey.InitParams.InputType, value: input)
        self.setContext(key: SendImageRequestKey.InitParams.SendImageConfig, value: sendImageConfig)
    }

    /// 给context添加参数
    @discardableResult
    public func addContext(_ subDic: SafeDictionary<String, Any>) -> Self {
        subDic.forEach { key, value in
            context[key] = value
        }
        logger.info("request \(requestId) addContext \(subDic)")
        return self
    }

    /// 添加process，指定在哪个步骤之后添加process
    @discardableResult
    public func addProcessor(afterState: SendImageState, processor: LarkSendImageProcessor, processorId: String) -> Self {
        if processorId.isEmpty {
            assertionFailure()
        }
        switch afterState {
        case .check:
            afterCheckProcessorArray.append(processor)
            logger.info("request \(requestId) addProcessor check \(processor) \(processorId)")
        case .compress:
            afterCompressProcessorArray.append(processor)
            logger.info("request \(requestId) addProcessor compress \(processor) \(processorId)")
        case .upload:
            afterUploadProcessorArray.append(processor)
            logger.info("request \(requestId) addProcessor upload \(processor) \(processorId)")
        }
        return self
    }

    // MARK: protocol
    /// 给context添加参数
    public func setContext(key: String, value: Any) {
        context[key] = value
        logger.info("request \(requestId) setContext \(key) \(value)")
    }

    public func getContext() -> SafeDictionary<String, Any> {
        return self.context
    }

    public func getCompressResult() -> [CompressResult]? {
        if let imageResultAndInputArray = context[SendImageRequestKey.CompressResult.CompressResult] as? [CompressResult] {
            return imageResultAndInputArray
        }
        return nil
    }

    public func getCheckResult() -> [CheckResult]? {
        if let imageCheckResult = context[SendImageRequestKey.CheckResult.CheckResult] as? [CheckResult] {
            return imageCheckResult
        }
        return nil
    }

    public func getInput() -> ImageInputType {
        return self.input
    }

    public func getConfig() -> SendImageConfig {
        return self.sendImageConfig
    }
}
