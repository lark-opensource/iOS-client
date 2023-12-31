//  NetworkFlowHelper.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/2/6.
//

import Foundation
import EENavigator
import SKResource
import SKFoundation
import UniverseDesignDialog
import UniverseDesignColor
import UniverseDesignToast
import UIKit
import RxSwift
import SwiftyJSON
import SKInfra

 public final class NetworkFlowHelper {
     static public var dataTrafficFlag: Bool = false
     private var disposeBag = DisposeBag()
     private let networkStauts: SKNetStatusService
     private let cacheService: DriveCacheServiceBase?
    /// 流量阈值 50M
     static private let dataLimiter: UInt64 = 50 * 1024 * 1024
     public init(networkStauts: SKNetStatusService = DocsNetStateMonitor.shared,
                 cacheService: DriveCacheServiceBase? = DocsContainer.shared.resolve(DriveCacheServiceBase.self)) {
         self.networkStauts = networkStauts
         self.cacheService = cacheService
     }
     
     public enum ToastType {
         case manualOfflineSuccessToast
         case manualOfflineFlowToast(trueSize: UInt64)
     }
      
     enum ToastError: Error {
         case fetchFailed
     }
     
     public func process(_ size: UInt64,
                        skipCheck: Bool,
                        requestTask: @escaping () -> Void,
                        judgeToast:@escaping () -> Void
                        ) {
        if !skipCheck,
           networkStauts.accessType != .wifi,
           size >= UInt64(Self.dataLimiter),
           !Self.dataTrafficFlag {
             requestTask()
             judgeToast()
        } else {
            requestTask()
        }
    }
     //判断离线是否需要弹Toast
     public func checkIfNeedToastWhenOffline(fileSize: UInt64, fileName: String, objToken: FileListDefine.ObjToken, block: @escaping (ToastType) -> Void) {
        if fileSize == 0 {
            disposeBag = DisposeBag()
            fetchFileSize(fileToken: objToken)
                .subscribe(onSuccess: {[weak self] size in
                    guard let self = self else { return }
                    block(self.judgeManualOfflineTips(objToken: objToken, fileSize: UInt64(size), fileName: fileName))
                }, onError: { _ in
                    block(.manualOfflineSuccessToast)
                })
                .disposed(by: disposeBag)
        } else {
            block(judgeManualOfflineTips(objToken: objToken, fileSize: UInt64(fileSize), fileName: fileName))
        }
    }
     
     //获取文件大小
    private func fetchFileSize(fileToken: FileListDefine.ObjToken) -> Single<Int64> {
         let request = DocsRequest<JSON>(path: OpenAPI.APIPath.fetchFileInfo,
                                         params: ["file_token": fileToken, "mount_point": DriveConstants.driveMountPoint]) // 暂时只考虑 space mount point
             .set(method: .POST)
             .set(encodeType: .jsonEncodeDefault)
             .set(needVerifyData: false)
         return request.rxStart().map { data in
             guard let json = data else {
                 throw ToastError.fetchFailed
             }
             guard let size = json["data"]["size"].int64, size > 0 else {
                 throw ToastError.fetchFailed
             }
             return size
         }
     }
     //判断离线弹窗策略
     private func judgeManualOfflineTips(objToken: FileListDefine.ObjToken, fileSize: UInt64, fileName: String) -> ToastType {
         if let judge = cacheService?
                .isDriveFileExist(token: objToken,
                                  dataVersion: nil,
                                  fileExtension: SKFilePath.getFileExtension(from: fileName)) {
             if fileSize >= UInt64(Self.dataLimiter),
                networkStauts.accessType != .wifi,
                !judge,
                !Self.dataTrafficFlag {
                 return .manualOfflineFlowToast(trueSize: fileSize)
             } else {
                 return .manualOfflineSuccessToast
             }
         }
         return .manualOfflineSuccessToast
     }
     //Toast展示在view中
     public func presentToast(view: UIView, fileSize: UInt64) {

         let opeartion = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Warning_CellularStreaming_ButtonClose,
                                                displayType: .horizontal)
         let config = UDToastConfig(toastType: .info,
                                    text: BundleI18n.SKResource.CreationMobile_Warning_CellularStreaming_Toast(FileSizeHelper.memoryFormat(fileSize)),
                                    operation: opeartion)
         DispatchQueue.main.async {
             UDToast.showToast(with: config, on: view, delay: 2, operationCallBack: { _ in
                 NetworkFlowHelper.dataTrafficFlag = true
                 UDToast.removeToast(on: view)
             })
         }
     }
}
