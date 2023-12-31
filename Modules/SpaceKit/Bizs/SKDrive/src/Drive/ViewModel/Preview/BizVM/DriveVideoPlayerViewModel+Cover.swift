//
//  DriveVideoPlayerViewModel+Cover.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2023/6/2.
//  

import SKFoundation
import SKCommon

extension DriveVideoPlayerViewModel {

    func setupCoverDownloader() {
        guard let fileInfo = fileInfo else { return }
        coverDownloader = ThumbnailDownloader {
            DocDownloadCacheService.shared.dataWithVersion(key: fileInfo.fileToken,
                                                           type: ThumbnailDownloader.downloadType,
                                                           dataVersion: fileInfo.dataVersion)
        }
    }

    func loadVideoCover() {
        guard let fileInfo = fileInfo, let meta = fileInfo.getMeta() else { return }
        guard let downloader = coverDownloader else { return }
        if let cacheData = DocDownloadCacheService.shared.dataWithVersion(key: fileInfo.fileToken,
                                                                          type: ThumbnailDownloader.downloadType,
                                                                          dataVersion: fileInfo.dataVersion) {
            if let image = UIImage(data: cacheData) {
                self.bindAction?(.showCover(image: image))
                return
            }
        }
        DocsLogger.driveInfo("videoPlayer: start download video cover, token: \(DocsTracker.encrypt(id: meta.fileToken))")
        let teaParams = [DriveStatistic.RustTeaParamKey.downloadFor: DriveStatistic.DownloadFor.videoCover]
        downloader.downloadThumb(meta: meta, extra: nil, priority: .userInteraction, teaParams: teaParams)
            .subscribe(onNext: { [weak self] (image) in
                self?.bindAction?(.showCover(image: image))
            }, onError: { error in
                DocsLogger.driveError("videoPlayer: download cover fail: \(error.localizedDescription), token: \(DocsTracker.encrypt(id: meta.fileToken))")
            }).disposed(by: disposeBag)
    }
}
