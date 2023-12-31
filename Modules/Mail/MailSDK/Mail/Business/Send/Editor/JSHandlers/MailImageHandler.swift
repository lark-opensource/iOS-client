//
//  MailSelectImageService.swift
//  MailSDK
//
//  Created by majx on 2019/6/14.
//

import Foundation
import Photos
import LarkUIKit
import Kingfisher
import LarkFoundation
import Homeric
import RxSwift
import RustPB
import LarkActionSheet
import EENavigator
import ByteWebImage
import LarkAssetsBrowser
import RxRelay
import LarkSensitivityControl
import LarkStorage

extension EditorJSService {
    // mail的前端接口，根据前端的实际接口情况进行替换
    static let mailPickImage = EditorJSService(rawValue: "biz.util.selectImage")
    static let imgDomChange = EditorJSService(rawValue: "biz.core.imgDomDidChange")
    static let imgInsertDone = EditorJSService(rawValue: "biz.img.insertDone")
    static let imgUploadRetry = EditorJSService(rawValue: "biz.util.retryUploadImg")
    static let removeImg = EditorJSService(rawValue: "biz.util.deleteUploadImg")
    static let uploadImg = EditorJSService(rawValue: "biz.img.insertUploadedImg")
}

class MailImageHandler: EditorJSServiceHandler {
    let disposeBag = DisposeBag()
    var threadID: String?
    let docsScheme = "docsource://"
    private var tokenUuidCache: [String: (String, String)] = [:]

    // Contains models that represent the status of every img in a single email, for example the upload progress of the image.
    private(set) var imageInfoDic: [String: MailImageInfo] = [:]
    private var uploadUUIDs: [String] = []
    let handleServices: [EditorJSService] = [.mailPickImage, .imgDomChange, .imgInsertDone, .imgUploadRetry, .removeImg, .uploadImg]
    weak var uiDelegate: MailSendController?
    private var serviceProvider: MailSharedServicesProvider?
    private let imageUploader: MailImageUploader
    private var pickImageJsName: String?
    let dataManager = MailSendDataMananger.shared
    var errorImg: [String: MailImageInfo] {
        return imageInfoDic.filter({ $0.value.status == .error })//上传失败的图片
    }
    
    var isContainsErrorImg: Bool {
        return imageInfoDic.filter({ $0.value.status == .error }).count > 0
    }
    var isContainsUploadingImg: Bool {
        return imageInfoDic.filter({ $0.value.status == .uploading }).count > 0
    }

    var successedImgs: [MailImageInfo] {
        var imgs = [MailImageInfo]()
        for (_, value) in imageInfoDic where value.status == .complete {
            imgs.append(value)
        }
        return imgs
    }
    var removedImages: [String: MailImageInfo] = [:]

    var uploadTaskInfos: [MailImageUploader.UploadTaskInfo] = []
    private let insertDoneStatusQueue = DispatchQueue(label: "MailImageHandler.Serial", qos: .userInitiated)
    var insertDoneStatus = BehaviorRelay<Set<String>>(value: Set([]))

