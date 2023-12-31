//
// Created by duanxiaochen.7 on 2021/2/7.
// Affiliated with SKBrowser.
//
// Description:

import Foundation
import UIKit
import SKUIKit
import SKCommon
import SKFoundation
import SKResource
import HandyJSON
import UniverseDesignToast
import Photos
import LarkAppConfig
import RxSwift
import SwiftyJSON
import SKInfra
import LarkSensitivityControl


// MARK: 图像接收处理
extension SheetShareManager {

    func handleStartWriteImage(_ params: [String: Any]) {
        guard receiveStatue == .idle, let callback = params["callback"] as? String else {
            DocsLogger.info("sheetShareManager 正在写入中，不能重复写入")
            return
        }

        let json = JSON(params)
        // 这里使用SwiftJSON进行转换的原因是 前端有时候可能会传递double类型的数据过来 直接params["height"] as? UInt32会转失败
        guard let width = json["width"].uInt32, let height = json["height"].uInt32, width != 0, height != 0 else {
            DocsLogger.info("sheetShareManager 前端传递的宽高异常")
            return
        }

        DocsLogger.info("sheetShareManager image meta data: width:\(width) height:\(height)")
        imageHelper = StitchImageHelper(width: width, height: height, fileName: docsInfo.title)
        imageHelper?.delegate = self

        receiveStatue = .writing

        //获取内存使用情况
        callJSService(DocsJSCallBack(callback), params: ["memoryLimit": MemoryUtil.getAvaliableMemorySize()])

        transferOverTimeWorkItem.cancel()
        // 前端20s后没有传输数据过来上报超时
        transferOverTimeWorkItem = DispatchWorkItem { [weak self] in
            guard let `self` = self else { return }
            self.reportFail(type: .waitTimeout)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: transferOverTimeWorkItem)
    }

    func handleReceiveImageData(_ params: [String: Any]) {
        // 取消上报超时
        if transferOverTimeWorkItem.isCancelled == false {
            transferOverTimeWorkItem.cancel()
        }

        guard receiveStatue == .writing else {
            DocsLogger.info("sheetShareManager 状态异常，请检查meta信息")
            return
        }

        let startDate = Date()

        Date.measure(prefix: "sheetShareManager write image") { [weak self] in
            guard let `self` = self else { return }
            guard receiveStatue == .writing else {
                DocsLogger.info("sheetShareManager 调用顺序错误，当前状态为\(receiveStatue)")
                return
            }

            let parseDate = Date()

            DocsLogger.info("sheetShareManager parse data elasped time: \(Date().timeIntervalSince(parseDate) * 1000)")
            let json = JSON(params)
            guard let base64Pixel = params["img"] as? String, let width = json["width"].uInt32, let height = json["height"].uInt32, let isLast = params["isLast"] as? Bool else {
                DocsLogger.info("sheetShareManager 前端传入的参数不对")
                self.cancatImageFailue()
                return
            }

            guard let islastInRow = params["isLastInRow"] as? Bool, let callback = params["callback"] as? String else {
                DocsLogger.info("sheetShareManager 前端传入的参数不对")
                self.cancatImageFailue()
                return
            }

            let endParseDate = Date()

            DocsLogger.info("sheetShareManager parse data elasped time: \(endParseDate.timeIntervalSince(parseDate) * 1000)")

            DocsLogger.info("sheetShareManager image width: \(width) height: \(height)")

            receiveImageCallback = callback

            guard let pureBase64 = base64Pixel.split(separator: ",").last,
                  let data = Data(base64Encoded: String(pureBase64), options: .ignoreUnknownCharacters),
                  let image = UIImage(data: data) else {
                DocsLogger.info("sheetShareManager base64 数据有误")
                self.cancatImageFailue()
                return
            }

            guard image.size.width == CGFloat(width),
                  image.size.height == CGFloat(height) else {
                DocsLogger.info("sheetShareManager 宽高与像素不匹配")
                self.cancatImageFailue()
                return
            }

            guard let pixelsPointer = image.wk.pixelData() else {
                DocsLogger.info("sheetShareManager convert pixeld ata fail")
                self.cancatImageFailue()
                return
            }

            let imageInfo = ImageInfo(pixelPtr: pixelsPointer, width: width, height: height, isLastCol: islastInRow, isFinish: isLast)

            guard let imageHelper = imageHelper else {
                return
            }
            Date.measure(prefix: "sheetShareManager receive image") {
                imageHelper.receiveImageInfo(imageInfo)
            }

            Date.measure(prefix: "sheetShareManager can receive") {
                let shouldContinue = imageHelper.canReceiveImage()
                notifyFontedShouldContinueSendImageInfo(shouldContinue)
            }

            let endDate = Date()
            let elapsedTime = endDate.timeIntervalSince(startDate) * 1000
            DocsLogger.info("sheetShareManager notify notifyFontedShouldContinueSendImageInfo elapsedTime:\(elapsedTime)")
        }


    }

    func notifyFontedShouldContinueSendImageInfo(_ shouldContinue: Bool) {
        callJSService(DocsJSCallBack(receiveImageCallback), params: ["continueTransfer": shouldContinue])
    }

    func cancelWriteImageTask(fromWeb: Bool = false) {
        guard receiveStatue == .writing else {
            DocsLogger.info("sheetShareManager 当前不是写入状态")
            return
        }
        DocsLogger.info("sheetShareManager 前端调用取消逻辑")
        if fromWeb {
            reportFail(type: .stopTransfer)
        }
        imageHelper?.cancel()
        receiveStatue = .idle
        hideLoadingTip()
    }
}


