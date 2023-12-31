//
//  UploadImageNetworkService.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/7/18.
// swiftlint:disable function_parameter_count

import Foundation
import RxSwift
import SKFoundation
import ThreadSafeDataStructure
import SKInfra

// 1MB的数据的超时时间
private struct UploadTimeoutPerMB {
    // 目前都设置为 1MB增加5s, 大概 200kb/ss
    static let wifi = 5.0
    static let celluar = 5.0
    static let `default` = 5.0
}

// 上传模式
// doc 模式是代表图片挂载到 doc 后台, 正常请求不会再用到这种模式
// drive 模式是代表图片挂载到 drive, 用于统一收费
enum UploadImageType: Int {
    case doc = 0
    case drive = 1
    case copyTo = 2
}

// 上传任务信息
typealias UploadSuccessType = (uuid: String, params: [String: Any])
typealias UploadResultType = Result<UploadSuccessType, UploadError>
typealias UploadTaskCompletion = (UploadResultType) -> Void
typealias UploadProgressType = (bytesTransferred: Int64, bytesTotal: Int64)
typealias UploadTaskProgress = (UploadProgressType) -> Void
// 上传任务信息
private struct UploadTaskInfo: Hashable {
    let uploadVersion: UploadImageType // 上传方式
    let uuid: String // 图片在 cache 中的标识符, 同时也是任务的唯一标识符
    let imageData: Data // 图片元数据
    let serverPath: String // 上传地址

    let params: [String: AnyHashable]? // 额外参数

    let progress: UploadTaskProgress?
    let completion: UploadTaskCompletion // 上传回调

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(uploadVersion)
        hasher.combine(serverPath)
        if let params = params {
            hasher.combine(params)
        }
    }

    static func == (lhs: UploadTaskInfo, rhs: UploadTaskInfo) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

class UploadImageNetworkService {

    private let disposeBag = DisposeBag()

    // 用来保存上传到 Doc 的请求
    private let docRequestsDic: SafeDictionary<UploadTaskInfo, DocsRequest<Any>> = [:] + .readWriteLock

    init() {
        DocsLogger.info("UploadImageNetworkService init - \(addressOf(self))")
    }

    deinit {
        DocsLogger.info("UploadImageNetworkService deinit - \(addressOf(self))")
    }

    func addressOf<T: AnyObject>(_ o: T) -> String {
        let addr = unsafeBitCast(o, to: Int.self)
        return String(format: "%p", addr)
    }

    /// 上传接口 V1 - 根据前端给的地址上传到指定位置
    // 这里使用字典,是为了未来扩展参数
    // 目前 V1 接口要求
    // params["multiparts"]
    // params["request-header"]
    // 是要存在的
    func uploadImageV1(_ imageData: Data,
                       for uuid: String,
                       with params: [String: AnyHashable],
                       to serverPath: String,
                       progress: UploadTaskProgress? = nil,
                       completion: @escaping UploadTaskCompletion) {

        let task = UploadTaskInfo(
            uploadVersion: .doc,
            uuid: uuid,
            imageData: imageData,
            serverPath: serverPath,
            params: params,
            progress: progress,
            completion: completion
        )

        uploadImageToDoc(task)
    }

    /// 上传接口 V2.1 - 利用 V2 接口上传的图片，在复制粘贴的时候直接替换 token
    // 目前 V2.1 接口要求
    // params["dest"] = ["obj_type": xxx, "obj_token": xxx] // copy 到哪里
    // params["files"] = [xxxx] // 图片的 token
    func copyImage(
        for uuid: String,
        with params: [String: AnyHashable],
        completion: @escaping UploadTaskCompletion) {

        let task = UploadTaskInfo(
            uploadVersion: .copyTo,
            uuid: uuid,
            imageData: Data(), // 实际上没用
            serverPath: "",
            params: params,
            progress: nil,
            completion: completion
        )

        DocsLogger.info("upload image 插入V2.1 - 复制图片， uuid=\(uuid.encryptToken)", component: LogComponents.uploadImg)
        copyImage(task)
    }

    /// 取消所有任务
    func cancelAllTask() {
        DocsLogger.info("upload image 取消所有任务, docRequestsDic.count=\(docRequestsDic.count)", component: LogComponents.uploadImg)

        //取消docRequest请求
        docRequestsDic.forEach { (_, docRequst) in
            docRequst.cancel()
        }
        docRequestsDic.removeAll()
    }
}


