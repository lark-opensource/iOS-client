//
//  DriveThumbImageViewModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/8/17.
//

import Foundation
import RxSwift
import RxCocoa
import SKFoundation
import SKResource

protocol DriveThumbImageViewModelDepencency {
    // input
    var image: UIImage { get }
    var fileInfoReplay: ReplaySubject<Result<DKFileProtocol, Error>> { get }
    var downloader: DKPreviewDownloadService { get set }
    var cacheSource: DriveCacheService.Source { get }
    var previewType: DrivePreviewFileType { get }
    var networkReachable: Observable<Bool> { get }
    var cacheService: DKCacheServiceProtocol { get }
    // output
    var retryFetchFileInfo: () -> Void { get }
}

struct DriveThumbImageViewModelDependencyImpl: DriveThumbImageViewModelDepencency {
    var fileInfoReplay: ReplaySubject<Result<DKFileProtocol, Error>>
    var image: UIImage
    var downloader: DKPreviewDownloadService
    var retryFetchFileInfo: () -> Void
    var cacheSource: DriveCacheService.Source
    var previewType: DrivePreviewFileType
    var networkReachable: Observable<Bool>
    var cacheService: DKCacheServiceProtocol
}
class DriveThumbImageViewModel: DriveImageViewModelType {
    lazy var followContentManager = DriveImageFollowManager()
    
    private var bag = DisposeBag()
    private var fileInfo: DKFileProtocol?
    private let _imageSource: BehaviorRelay<DriveImagePreviewResult>
    private let _downloadState: BehaviorRelay<DriveImageDownloadState>
    private var dependency: DriveThumbImageViewModelDepencency
    private var downloadComplete: Bool = false
    var imageSource: Driver<DriveImagePreviewResult> {
        return _imageSource.asDriver(onErrorJustReturn: .failed).do( onSubscribed: {[weak self] in
            DocsLogger.driveInfo("DriveThumbImageViewModel -- setup streaming")
            self?.setupStreaming()
        })
            }
    
    var downloadState: Driver<DriveImageDownloadState> {
        return _downloadState.asDriver()
    }
    
    var progressTouchable: Driver<Bool> {
        // 失败状态下，进度条变成可点状态，如果无网络，不可点
        return Observable.combineLatest(_downloadState.asObservable(), dependency.networkReachable).map { (state, reachable) in
            switch state {
            case .failed:
                return reachable
            default:
                return true
            }
        }.asDriver(onErrorJustReturn: false)
    }
    var isLineImage: Bool { return false }
    weak var hostContainer: UIViewController?

    init(dependency: DriveThumbImageViewModelDepencency) {
        self.dependency = dependency
        _imageSource = BehaviorRelay<DriveImagePreviewResult>(value: .thumb(image: dependency.image))
        _downloadState = BehaviorRelay<DriveImageDownloadState>(value: .progress(progress: "0%"))
    }
    
    private func setupStreaming() {
        let previewType = dependency.previewType
        dependency.fileInfoReplay.skip(1).subscribe(onNext: {[weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(fileInfo):
                self.fileInfo = fileInfo
                if previewType == .similarFiles {
                    self.startLoadOrigin(fileInfo: fileInfo)
                } else {
                    self.downloadPreview(type: previewType, fileInfo: fileInfo)
                }
            case  .failure:
                DocsLogger.driveInfo("DriveThumbImageViewModel -- fileInfo failed")
                self.fileInfo = nil
            }
        }).disposed(by: bag)
        dependency.networkReachable.distinctUntilChanged().filter({ $0 }).skip(1).subscribe(onNext: {[weak self] _ in
            DocsLogger.driveInfo("DriveThumbImageViewModel -- resum when reachable")
            self?.resume()
        }).disposed(by: bag)
    }
    