    init(with uploaderDelegate: MailUploaderDelegate) {
        self.serviceProvider = uploaderDelegate.serviceProvider
        self.imageUploader = MailImageUploader(with: uploaderDelegate)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceivedDownloadDriveImageNotification(_:)),
                                               name: Notification.Name.Mail.MAIL_DOWNLOAD_DRIVE_IMAGE,
                                               object: nil)
    }

    @objc
    func didReceivedDownloadDriveImageNotification(_ notification: Notification) {
        guard let downloadResponse = notification.object as? Space_Drive_V1_PushDownloadCallback else {
            mailAssertionFailure("unexpected param")
            return
        }
        DispatchQueue.main.async {
            self.handleDrivePush(downloadResponse: downloadResponse)
        }
    }

    // 三方客户端对标此方法处理 copy docs的下载成功回调
    func handleDrivePush(downloadResponse: Space_Drive_V1_PushDownloadCallback) {
        guard let imgInfo = imageInfoDic.first(where: { (_, value) -> Bool in
            return value.driveKey == downloadResponse.key
        })?.value else { return }
        let src = imgInfo.src
        let components = URLComponents(string: src)
        var contentType = "jpeg"
        components?.queryItems?.forEach({ (item) in
            switch item.name {
            case "contentType":
                if let value = item.value {
                    contentType = value
                }
            default:
                ()
            }
        })
        let uuid = imgInfo.uuid
        let failAction = {
            //这里不更新一下status就调用JS的话会有bug
            self.imageInfoDic[uuid]?.status = .error
            let jsStr = "window.command.setDriveImgError(`\(uuid)`)"
            self.uiDelegate?.evaluateJavaScript(jsStr)
        }
        if downloadResponse.status == .success {
            let cachePath = makeImageUploadingPath(with: uuid, isGif: imgInfo.name.mail.isGif)
            let data = try? Data.read(from: cachePath)
            guard let imgData = data else {
                mailAssertionFailure("empty data in download drive image")
                failAction()
                return
            }
            let user = serviceProvider?.user
            serviceProvider?.cacheService.set(object: imgData as NSCoding, for: imgInfo.getCacheKey(userToken: user?.token, tenantID: user?.tenantID))

            let info = makeImageUploadTaskInfo(uuid: uuid, filePath: cachePath.absoluteString, fileSize: Int64(imgData.count), fileName: "\(uuid).\(contentType)", needSaveCidSrc: true)
            if Store.settingData.mailClient {
                imageUploader.uploadImages([info], threadId: uiDelegate?.getDraftId())
                insertDoneStatusAccept(newId: uuid)
            } else {
                imageUploader.uploadImages([info], threadId: uiDelegate?.getThreadId())
            }

        } else if downloadResponse.status == .failed {
            failAction()
        }
    }
    
    private func insertDoneStatusAccept(newId: String) {
        insertDoneStatusQueue.async { [weak self] in
            guard let self = self else { return }
            var vals = self.insertDoneStatus.value
            vals.insert(newId)
            MailLogger.info("insertDoneStatusAccept current: \(vals), insert: \(newId)")
            self.insertDoneStatus.accept(vals)
        }
    }
    
    private func insertDoneStatusRemove(id: String) {
        insertDoneStatusQueue.async { [weak self] in
            guard let self = self else { return }
            var vals = self.insertDoneStatus.value
            vals.remove(id)
            MailLogger.info("insertDoneStatusAccept current: \(vals), remove: \(id)")
            self.insertDoneStatus.accept(vals)
        }
    }

    func resetImageInfo(_ infos: [MailImageInfo]) {
        imageInfoDic.removeAll()
        infos.forEach { (info) in
            var info = info
            info.status = .complete
            imageInfoDic[info.uuid] = info
        }
    }

    func handle(params: [String: Any], serviceName: String) {
        if serviceName == EditorJSService.mailPickImage.rawValue {
            guard let callback = params["callback"] as? String else {
                mailAssertionFailure("all the event that handle by 'MailImageHandler' must have a callback")
                return
            }
            pickImageJsName = callback
        } else if serviceName == EditorJSService.imgDomChange.rawValue {
            MailLogger.info("[mail_client_editor] handle - imgDomChange")
            handleImgDomChange(params)
        } else if serviceName == EditorJSService.imgInsertDone.rawValue {
            MailLogger.info("[mail_client_editor] handle - imgInsertDone")
            handleImgInsertDone(params)
        } else if serviceName == EditorJSService.imgUploadRetry.rawValue {
            MailLogger.info("[mail_client_editor] handle - imgUploadRetry")
            handleImgUploadRetry(params)
            
        } else if serviceName == EditorJSService.removeImg.rawValue {
            MailLogger.info("[mail_client_editor] handle - removeImg")
            handleRemoveImg(params)
        } else if serviceName == EditorJSService.uploadImg.rawValue {
            MailLogger.info("[mail_client_editor] handle - uploadImg")
            handleUploadImg(params)
        }
    }
    
    private func setDriveImgSuccess(uuid: String, token: String, dataSize: Int64, imageName: String) {
        let jsStr = "window.command.setDriveImgSuccess(`\(uuid)`, `\(token)`, \(dataSize), `\(imageName)`)"
        MailLogger.info("[mail_client_upload] [mail_client_editor] setDriveImgSuccess excute js `\(uuid)`")
        self.uiDelegate?.evaluateJavaScript(jsStr)
    }

    // 只有在撤销的场景才能生效触发
    func handleUploadImg(_ params: [String: Any]) {
        MailLogger.info("[mail_client_editor] handle handleUploadImg, params: \(params)")
        guard let uuid = params["uuid"] as? String else { mailAssertionFailure("must have uuid"); return; }
        if let image = removedImages[uuid], let token = image.token {
            MailLogger.info("[mail_client_upload] [mail_client_editor] handleUploadImg for removedImage excute js")
            self.setDriveImgSuccess(uuid: uuid, token: token, dataSize: image.dataSize, imageName: image.name)
            self.uiDelegate?.draft?.content.images.append(image)
            removedImages.removeValue(forKey: uuid)
        } else {
            getCachedImgForPaste(uuid: uuid) { [weak self] imageData in
                guard let self = self else { return }
                guard let imageData = imageData else {
                    MailLogger.error("[mail_client_upload] [mail_client_editor] handleUploadImg failed to get data `\(uuid)`")
                    return
                }
                guard let image = UIImage(data: imageData) else {
                    MailLogger.error("[mail_client_upload] [mail_client_editor] handleUploadImg convert to image failed `\(uuid)`")
                    return
                }
                let imgAttribute: MailImageAttribute = (imageData, image.size, uuid)
                self.jsInsertImage([imgAttribute])
            }
        }
    }
    
    private func getCachedImgForPaste(uuid: String, callback: @escaping (_ imageData: Data?) -> Void) {
        let user = serviceProvider?.user
        if let imageData = serviceProvider?.cacheService.object(forKey: MailImageInfo.getImageUrlCacheKey(urlString: "cid:\(uuid)", userToken: user?.token, tenantID: user?.tenantID)) as? Data {
            MailLogger.info("[mail_client_upload] [mail_client_editor] getCachedImgForPaste use data from cache `\(uuid)`")
            callback(imageData)
        } else if Store.settingData.mailClient,
                  let draftInfo = serviceProvider?.cacheService.object(forKey: "draft_cid:\(uuid)") as? [String: String],
                  let draftId = draftInfo["draft_id"] {
            MailLogger.info("[mail_client_upload] [mail_client_editor] getCachedImgForPaste get from Rust `\(uuid)`, draftId: \(draftId)")
            MailDataSource.shared
                .mailDownloadRequest(token: uuid, messageID: draftId, isInlineImage: true)
                .subscribe(onNext: { [weak self] resp in
                    guard let self = self else { return }
                    if !resp.filePath.isEmpty {
                        MailLogger.info("[mail_client_upload] [mail_client_editor] getCachedImgForPaste cache from Rust `\(uuid)`, draftId: \(draftId)")
                        var path = resp.filePath
                        var absPath = AbsPath(path)
                        var data: Data?
                        if absPath.exists {
                            data = try? Data.read(from: absPath)
                        } else {
                            // 兜底
                            path = path.correctPath
                            data = try? Data.read(from: AbsPath(path))
                        }
                        callback(data)
                    } else {
                        MailLogger.info("[mail_client_upload] [mail_client_editor] getCachedImgForPaste download from Rust `\(uuid)`, draftId: \(draftId)")
                        let taskWrapper = RustSchemeTaskWrapper(task: nil, webURL: nil)
                        taskWrapper.key = resp.key
                        taskWrapper.msgID = draftId
                        taskWrapper.fileToken = uuid
                        taskWrapper.inlineImage = true
                        taskWrapper.downloadChange = MailDownloadPushChange(status: .pending, key: resp.key)
                        self.serviceProvider?.imageService.startDownTask((resp.key, taskWrapper))
                        self.serviceProvider?.imageService
                            .downloadTask
                            .asObservable()
                            .filter({ $0.0 == resp.key })
                            .subscribe { (key, task) in
                                guard let task = task else { return }
                                guard let change = task.downloadChange else {
                                    MailLogger.error("[mail_client_upload] [mail_client_editor] getCachedImgForPaste ❌ 有对应key的push，但缓存没有task")
                                    return
                                }
                                switch change.status {
                                case .success:
                                    guard let path = change.path else {
                                        MailLogger.error("[mail_client_upload] [mail_client_editor] getCachedImgForPaste rust success-- uuid: \(uuid) key: \(change.key) but path is nil")
                                        return
                                    }
                                    let data = AbsPath(path).exists ? try? Data.read(from: AbsPath(path)) : try? Data.read(from: AbsPath(path.correctPath))
                                    callback(data)
                                case .inflight, .pending:
                                    break
                                case .failed, .cancel:
                                    MailLogger.error("[mail_client_upload] [mail_client_editor] getCachedImgForPaste rust fail -- uuid: \(uuid) key: \(change.key), status \(change.status)")
                                    callback(nil)
                                @unknown default:
                                    callback(nil)
                                }
                            } onError: { e in
                                MailLogger.error("[mail_client_upload] [mail_client_editor] getCachedImgForPaste rust error -- uuid: \(uuid) e: \(e)")
                                callback(nil)
                            }.disposed(by: self.disposeBag)
                    }
                }, onError: { (error) in
                    MailLogger.info("[mail_client_upload] [mail_client_editor] getCachedImgForPaste for \(uuid) error: \(error)")
                    callback(nil)
                }).disposed(by: disposeBag)
        } else {
            MailLogger.info("[mail_client_upload] [mail_client_editor] getCachedImgForPaste noData `\(uuid)`")
            callback(nil)
        }
    }
    
    func removeFailedImgs() {
        let infos: [String: MailImageInfo] = imageInfoDic.filter({$0.value.status == .error || $0.value.status == .uploading})
        for info in infos {
            self.imageInfoDic.removeValue(forKey: info.key)
            self.uiDelegate?.evaluateJavaScript("window.command.deleteImgDom([`\(info.key)`])")
        }
    }

    func handleRemoveImg(_ params: [String: Any]) {
        guard let uuid = params["uuid"] as? String else { mailAssertionFailure("must have uuid"); return; }
        imageInfoDic.removeValue(forKey: uuid)
        let count = self.uiDelegate?.draft?.content.images.count ?? 0
        if let index = self.uiDelegate?.draft?.content.images.firstIndex(start: 0, end: count, where: ({ $0.uuid == uuid })) {
            if let existImageInfo = self.uiDelegate?.draft?.content.images[index] {
                self.removedImages.updateValue(existImageInfo, forKey: uuid)
            }
            self.uiDelegate?.draft?.content.images.remove(at: index)
        }
    }
    
    func UploadRetryAll(){
        for (uuid, _) in errorImg {
            guard var imgInfo = imageInfoDic[uuid] else { mailAssertionFailure("missing info"); continue; }
            if imgInfo.src.hasPrefix(MailCustomScheme.cid.rawValue) {
                let fileUploadingPath = self.makeImageUploadingPath(with: uuid, isGif: imgInfo.name.mail.isGif)
                let blockid = uuid
                self.uiDelegate?.evaluateJS(js: "window.command.setImgRetry(`\(blockid)`, `\(uuid)`)")
                let taskInfo = self.makeImageUploadTaskInfo(uuid: uuid,
                                                            filePath: fileUploadingPath.absoluteString,
                                                            fileSize: imgInfo.dataSize,
                                                            fileName: imgInfo.name)
                if Store.settingData.mailClient {
                    self.imageUploader.uploadImages([taskInfo], threadId: self.uiDelegate?.getDraftId())
                } else {
                    self.imageUploader.uploadImages([taskInfo], threadId: self.uiDelegate?.getThreadId())
                }
            } else {
                self.downloadDriveImg(uuid: uuid, src: imgInfo.src)
            }
            imgInfo.status = .uploading
            imageInfoDic[uuid] = imgInfo
        }
    }
    
    func handleImgUploadRetry(_ params: [String: Any]) {
        guard let uuid = params["uuid"] as? String,
              let blockid = params["blockId"] else { mailAssertionFailure("must have cid"); return }
        guard var info = imageInfoDic[uuid] else { mailAssertionFailure("missing info"); return }
        //上传图片失败时，点击图片即触发重传，不再显示actionSheet
        if info.src.hasPrefix(MailCustomScheme.cid.rawValue) {
            let fileUploadingPath = self.makeImageUploadingPath(with: uuid, isGif: info.name.mail.isGif)
            self.uiDelegate?.evaluateJS(js: "window.command.setImgRetry(`\(blockid)`, `\(uuid)`)")
            let taskInfo = self.makeImageUploadTaskInfo(uuid: uuid,
                                                        filePath: fileUploadingPath.absoluteString,
                                                        fileSize: info.dataSize,
                                                        fileName: info.name)
            if Store.settingData.mailClient {
                self.imageUploader.uploadImages([taskInfo], threadId: self.uiDelegate?.getDraftId())
            } else {
                self.imageUploader.uploadImages([taskInfo], threadId: self.uiDelegate?.getThreadId())
            }
        } else {
            self.downloadDriveImg(uuid: uuid, src: info.src)
        }
        info.status = .uploading
        imageInfoDic[uuid] = info
    }

    func downloadDriveImg(uuid: String, src: String) {
        MailLogger.info("[mail_client_upload] downloadDriveImage uuid: \(uuid)")
        let cachePath = makeImageUploadingPath(with: uuid)
        let jsStr1 = "window.command.setDriveImgProgress(`\(uuid)`, 0)"
        uiDelegate?.evaluateJavaScript(jsStr1)
        imageInfoDic[uuid] = MailImageInfo(uuid: uuid, src: src, width: "0", height: "0")
        let downloadSrc = src.replacingOccurrences(of: docsScheme, with: "https://")

        dataManager.downloadImg(urlStr: downloadSrc, localPath: cachePath.absoluteString).subscribe(onNext: { [weak self] (key) in
            // This callback only means Rust kick off a request, the upcoming image data will be reveived in function 'handleDrivePush'
            guard let `self` = self else { return }
            self.imageInfoDic[uuid]?.driveKey = key
            MailLogger.info("drive download key: \(key)")
        }, onError: { [weak self] (err) in
            let jsStr = "window.command.setDriveImgError(`\(uuid)`)"
            self?.uiDelegate?.evaluateJavaScript(jsStr)
            self?.imageInfoDic[uuid]?.status = .error
            mailAssertionFailure("error in upload img \(err)")
        }).disposed(by: disposeBag)
    }

    func handleImgInsertDone(_ params: [String: Any]) {
        MailLogger.info("[mail_client_upload] handleImgInsertDone image data for params: \(params)")
        guard let uuid = params["uuid"] as? String else { return }
        if errorImg.keys.contains(uuid) {
            let jsStr = "window.command.setDriveImgError(`\(uuid)`)"
            MailLogger.error("vvImage-uid ori setDriveImgProgress 执行js `\(jsStr)`")
            self.uiDelegate?.evaluateJavaScript(jsStr)
        }
        if let _ = params["token"] as? String, let existImageInfo = imageInfoDic[uuid], let existToken = existImageInfo.token {
            // 已经存在该图片，不需要重新上传或更换token，直接使用原token setDriveSuccess
            MailLogger.info("[mail_client_editor] handleImgInsertDone setDriveImgSuccess")
            self.setDriveImgSuccess(uuid: existImageInfo.uuid, token: existToken, dataSize: existImageInfo.dataSize, imageName: existImageInfo.name)
        } else {
            // 新的图片
            let urlString = "cid:\(uuid)"
            // 三方客户端传此id给rust去upload
            if Store.settingData.mailClient {
                MailLogger.info("[mail_client_upload] uploadImages: \(uploadTaskInfos.map({ $0.uuid })) paths: \(uploadTaskInfos.map({ $0.filePath })))")
                insertDoneStatusAccept(newId: uuid)
            }
            let user = serviceProvider?.user
            guard let data = serviceProvider?.cacheService.object(forKey: MailImageInfo.getImageUrlCacheKey(urlString: urlString, userToken: user?.token, tenantID: user?.tenantID)) as? Data else {
                MailLogger.error("[mail_client_upload] no image data for cid:\(uuid)")
                return
            }
            guard let imageInfo = serviceProvider?.cacheService.object(forKey: uuid) as? [String: String],
                  let token = imageInfo["fileToken"] else {
                      MailLogger.info("no image info for cid:\(uuid)")
                      return
                  }

            var format = "png"
            if let f = MailImageHandler.imageFormatFromImageData(data: data) {
                format = f
            }
            self.tokenUuidCache[token] = (uuid, format)
            self.replaceToken(tokenSet: [token])
        }
    }

    static func imageFormatFromImageData(data: Data) -> String? {
        var bytes = [UInt8](repeating: 0, count: 1)
        data.copyBytes(to: &bytes, count: 1)
        switch bytes[0] {
        case 0xFF:
            return "jpeg"
        case 0x89:
            return "png"
        case 0x47:
            return "gif"
        case 0x49, 0x4D:
            return "tiff"
        default:
            return nil
        }
    }

    func handleImgDomChange(_ params: [String: Any]) {
        MailLogger.info("vvImage-uid handleImgDomChange uuid: \(params["uuid"])")
        guard let src = params["src"] as? String,
              let uuid = params["uuid"] as? String else { return }
        if !src.hasPrefix("data:image") {
            // data的base64数据过大，不打log
            MailLogger.info("vvImage-uid handleImgDomChange uuid: \(uuid)")
        }
        if FeatureManager.open(.copyBlob) && src.hasPrefix("data:image"), let base64Regex = try? NSRegularExpression(pattern: "data:image\\/.+;base64,(.+)", options: .caseInsensitive) {
            // blob的场景，editor先转换成base64，native需要上传图片
            var cost: Int = -1
            if let startTime = params["startTime"] as? Double {
                let handleTime = Date().timeIntervalSince1970 * 1000
                cost = Int(handleTime - startTime)
            }
            let mutableSrc = NSMutableString(string: src)
            if let match = base64Regex.firstMatch(in: mutableSrc as String, options: .reportCompletion, range: NSRange(location: 0, length: mutableSrc.length)), match.numberOfRanges >= 2 {
                let base64 = mutableSrc.substring(with: match.range(at: 1))
                if let data = Data(base64Encoded: base64), let image = UIImage(data: data) {
                    let dataBytes = data.count
                    MailTracker.log(event: "mail_sendmail_insert_image_dev", params: ["block_time": cost, "image_size": dataBytes])
                    MailLogger.info("MailSend insert image called block: \(cost)ms, size: \(dataBytes)bytes")
                    startUploadImages([(data, image.size, uuid)])
                }
            }
        } else if src.hasPrefix("http") || src.hasPrefix(docsScheme) {
            MailLogger.info("vvImage-uid handleImgDomChange uuid: \(uuid)")
            guard src.contains("/space/api/") else {
                MailLogger.info("not drive domain image")
                return
            }
            guard let map = params["imgParams"] as? [String: Any],
                let token = map["token"] as? String, !token.isEmpty else {
                MailLogger.info("imgdomchange token is empty")
                return
            }
            var contentType = "png"
            if let type = map["contentType"] as? String {
                contentType = type
            }
            self.tokenUuidCache[token] = (uuid, contentType)
            if FeatureManager.open(.copyDrivePic) {
                self.replaceToken(tokenSet: [token], uuid: uuid, src: src) // copy Docs
            } else {
                // TODO:VVLONG 处理拷贝的场景
                downloadDriveImg(uuid: uuid, src: src)
            }
        }
    }
    
    private func replaceTokenFailProcess(uuid: String, src: String) {
        guard !uuid.isEmpty && !src.isEmpty else { return }
        downloadDriveImg(uuid: uuid, src: src)
    }
    private func replaceToken(tokenSet: Set<String>, uuid: String = "", src: String = "") {
        guard tokenSet.count > 0 else {
            MailLogger.error("token is empty")
            replaceTokenFailProcess(uuid: uuid, src: src)
            return
        }
        var req = SendHttpRequest()
        req.url = MailDriveAPI.getChangeTokenUrl(provider: serviceProvider?.provider.configurationProvider)
        req.method = .post
        let session = serviceProvider?.user.token ?? ""
        var header: [String: String] = [:]
        let sessionStr = "session=" + session
        header["Cookie"] = sessionStr
        req.headers = header
        var json: [String: Any] = [:]
        var file_array: [Dictionary<String, String>] = []
        for token in tokenSet {
            let file = ["file_token": token]
            file_array.append(file)
        }
        json["files"] = file_array
        var mountNodePoint: String = serviceProvider?.user.token ?? ""
        if self.uiDelegate?.isSharedAccount() ?? false, let sharedAccountId = self.uiDelegate?.sharedAccountId {
            mountNodePoint = "shared_mailbox_" + sharedAccountId
        }
        var mount_dic: [String: String] = [:]
        mount_dic["mount_point"] = "email"
        mount_dic["mount_key"] = mountNodePoint
        json["dest_mount_info"] = mount_dic
        guard let body = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            MailLogger.info("handleImgDomChange json transform fail")
            replaceTokenFailProcess(uuid: uuid, src: src)
            return
        }
        req.body = body
        req.retryNum = 3
        MailDataServiceFactory.commonDataService?.sendHttpRequest(req: req).subscribe(onNext: { [weak self] (resp) in
            guard let `self` = self else { return }
            guard let json = try? JSONSerialization.jsonObject(with: resp.body, options: []) else {
                MailLogger.info("parse resp json fail")
                self.replaceTokenFailProcess(uuid: uuid, src: src)
                return
            }
            guard let strJson = json as? [String: Any] else {
                MailLogger.info("json to stringJson fail")
                self.replaceTokenFailProcess(uuid: uuid, src: src)
                return
            }
            let dataMap = strJson["data"]
            guard let dataDic = dataMap as? [String: Any],
                  let fileMap = dataDic["succ_files"] as? [String: Any] else {
                MailLogger.info("parse succ_files fail")
                self.replaceTokenFailProcess(uuid: uuid, src: src)
                return
            }
            for token in tokenSet {
                if let newToken = fileMap[token] as? String,
                   !newToken.isEmpty {
                    let (uuid, type) = self.tokenUuidCache[token] ?? ("", "")
                    self.serviceProvider?.cacheService.set(object: ["fileToken": newToken] as NSCoding,
                                         for: uuid)
                    self.tokenUuidCache.removeValue(forKey: token)
                    MailLogger.info("[mail_client_editor] replaceToken setDriveImgSuccess")
                    self.setDriveImgSuccess(uuid: uuid, token: newToken, dataSize: 100, imageName: "\(uuid).\(type)")
                } else {
                    MailLogger.info("token not find in map")
                }
            }
        }, onError: { [weak self] (err) in
            MailLogger.error("http multicopy failed, \(err)")
            self?.replaceTokenFailProcess(uuid: uuid, src: src)
        }).disposed(by: self.disposeBag)
    }
}