private extension UploadImageNetworkService {

    private func uploadImageToDoc(_ task: UploadTaskInfo) {

        let dataCount = task.imageData.count // 文件大小
        let timeout = task.imageData.uploadTimeout() // 设置超时时间
        let uuid = task.uuid

        DocsLogger.info(
            "ready to upload ToDoc, uuid=\(task.uuid.encryptToken)", component: LogComponents.uploadImg
        )

        var header: [String: String] = [:]
        if let requestHeader = task.params?["request-header"] as? [String: String] {
            header = requestHeader
        }

        var multiparts: [String: Any] = ["size": dataCount, "type": "image/jpeg"]
        if let mp = task.params?["multiparts"] as? [String: Any] {
            multiparts.merge(other: mp)
        }

        // 创建请求
        let uploadingTaskForDoc = DocsRequest<Any>(
            path: task.serverPath,
            params: nil,
            trafficType: .upload)

        self.docRequestsDic.updateValue(uploadingTaskForDoc, forKey: task)

        uploadingTaskForDoc.set(headers: header)
        uploadingTaskForDoc.set(timeout: timeout)

        uploadingTaskForDoc.upload(multipartFormData: {(formData) in
            multiparts.forEach({ (key, value) in
                guard key != "file" else { return } // 这里是什么意思呢
                guard let data = "\(value)".data(using: .utf8, allowLossyConversion: false) else {
                    spaceAssertionFailure("parse value to utf8 data failure when upload image")
                    return
                }
                formData.append(data, withName: key)
            })
            // 该接口有坑，只设置mimetype不够，文件名也必须有拓展名
            formData.append(task.imageData, withName: "file", fileName: "\(uuid).jpeg", mimeType: "image/jpeg")
        }, rawResult: { [weak self] (data, _, error) in
            defer {
                self?.docRequestsDic.removeValue(forKey: task)
            }

            DocsLogger.info(
                "finish upload image",
                error: error,
                component: LogComponents.uploadImg
            )

            if let error = error {
                task.completion(.failure(.networkError(error)))
                return
            }

            guard let data = data else {
                task.completion(.failure(.dataIsNil))
                return
            }

            // 成功就回调 uuid + 网络数据
            let result = ["data": data]
            task.completion(.success((uuid, result)))
        })
    }

    private func copyImage(_ task: UploadTaskInfo) {
        guard let param = task.params else {
            task.completion(.failure(.lackOfNecessaryParams))
            DocsLogger.info("upload image failure - lack of necessary params", component: LogComponents.uploadImg)
            return
        }
        let params = param as [String: Any]

        let header = [
            "Content-Type": "application/json",
            "Accept": "application/json, text/plain, */*"
        ]

        let uploadingTaskForDoc = DocsRequest<Any>(
            path: OpenAPI.APIPath.driveMutiCopy,
            params: params
        )

        self.docRequestsDic.updateValue(uploadingTaskForDoc, forKey: task)

        uploadingTaskForDoc.set(method: .POST)
        uploadingTaskForDoc.set(headers: header)
        uploadingTaskForDoc.set(encodeType: .jsonEncodeDefault)
        uploadingTaskForDoc.start(result: { [weak self] (data, error) in

            defer {
                self?.docRequestsDic.removeValue(forKey: task)
            }

            if let error = error {
                task.completion(.failure(.networkError(error)))
                return
            }

            guard let data = data else {
                task.completion(.failure(.dataIsNil))
                return
            }

            // 成功就回调 uuid + 网络数据
            let result = ["data": data]
            task.completion(.success((task.uuid, result)))
        })
    }
}

private extension Data {
    func uploadTimeout() -> Double {
        let count = self.count
        let mb = Double(count / 1000 / 1000)

        var timeoutPerMB = UploadTimeoutPerMB.default // 默认上传时间 5S/MB * X MB
        if DocsNetStateMonitor.shared.accessType.isWifi() {
            timeoutPerMB = UploadTimeoutPerMB.wifi
        } else {
            timeoutPerMB = UploadTimeoutPerMB.celluar
        }

        return mb * timeoutPerMB + timeoutPerMB // 设置最少超时至少大于 5s + 真实超时时间
    }
}