    func resume() {
        guard !downloadComplete else {
            DocsLogger.driveInfo("DriveThumbImageViewModel -- download complete not need retry")
            return
        }
        guard nil != fileInfo else {
            DocsLogger.driveInfo("DriveThumbImageViewModel -- retry fetch fileinfo")
            dependency.retryFetchFileInfo()
            return
        }
        DocsLogger.driveInfo("DriveThumbImageViewModel -- start retry download")
        dependency.downloader.retryDownload(cacheSource: dependency.cacheSource)
    }
    
    private func startLoadOrigin(fileInfo: DKFileProtocol) {
        guard  let meta = fileInfo.getMeta() else {
            _downloadState.accept(.failed(tips: failTips(fileInfo: fileInfo)))
            return
        }
        DocsLogger.driveInfo("DriveThumbImageViewModel -- start download similar file")
        updateDowloader(fileInfo: fileInfo)
        dependency.downloader.downloadSimilar(meta: meta, cacheSource: dependency.cacheSource)
    }
    
    func downloadPreview(type: DrivePreviewFileType, fileInfo: DKFileProtocol) {
        DocsLogger.driveInfo("DriveThumbImageViewModel -- start download preview file: \(type)")
        updateDowloader(fileInfo: fileInfo)
        dependency
            .downloader
            .download(previewType: type, cacheSource: dependency.cacheSource, cacheCustomID: nil)
    }

    private func updateDowloader(fileInfo: DKFileProtocol) {
        dependency.downloader.updateFileInfo(fileInfo)
        dependency.downloader.downloadStatusHandler = { [weak self] status in
            guard let self = self else {
                return
            }
            self.handleDownloadStatus(status)
        }

    }
    private func handleDownloadStatus(_ status: DriveDownloadService.DownloadStatus) {
        guard let fileInfo = fileInfo else {
            return
        }

        switch status {
        case .downloading(let progress):
            let value = progress > 1 ? 1.0 : progress
            _downloadState.accept(.progress(progress: "\(Int(value * 100))%"))
        case .failed:
            let tips = failTips(fileInfo: fileInfo)
            DocsLogger.driveInfo("DriveThumbImageViewModel -- download failed")
            _downloadState.accept(.failed(tips: tips))
        case .success:
            handleDownloadCompleted()
            _downloadState.accept(.done(tips: BundleI18n.SKResource.LarkCCM_Drive_ImagePreview_Done_Button))
        case .retryFetch:
            let tips = failTips(fileInfo: fileInfo)
            DocsLogger.driveInfo("DriveThumbImageViewModel -- download retryFetch")
            _downloadState.accept(.failed(tips: tips))
        }
    }
    
    private func handleDownloadCompleted() {
        guard let fileInfo = fileInfo else { return }
        // 下载成功，打开本地文件
        let cacheType: DriveCacheType = dependency.previewType == .similarFiles ? .similar : .preview
        let result = dependency.cacheService.getFile(type: cacheType, fileExtension: fileInfo.fileExtension, dataVersion: fileInfo.dataVersion)
        switch result {
        case .failure:
            DocsLogger.driveInfo("DriveThumbImageViewModel -- download failed")
            _downloadState.accept(.failed(tips: failTips(fileInfo: fileInfo)))
            return
        case let .success(node):
            DocsLogger.driveInfo("DriveThumbImageViewModel --  download success")
            guard let path = node.fileURL else {
                spaceAssertionFailure("DriveThumbImageViewModel -- cache node url not set")
                _downloadState.accept(.failed(tips: failTips(fileInfo: fileInfo)))
                return
            }
            _imageSource.accept(.local(url: path))
        }
    }
    
    private func failTips(fileInfo: DKFileProtocol?) -> String {
        guard let info = fileInfo else {
            return BundleI18n.SKResource.LarkCCM_Drive_ImagePreview_LoadImage_Button(Int64(0).memoryFormat)

        }
        var tips = BundleI18n.SKResource.LarkCCM_Drive_ImagePreview_LoadImage_Button(Int64(info.size).memoryFormat)
        return tips
    }
}