// MARK: - AssetPickerSuiteViewDelegate
extension MailImageHandler: AssetPickerSuiteViewDelegate {
    typealias MailImageAttribute = (imgData: Data, imgSize: CGSize, uuid: String?)

    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        MailTracker.insertLog(insertType: MailTracker.InsertType.image)
        var imgAttributes: [MailImageAttribute] = [MailImageAttribute]()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        let assets = result.selectedAssets
        let isOrigin = result.isOriginal

        // When 'isSynchronous' is true,
        // the 'PHImageManager.default().requestImageData' api will block the calling thread,
        // so it's safer to call this api in a global queue instead of main queue.
        // Also, we will compress image data inside this loop, so don't run this in main thread
        DispatchQueue.global(qos: .userInteractive).async {
            for asset in assets {
                switch asset.mediaType {
                case .image:
                    if let image = asset.editImage {
                        if let imgData = image.jpegData(compressionQuality: 1) {
                            imgAttributes.append((imgData: imgData, imgSize: image.size, nil))
                        }
                    } else {
                        // iOS 13 isSynchronous 设置无效，参考MessageImage，利用信号量异步变同步
                        /// 原图
                        do {
                            let token = Token(MailSensitivityApiToken.addImage)
                            let requestImageDataResultHandler = { (imgData: Data?) in
                                if var imgData = imgData,
                                   let image = UIImage(data: imgData)?.lu.fixOrientation() {
                                    /// 如果是不支持的图片，则转成UIImage再取数据
                                    if asset.isGIF {
                                        MailLogger.info("insert gif img")
                                        imgAttributes.append((imgData: imgData, imgSize: image.size, uuid: nil))
                                    } else if self.checkIsSupportImageFormat(imageData: imgData) {
                                        if !result.isOriginal, let compressData = image.data(quality: 0.6) {
                                            imgData = compressData
                                        }
                                        imgAttributes.append((imgData: imgData, imgSize: image.size, uuid: nil))
                                    } else if let newImgData = image.jpegData(compressionQuality: result.isOriginal ? 1 : 0.5) {
                                        imgAttributes.append((imgData: newImgData, imgSize: image.size, uuid: nil))
                                    } else {
                                        mailAssertionFailure("fail to convert data")
                                    }
                                }
                                MailTracker.log(event: Homeric.EMAIL_DRAFT_ADD_IMAGE, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .toolbar)])
                            }
                            if #available(iOS 13.0, *) {
                                _ = try AlbumEntry.requestImageDataAndOrientation(forToken: token,
                                                                                  manager: PHImageManager.default(),
                                                                                  forAsset: asset,
                                                                                  options: options) { (imgData, _, _, _) in
                                    requestImageDataResultHandler(imgData)
                                }
                            } else {
                                _ = try AlbumEntry.requestImageData(forToken: token,
                                                                    manager: PHImageManager.default(),
                                                                    forAsset: asset,
                                                                    options: options) { (imgData, _, _, _) in
                                    requestImageDataResultHandler(imgData)
                                }
                            }
                        } catch {
                            DispatchQueue.main.async {
                                if let view = self.uiDelegate?.view {
                                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Shared_AddAttachment_UnableToAdd_Text, on: view)
                                }
                            }
                        }
                    }
                case .video:
                    let op = PHVideoRequestOptions()
                    op.version = .current
                    op.deliveryMode = .automatic
                    guard !asset.isInICloud else {
                        DispatchQueue.main.async {
                            if let view = self.uiDelegate?.view {
                                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: view)
                            }
                        }
                        return
                    }
                    do {
                        _ = try AlbumEntry.requestAVAsset(forToken: Token(MailSensitivityApiToken.addVideo),
                                                          manager: PHImageManager.default(),
                                                          forVideoAsset: asset,
                                                          options: op) { (avasset, _, _) in
                            guard let urlAsset = avasset as? AVURLAsset else {
                                mailAssertionFailure("type error")
                                return
                            }
                            let url = urlAsset.url
                            let name = String(url.absoluteString.split(separator: "/").last ?? "")
                            let value = try? url.resourceValues(forKeys: [.fileSizeKey])
                            let model = MailSendFileModel(name: name, fileURL: url, size: UInt(value?.fileSize ?? 0))
                            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                                self.uiDelegate?.insertAttachment(fileModel: model)
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            if let view = self.uiDelegate?.view {
                                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Shared_AddAttachment_UnableToAdd_Text, on: view)
                            }
                        }
                    }
                default:
                    ()
                }
            }
            DispatchQueue.main.async {
                var size:CGFloat = 0;
                for att in imgAttributes {
                    size += CGFloat(att.imgData.count)
                }
                let totalSize = Int(size)
                let availableSize = self.uiDelegate?.attachmentViewModel.availableSize ?? 0
                if totalSize > availableSize {
                    if let view = self.uiDelegate?.view {
                        let limitSize = String("\((self.uiDelegate?.contentChecker.mailLimitSize ?? 50)) MB")
                        ActionToast.showFailureToast(with:BundleI18n.MailSDK.Mail_Attachment_OverLimit(limitSize),
                                                     on: view, bottomMargin: suiteView.bounds.size.height + 100)
                        return
                    }
                    suiteView.set(isOrigin: isOrigin)
                }
                self.jsInsertImage(imgAttributes)
                self.uiDelegate?.resetPanel()
            }
        }
    }

    /// 检查是否是支持的图片格式
    /// 为了确保图片在各个终端及第三方邮件可用，仅支持png和jpeg，其余图片转换后使用
    func checkIsSupportImageFormat(imageData: Data) -> Bool {
        if imageData.lf.fileFormat() == FileFormat.image(.png) ||
           imageData.lf.fileFormat() == FileFormat.image(.jpeg) {
            return true
        }
        return false
    }

    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        MailTracker.insertLog(insertType: MailTracker.InsertType.image)
        let image = photo.lu.fixOrientation()
        if let imgData = image.data(quality: 1) {
            jsInsertImage([(imgData: imgData, imgSize: image.size, uuid: nil)])
        }
        uiDelegate?.resetPanel()
    }

    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        MailTracker.insertLog(insertType: MailTracker.InsertType.image)
    }
}

