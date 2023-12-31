//
//  OpenDocumentHandler.swift
//  LarkWeb
//
//  Created by 李论 on 2019/9/6.
//

import UIKit
import LKCommonsLogging
import Foundation
import WebKit
import LarkFoundation
import EENavigator
import Alamofire
import WebBrowser
import ECOInfra

class OpenDocumentHandler: JsAPIHandler {
    static let logger = Logger.log(OpenDocumentHandler.self, category: "Module.JSSDK")
    var needAuthrized: Bool {
        return true
    }
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        if args["url"] != nil {
            ///预览API升级，使用url进行打开预览
            OpenDocumentHandler.logger.info("open by handleV2")
            handleV2(args: args, api: api, sdk: sdk, callback: callback)
            return
        }
        guard let templatePath = args["filePath"] as? String,
            let filePath = LarkWebFileManager.toAbsolutePath(templatePath: templatePath) else {
                OpenDocumentHandler.logger.log(level: .error, "filePath 为空\(String(describing: args["filePath"]))")
            callback.callbackFailure(param: NewJsSDKErrorAPI.invalidParameter(extraMsg: "filePath").description())
                return
        }
        guard LSFileSystem.fileExists(filePath: filePath) else {
            OpenDocumentHandler.logger.log(level: .error, "\(filePath) 不存在)")
            callback.callbackFailure(param: NewJsSDKErrorAPI.invalidParameter(extraMsg: "filePath").description())
            return
        }
        let fileType = args["fileType"] as? String ?? (filePath as NSString).pathExtension
        let supportTypes: Set<String> = ["doc", "docx", "xls", "xlsx", "ppt", "pptx", "pdf"]
        guard !fileType.isEmpty, supportTypes.contains(fileType) else {
            OpenDocumentHandler.logger.log(level: .error, "\(filePath) 文件类型不存在)")
            callback.callbackFailure(param: NewJsSDKErrorAPI.openDoc.fileFormateNotSupport.description())
            return
        }
        let fileName = LarkWebFileManager.getOriginFileName(absolutePath: filePath)
        let docVC = LarkWebDocumentPreviewController(filePath: filePath,
                                                     fileName: fileName,
                                                     fileType: fileType)
        Navigator.shared.push(docVC, from: api) // Global
        callback.callbackSuccess(param: ["code": 0])
    }

    ///Alamofire.SessionManager返回的response生成的建议文件名可能含非法字符，需要去掉；可能已经编码，需要解码
    private func formateFileName(fileName: String) -> String {
        ///将推荐的名字中的，换行符、非法字符、控制字符去掉，因为这些字符的文件名是不合法的
        var invalidCharacters = CharacterSet(charactersIn: ":/")
        invalidCharacters.formUnion(.newlines)
        invalidCharacters.formUnion(.illegalCharacters)
        invalidCharacters.formUnion(.controlCharacters)
        let formateFileName = fileName.components(separatedBy: invalidCharacters)
        .joined(separator: "")
        ///尝试将fileName进行URLdecode
        return URL(string: formateFileName)?.path ?? formateFileName
    }
    func handleV2(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        guard (args["url"] as? String) != nil else {
            OpenDocumentHandler.logger.error("url is nil")
            callback.callbackFailure(param: NewJsSDKErrorAPI.invalidParameter(extraMsg: "url").description())
            return
        }
        let method = requestMethodMap(originMethod: args["method"])
        let header = args["header"] as? [String: String]
        let body = args["body"] as? String
        let onProgress = args["onProgress"] as? String
        /// 下载文件是否过大，目前按照100M为上限
        var dataTotalLen = 0
        var sizeExceedsLimit = false
        guard let urlStr = args["url"] as? String,
            let url = possibleURL(urlStr: urlStr) else {
                /// URL无效
                DownloadFileHandler.logger.log(level: .error, "url 错误,\(args)")
                callback.callbackFailure(param: NewJsSDKErrorAPI.invalidParameter(extraMsg: "url").description())
                return
        }
        /// 生成下载请求对象
        let bodyData = body?.data(using: .utf8)
        //  编译不过？？？
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = bodyData
        req.allHTTPHeaderFields = header
        let downloadRequest = sdk.sessionManager.download(req, to: {[weak self] url, rsp in
            let unknownFileName = "unknown"
            ///将Alamofire建议的文件名suggestedFilename
            let fileName = self?.formateFileName(fileName: rsp.suggestedFilename ?? unknownFileName) ?? unknownFileName
            let des = LarkWebFileManager.pathForHttpResp(url: url,
                                                        fileName: fileName,
                                                         storageType: .Tmp)
            return (URL(fileURLWithPath: des), [.removePreviousFile])
        })
        /// 如果有taskId则保存住task，以便js一侧随时取消
        if let taskId = args["taskId"] as? String {
            sdk.downloadRequests[taskId] = downloadRequest
        }
        downloadRequest.downloadProgress { [weak self, weak downloadRequest, weak api] (progress) in
            /// 限制下载大小为100M
            if progress.totalUnitCount > 100 * 1024 * 1024 || progress.completedUnitCount > 100 * 1024 * 1024 {
                sizeExceedsLimit = true
                progress.cancel()
                downloadRequest?.cancel()
                OpenDocumentHandler.logger.warn("downloadRequest cancelled for unitCount > 100 * 1024 * 1024. url:\(urlStr)")
                return
            }
            guard let `self` = self else { return }

            dataTotalLen = Int(progress.totalUnitCount)
            let callInfo = self.progressInfo(totalBytes: Int(progress.totalUnitCount),
                                              receivedBytes: Int(progress.completedUnitCount),
                                              finish: false)
            callback.asyncNotify(event: onProgress, data: callInfo)
        }
        .response { [weak self, weak sdk, weak api] (downloadResponse) in

            guard let `self` = self, let sdk = sdk, let api = api else { return }

            /// 请求响应后就可以取消保存住的任务了
            if let taskId = args["taskId"] as? String {
                sdk.downloadRequests[taskId] = nil
            }
            guard let rspCode = downloadResponse.response?.statusCode,
                rspCode == 200 || rspCode == 206,
                downloadResponse.error == nil,
                let destinationURL = downloadResponse.destinationURL else {
                    /// 失败回调
                    /// 如果是取消，需要回调取消的code和errormsg
                    if let error = downloadResponse.error as NSError?,
                        error.code == NSURLErrorCancelled {
                        callback.callbackFailure(param: sizeExceedsLimit ? NewJsSDKErrorAPI.openDoc.exceedsLimit.description() : NewJsSDKErrorAPI.DownloadFile.cancel.description())
                        OpenDocumentHandler.logger.error("downloadRequest cancelled. url:\(urlStr)", error: error)
                        return
                    }
                    let errMsg = downloadResponse.error?.localizedDescription ?? ""
                callback.callbackFailure(param: NewJsSDKErrorAPI.openDoc.downloadFail(extraMsg: errMsg).description())
                    return
            }
            //由于原来的success和fail只能调用一次，现在 onProgress 是一个可以持续调用的方法
            //js层依赖这个state回调，实现 onProgress的清理逻辑
            let callInfo = self.progressInfo(totalBytes: dataTotalLen,
                                             receivedBytes: dataTotalLen,
                                             finish: true)
            callback.asyncNotify(event: onProgress, data: callInfo)

            /// 成功回调
            DownloadFileHandler.logger.log(level: .info, "download \(url) success")
            let filePath = destinationURL.path
            guard LSFileSystem.fileExists(filePath: filePath) else {
                OpenDocumentHandler.logger.log(level: .error, "\(filePath) 不存在)")
                callback.callbackFailure(param: NewJsSDKErrorAPI.invalidParameter(extraMsg: "url").description())
                return
            }
            let fileType = args["fileType"] as? String ?? (filePath as NSString).pathExtension
            let supportTypes: Set<String> = ["doc", "docx", "xls", "xlsx", "ppt", "pptx", "pdf"]
            guard !fileType.isEmpty, supportTypes.contains(fileType) else {
                OpenDocumentHandler.logger.log(level: .error, "\(filePath) 文件类型不存在)")
                callback.callbackFailure(param: NewJsSDKErrorAPI.openDoc.fileFormateNotSupport.description())
                return
            }
            let fileName = LarkWebFileManager.getOriginFileName(absolutePath: filePath)
            let docVC = LarkWebDocumentPreviewController(filePath: filePath,
                                                         fileName: fileName,
                                                         fileType: fileType)
            Navigator.shared.push(docVC, from: api) // Global
            callback.callbackSuccess(param: ["code": 0])
        }
    }

    private func requestMethodMap(originMethod: Any?) -> String {
        let method = originMethod as? String ?? "GET"
        switch method {
        case "GET", "POST":
            return method
        default:
            return "GET"
        }
    }

    private func progressInfo(
        totalBytes: Int,
        receivedBytes: Int,
        finish: Bool
    ) -> [String: Any] {
        let prog = Int((Double(receivedBytes) / max(Double(totalBytes), 1.0)) * 100)
        let progressInfo = [
            "totalBytesExpectedToWrite": totalBytes,
            "totalBytesWritten": receivedBytes,
            "progress": prog
            ] as [String: Any]
        let state = finish ? 0:1
        return  ["state": state, "data": progressInfo]
    }
}
