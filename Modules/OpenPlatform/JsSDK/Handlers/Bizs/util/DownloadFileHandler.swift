//
//  DownloadFileHandler.swift
//  LarkWeb
//
//  Created by 李论 on 2019/9/2.
//

import Alamofire
import LarkLocalizations
import LKCommonsLogging
import WebBrowser

class DownloadFileHandler: JsAPIHandler {

    static let logger = Logger.log(DownloadFileHandler.self, category: "Module.JSSDK")

    var needAuthrized: Bool {
        return true
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        /// 请求头
        let header = args["header"] as? [String: String]
        let onProgress = args["onProgress"] as? String
        var dataTotalLen = 0

        /// 下载文件是否过大，目前按照100M为上限
        var sizeExceedsLimit = false

        guard let urlStr = args["url"] as? String,
            let url = possibleURL(urlStr: urlStr) else {
                /// URL无效
                DownloadFileHandler.logger.log(level: .error, "url 错误,\(args)")
                callback.callbackFailure(param: NewJsSDKErrorAPI.invalidParameter(extraMsg: "url").description())
                return
        }

        /// 生成下载请求对象
        let downloadRequest = sdk.sessionManager.download(url,
                                                          method: .get,
                                                          headers: header,
                                                          to: { url, rsp in
                                                            let fileName = rsp.suggestedFilename ?? "unknown"
                                                            let des = LarkWebFileManager.pathForHttpResp(url: url, fileName: fileName, storageType: .Tmp)
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
                DownloadFileHandler.logger.warn("downloadRequest cancelled for unitCount > 100 * 1024 * 1024. url:\(urlStr)")
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
                let destinationURL = downloadResponse.destinationURL,
                let templatePath = LarkWebFileManager.toTemplatePath(absolutePath: destinationURL.path) else {
                    /// 失败回调
                    /// 如果是取消，需要回调取消的code和errormsg
                    if let error = downloadResponse.error as NSError?,
                        error.code == NSURLErrorCancelled {
                        callback.callbackFailure(param: sizeExceedsLimit ? NewJsSDKErrorAPI.DownloadFile.exceedsLimit.description() : NewJsSDKErrorAPI.DownloadFile.cancel.description())
                        DownloadFileHandler.logger.error("downloadRequest cancelled. url:\(urlStr)", error: error)
                        return
                    }
                    let errMsg = downloadResponse.error?.localizedDescription ?? ""
                callback.callbackFailure(param: NewJsSDKErrorAPI.downloadFail(extraMsg: errMsg).description())
                    DownloadFileHandler.logger.error("downloadRequest failed. url:\(urlStr) errMsg:\(errMsg)")
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
            let result = ["code": 0, "tempFilePath": templatePath] as [String: Any]
            callback.callbackSuccess(param: result)
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
