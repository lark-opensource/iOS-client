//
//  DKPreviewVMDependency.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/21.
//

import Foundation
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import LarkDocsIcon

enum DKFilePreviewInfo {
    struct LocalPreviewData {
        let url: SKFilePath
        let originFileType: DriveFileType
        let fileName: String
        let previewFrom: DrivePreviewFrom
        let additionalStatisticParameters: [String: String]?
    }

    case local(data: LocalPreviewData) // 本地路径预览,除音视频类型
    case linearizedImage(dependency: DriveImageDownloaderDependency) // 线性化图片预览数据
    case streamVideo(video: DriveVideo) // 边下边播视频数据
    case localMedia(url: SKFilePath, video: DriveVideo) // 本地视频,音频 AVPlayer
    case archive(viewModel: DriveArchivePreviewViewModel) // 压缩文件数据
    case webOffice(info: DriveWPSPreviewInfo) // 在线 WPS 预览
    case excelHTML(info: DriveHTMLPreviewInfo) // html info
    case thumbnail(dependency: DriveThumbImageViewModelDepencency)
}

protocol DKPreviewVMDependency {
    // 文件下载器
    var downloader: DKPreviewDownloadService { get set }
    // 预览数据请求
    var filePreviewProvider: FilePreviewProvider { get }
    // 
    var filePreviewProcessorProvider: PreviewProcessorProvider { get }
    // 缓存服务
    var cacheService: DKCacheServiceProtocol { get }
    // 转码长链
    var previewPushService: FilePreviewPushService { get }
    // 网络状态
    var networkState: Observable<Bool> { get }
    // 性能埋点
    var performanceRecorder: DrivePerformanceRecorder { get }

}

/// 预览流程，区分正常/降级
enum PreviewFlow {
    case normal
    case downgrade
}

protocol DKPreviewVMInput {
    // 开始请求预览数据，重试请求预览数据
    var fetchPreview: AnyObserver<PreviewFlow> { get }
    var canCopy: BehaviorRelay<Bool> { get }
}

protocol DKPreviewVMOutput {
    typealias State = DKPreviewViewModel.State
    var previewState: Driver<State> { get }
    var previewAction: Signal<DKPreviewAction> { get }
}

protocol DKPreviewViewModelType {
    var output: DKPreviewVMOutput { get }
    var input: DKPreviewVMInput { get }
}