// MARK: - 插入及上传图片
extension MailImageHandler {

    /// - Parameter images: images to uplaod
    private func jsInsertImage(_ imgAttributes: [MailImageAttribute]) {
        // 发起上传图片
        let imageInfos = startUploadImages(imgAttributes);
        guard !imageInfos.isEmpty else {
            return
        }

        guard let pickImageJSFunc = pickImageJsName else {
            mailAssertionFailure("must have func name")
            return
        }
        guard let imgJSONStr = makeResJson(images: imageInfos, code: 0).toString() else {
            mailAssertionFailure("fail to get json string")
            return
        }
        let jsFunc: String = pickImageJSFunc + "(\(imgJSONStr))"
        MailLogger.info("jsInsertImage evaluate js, \(jsFunc)")
        uiDelegate?.evaluateJavaScript(jsFunc)
    }

    /// 开始上传图片
    @discardableResult
    private func startUploadImages(_ imgAttributes: [MailImageAttribute]) -> [MailImageInfo] {
        guard !imgAttributes.isEmpty else {
            return []
        }
        MailLogger.info("[mail_client_upload] js insert image")
        var imageInfos: [MailImageInfo] = []
        uploadTaskInfos = []
        _ = uiDelegate?.getScreenSize().width ?? 0
        for imgAttribute in imgAttributes {
            if let uuid = imgAttribute.uuid, !uuid.isEmpty, uploadUUIDs.contains(uuid) {
                // 过滤相同的uuid的图片上传
                MailLogger.info("upload the same uuid, ignore uuid=\(uuid)")
                continue
            }
            let uuid = imgAttribute.uuid ?? makeUniqueId()
            uploadUUIDs.append(uuid)
            /// 将image data 缓存
            let imgData = imgAttribute.imgData
            let imgSize = imgAttribute.imgSize
            let imgCodingData = imgData as NSCoding
            let width = "\(Int32(imgSize.width))"
            let height = "\(Int32(imgSize.height))"
            let isGif = imgData.mail.isGIF
            var imgInfo = MailImageInfo(uuid: uuid,
                                        src: MailCustomScheme.cid.rawValue + ":\(uuid)",
                                        width: width,
                                        height: height,
                                        isGif: isGif)
            imgInfo.dataSize = Int64(imgData.count)
            imageInfos.append(imgInfo)
            /// 写入缓存
            let user = serviceProvider?.user
            serviceProvider?.cacheService.set(object: imgCodingData, for: imgInfo.getCacheKey(userToken: user?.token, tenantID: user?.tenantID))
            MailLogger.info("[mail_client_upload] ori js insert image uuid: \(uuid) cacheKey: \(imgInfo.getCacheKey(userToken: user?.token, tenantID: user?.tenantID))")
            /// 将图片写入临时文件后再上传
            let userID = user?.userID
            let fileUploadingPath = makeImageUploadingPath(with: uuid, isGif: isGif)
            FileOperator.createFile(at: fileUploadingPath, contents: imgData, overwrite: true, attributes: nil, userID: userID)
            let taskInfo = makeImageUploadTaskInfo(uuid: uuid,
                                                   filePath: fileUploadingPath.absoluteString,
                                                   fileSize: Int64(imgData.count),
                                                   fileName: imgInfo.name)
            /// 按照 uuid 来标记info
            imageInfoDic[uuid] = imgInfo
            uploadTaskInfos.append(taskInfo)
            imageUploader.uploadImages([taskInfo],
                                       threadId: Store.settingData.mailClient ? uiDelegate?.getDraftId() : uiDelegate?.getThreadId())
        }
        return imageInfos
    }