extension SheetShareManager {
    func handleImageCore(_ path: SKFilePath, _ type: ShareAssistType, finishCallback: @escaping (() -> Void)) {
        let opItem = convertOpItem(from: type)

        // 权限管控
        if type == .saveImage || type == .more {
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                let response = DocPermissionHelper.validate(objToken: docsInfo.token,
                                                            objType: docsInfo.inherentType,
                                                            operation: .export)
                response.didTriggerOperation(controller: navigator?.currentBrowserVC ?? UIViewController())
                guard response.allow else {
                    finishCallback()
                    return
                }
            } else {
                let currentView = navigator?.currentBrowserVC?.view.window ?? UIView()
                if !DocPermissionHelper.checkPermission(.ccmExport,
                                                        docsInfo: docsInfo,
                                                        showTips: true,
                                                        securityAuditTips: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, hostView: currentView) {
                    DocsLogger.info("check Permission false, return")
                    finishCallback()
                    return
                }
            }
        }

        // 通过管控之后，如果是 more 则走 UIActivityController 逻辑，埋点
        if type == .more {
            showMoreViewController([path.pathURL])
            trackIfInCard {
                makeTrack(isCard: true, action: "share_card_img_success", opItem: opItem)
            } else: {
                makeTrack(isCard: false, action: "share_export_image_success", opItem: opItem)
            }
            finishCallback()
            return
        }
        // 其他情况肯定是要有一个下载图片的动作的，下载完成之后根据是否点击 saveImage 来区分埋点等事件
        saveImage(path) { [weak self] (success) in
            // 如果是要分享刚刚下载到本地的图片
            if type != .saveImage {
                if let image = try? UIImage.read(from: path) {
                    if type == .feishu {
                        self?.shareActionManager?.shareImageToLark(image: image)
                    } else {
                        self?.shareActionManager?.shareImageToSocialApp(type: type, image: image)
                    }
                    self?.trackIfInCard {
                        self?.makeTrack(isCard: true, action: "share_card_img_success", opItem: opItem)
                    } else: {
                        self?.makeTrack(isCard: false, action: "share_export_image_success", opItem: opItem)
                    }
                } else {
                    // 如果找不到图片，说明下载图片失败了，失败在其他地方已经埋点了，这里只是用来处理异常
                    DocsLogger.info("sheetShareManager image 创建失败")
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: self?.navigator?.currentBrowserVC?.view.window ?? UIView())
                }
            } else {
                // 保存到本地之后进行埋点
                self?.trackIfInCard {
                    if success {
                        self?.makeTrack(isCard: true, action: "download_card_img_success", opItem: nil)
                    }
                } else: {
                    // 一键生图的图片下载成功与否的埋点 见 StitchImageHelper 相关逻辑
                }
            }

            DocsLogger.info("save image \(success ? "success" : "failure")")
            finishCallback()
        }
    }

    //图片保存
    func saveImage(_ path: SKFilePath, callback: @escaping (Bool) -> Void) {
        let currentView = navigator?.currentBrowserVC?.view.window ?? UIView()
        UDToast.showTips(with: BundleI18n.SKResource.Doc_Share_ExportImageLoading, on: currentView)
        var isSuccessSave = true
        PHPhotoLibrary.shared().performChanges({
            do {
                let creationRequest = try AlbumEntry.forAsset(forToken: Token(PSDATokens.Sheet.sheet_share_image_do_download))
                creationRequest.addResource(with: .photo, fileURL: path.pathURL, options: nil)
            } catch {
                isSuccessSave = false
                DocsLogger.error("AlbumEntry.forAsset", extraInfo: nil, error: error, component: nil)
            }
        }, completionHandler: { [weak self] (success, error) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                UDToast.removeToast(on: currentView)
                if success && isSuccessSave {
                    UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Doc_ShotSaveSuccessfully, on: currentView)
                    callback(true)
                } else {
                    DocsLogger.error("sheetShareManager save long pic to album", extraInfo: nil, error: error, component: nil)
                    if PHPhotoLibrary.authorizationStatus() == .denied {
                        self.reportFail(type: .permissionDenied)
                    } else {
                        self.reportFail(type: .others, errMsg: error?.localizedDescription ?? "none")
                    }
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_SaveFailed, on: currentView)
                    callback(false)
                }
            }
        })
    }
}


extension SheetShareManager: StitchImageHelperDelegate {
    func stitchImageFinished(_ helper: StitchImageHelper) {
        DocsLogger.info("sheetShareManager 图像生成完毕隐藏loading")
        hideLoadingTip()
        DocsLogger.info("sheetShareManager 图像生成完毕")
        self.prevOperatedSharePanel?.isUserInteractionEnabled = true
        makeTrack(isCard: false, action: "export_image_success", opItem: nil)
        self.alertView?.changeOperationButton(true)
        storeImagePath = helper.imagePath
        if loadImageType == .alert {
            alertView?.updateImage(helper.imagePath)
            receiveStatue = .idle
        } else {
            handleImageCore(helper.imagePath, prevShareAssistType) { [weak self] in
                self?.receiveStatue = .idle
            }
        }
    }

    //内存问题暂停与恢复
    func receiveImagePause(_ helper: StitchImageHelper) {
        DocsLogger.info("sheetShareManager 通知前端暂停传递图像数据")
        notifyFontedShouldContinueSendImageInfo(false)

    }
    func receiveImageResume(_ helper: StitchImageHelper) {
        DocsLogger.info("sheetShareManager 通知前端继续传递图像数据")
        notifyFontedShouldContinueSendImageInfo(true)
    }
}


//资源清理
extension SheetShareManager {
    func restoreStatusAndFreeCache() {
        imageHelper?.freeCache()
        storeImagePath = nil
    }
}
