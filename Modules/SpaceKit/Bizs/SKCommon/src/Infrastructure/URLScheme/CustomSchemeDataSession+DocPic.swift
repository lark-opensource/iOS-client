//
//  CustomSchemeDataSession+DocPic.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/12/13.
// swiftlint:disable line_length

import SKFoundation

extension CustomSchemeDataSession {
    func downLoadPicByDocRequest(originUrl: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let beginTime = Date.timeIntervalSinceReferenceDate
        if let data = self.newCacheAPI.getImage(byKey: originUrl.path, token: self.getFileToken()) as? Data, UIImage(data: data) != nil {
            DocsLogger.info("downloadPic,hasCache=true, token=\(DocsTracker.encrypt(id: request.url?.absoluteString ?? ""))")
            let picSize: Int = data.count
            let costTime = Date.timeIntervalSinceReferenceDate - beginTime
            SKDownloadPicStatistics.downloadPicReport(0, type: -1, from: .customSchemeDocs, fileType: self.fileType, picSize: picSize, cost: Int(costTime * 1000), cache: .docCache)
            completionHandler(data, nil, nil)
            return
        }

        DocsLogger.info("downloadPic,hasCache=false, token=\(DocsTracker.encrypt(id: request.url?.absoluteString ?? ""))")
        let requestModify = getModifyRequest(originUrl: originUrl)
        guard let request = requestModify else {
            DispatchQueue.global().async {
                let error = NSError(domain: "url error", code: -1, userInfo: nil)
                completionHandler(nil, nil, error)
            }
            spaceAssertionFailure()
            return
        }
        request.setValue(DocsCustomHeaderValue.fromMobileWeb, forHTTPHeaderField: DocsCustomHeader.fromSource.rawValue)
        self.sessionDelegate?.session(self, didBeginWith: request)
        self.sessionTask = DocsRequest(request: request as URLRequest, trafficType: .docsFetch)
        self.sessionTask?.start(rawResult: { [weak self] (data, response, error) in
            guard let self = self else { return }
            var errorCode: Int = 0
            var picSize: Int = 0
            if let data = data, error == nil {
                var picDataValid: Bool = true
                if #available(iOS 13.0, *) {
                    if let httpRespnose = response as? HTTPURLResponse,
                        let contentType = httpRespnose.value(forHTTPHeaderField: "Content-Type"),
                        contentType.contains("json"),
                        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        picDataValid = false
                        errorCode = json["code"] as? Int ?? -1
                        DocsLogger.info("downloadPic,token=\(DocsTracker.encrypt(id: request.url?.absoluteString ?? "")), errorCode=\(errorCode)")
                    }
                }
                picSize = data.count
                completionHandler(data, response, nil)
                if picDataValid {
                    DispatchQueue.global().async {
                        self.newCacheAPI.storeImage(data as NSCoding, token: self.getFileToken(), forKey: originUrl.path, needSync: false)
                    }
                }
            } else if let data = self.newCacheAPI.getImage(byKey: originUrl.path, token: self.getFileToken()) as? Data {
                completionHandler(data, nil, nil)
            } else {
                DocsLogger.info("downloadPic,token=\(DocsTracker.encrypt(id: request.url?.absoluteString ?? "")), error=\(String(describing: error))")
                completionHandler(nil, nil, error)
                if let httpRespnose = response as? HTTPURLResponse {
                    if httpRespnose.statusCode != 200 {
                        errorCode = httpRespnose.statusCode
                    } else {
                        errorCode = -1
                    }
                }
            }

            let costTime = Date.timeIntervalSinceReferenceDate - beginTime
            SKDownloadPicStatistics.downloadPicReport(errorCode, type: -1, msg: "\(String(describing: error))", from: .customSchemeDocs, fileType: self.fileType, picSize: picSize, cost: Int(costTime * 1000), cache: .none)
        })
    }

}