    /// 创建图片上传任务信息
    private func makeImageUploadTaskInfo(uuid: String,
                                         filePath: String,
                                         fileSize: Int64,
                                         fileName: String,
                                         needSaveCidSrc: Bool = false) -> MailImageUploader.UploadTaskInfo {
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_UPLOAD_IMAGE_COST_TIME, params: ["uuid": uuid])
        MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_UPLOAD_IMAGE_MEMORY_DIFF, params: nil)
        let event = MailAPMEvent.DraftUploadImage()
        event.markPostStart()
        let tastInfo = MailImageUploader.UploadTaskInfo(uuid: uuid,
                                                        fileSize: fileSize,
                                                        filePath: filePath,
                                                        fileName: fileName,
                                                        params: [:]) { [weak self] (uuid, token, respKey, dataSize, progress, error, downloadStartTime) in
            guard let self = self else { return }
            MailLogger.info("[mail_client_upload] UploadTaskInfo callback `\(uuid)`, `\(token)`, `\(respKey)`, `\(dataSize)`")
            var imgInfo = self.imageInfoDic[uuid]
            /// 上传成功
            if error == nil, uuid == imgInfo?.uuid {
                if let token = token, !token.isEmpty {
                    let size = imgInfo?.dataSize ?? 0
                    let name = imgInfo?.name ?? ""
                    MailLogger.info("[mail_client_upload] [mail_client_editor] img ori webview setDriveImgSuccess")
                    self.setDriveImgSuccess(uuid: uuid, token: token, dataSize: size, imageName: name)
                    /// 标记图片上传成功
                    imgInfo?.token = token
                    imgInfo?.status = .complete
                    imgInfo?.dataSize = dataSize
                    
                    MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_UPLOAD_IMAGE_COST_TIME, params: ["file_size": dataSize])
                    MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_UPLOAD_IMAGE_MEMORY_DIFF, params: nil)
                    MailTracker.log(event: "mail_send_uploadimg_result", params: ["result": "true"])
                    if let imgInfo = imgInfo, !(self.uiDelegate?.draft?.content.images.map({ $0.uuid }) ?? []).contains(uuid) {
                        self.uiDelegate?.draft?.content.images.append(imgInfo)
                    }
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                    event.endParams.append(MailAPMEvent.DraftUploadImage.EndParam.resource_content_length(Int(dataSize)))
                    event.endParams.append(MailAPMEvent.DraftUploadImage.EndParam
                        .upload_ms(MailTracker.getCurrentTime() - downloadStartTime))
                    event.postEnd()
                } else {
                    if Store.settingData.mailClient,
                       let uploadTaskObservable = self.imageUploader.apiClient?.uploader.uploadTask.asObservable().filter({ $0.0 == respKey }) {
                        MailLogger.info("[mail_client_upload] uploadTaskObservable respKey \(respKey) uuid: \(uuid)")
                        let insertDoneObservable = self.insertDoneStatus.asObservable().filter({ $0.contains(uuid) })
                        Observable
                            .zip( uploadTaskObservable, insertDoneObservable )
                            .take(1)
                            .subscribe(onNext: { [weak self] (uploadInfo, ids) in
                                guard let uuid = ids.first(where: { $0 == uuid }) else {
                                    MailLogger.error("[mail_client_upload] uploadTaskObservable error \(uploadInfo) uuid: \(uuid) not found")
                                    return
                                }
                                MailLogger.info("[mail_client_upload] uploadTaskObservable zip \(uploadInfo) uuid: \(uuid)")
                                guard let `self` = self else { return }
                                guard let change = uploadInfo.1 else { return }
                                let size = imgInfo?.dataSize ?? 0
                                let name = imgInfo?.name ?? ""
                                let value = ["imageName": name, "fileToken": change.token]
                                self.serviceProvider?.cacheService.set(object: value as NSCoding, for: uuid)
                                MailLogger.info("[mail_client_upload] [mail_client_editor] img webview status == .success excute js")
                                self.setDriveImgSuccess(uuid: uuid, token: change.token, dataSize: size, imageName: name)
                                /// 标记图片上传成功
                                imgInfo?.token = change.token
                                imgInfo?.status = .complete
                                imgInfo?.dataSize = dataSize
                                self.imageInfoDic[uuid] = imgInfo
                                if let imgInfo = imgInfo, !(self.uiDelegate?.draft?.content.images.map({ $0.uuid }) ?? []).contains(uuid) {
                                    self.uiDelegate?.draft?.content.images.append(imgInfo)
                                }
                                self.insertDoneStatusRemove(id: uuid)
                            }).disposed(by: self.disposeBag)
                    } else {
                        var jsStr = ""
                        let minProgress: Float = 0.03
                        if progress < minProgress {//保证进度最小值是3%
                            jsStr = "window.command.setDriveImgProgress(`\(uuid)`, \(minProgress * 100))"
                        } else {
                            jsStr = "window.command.setDriveImgProgress(`\(uuid)`, \(progress * 100))"
                        }
                        self.uiDelegate?.evaluateJavaScript(jsStr)
                    }
                }
            } else if let error = error {
                /// 标记图片上传失败
                imgInfo?.status = .error
                MailLogger.error("error in upload image", error: error)
                guard let uuid = imgInfo?.uuid else { mailAssertionFailure("can not find image info"); return }
                let jsStr = "window.command.setDriveImgError(`\(uuid)`)"
                MailLogger.error("vvImage-uid ori setDriveImgProgress 执行js `\(jsStr)`")
                self.uiDelegate?.evaluateJavaScript(jsStr)
                MailTracker.log(event: "mail_send_uploadimg_result", params: ["result": "false"])
                let storageErr: Int = 13001
                let networkErr: Int = 1007
                let errorCode = error.mailErrorCode
                if errorCode != storageErr, errorCode != networkErr { // 需要过滤掉drive容量不足的case, 1007是网络不通也过滤掉
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                    event.endParams.append(MailAPMEvent.DraftUploadImage.EndParam.resource_content_length(Int(dataSize)))
                    event.endParams.appendError(error: error)
                    event.postEnd()
                } else {
                    event.abandon() // 抛弃埋点
                }
            }
            self.imageInfoDic[uuid] = imgInfo

        }
        return tastInfo
    }

    /// uuid for each image
    ///
    /// - Returns: uuid
    private func makeUniqueId() -> String {
        let rawUUID = UUID().uuidString
        let uuid = rawUUID.replacingOccurrences(of: "-", with: "")
        return uuid.lowercased()
    }

    private func makeImageUploadingPath(with uuid: String, isGif: Bool = false) -> IsoPath {
        return FileOperator.makeImageUploadingPath(with: uuid, userID: serviceProvider?.user.userID, isGif: isGif)
    }

    func makeThumbJSON(info: MailImageInfo) -> [String: Any] {
        let infoDic = ["uuid": info.uuid,
                       "src": info.src,
                       "width": info.width,
                       "height": info.height,
                       "name": info.name]
        return infoDic
    }

    private func makeResJson(images infos: [MailImageInfo], code: Int) -> [String: Any] {
        var thumbsList: [[String: Any]] = [[:]]
        thumbsList.removeAll()
        for info in infos {
            let infoDic = makeThumbJSON(info: info)
            thumbsList.append(infoDic)
        }
        return ["code": code,
                "thumbs": thumbsList] as [String: Any]
    }
}
