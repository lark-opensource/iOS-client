//
//  DKDownloadViewModel.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/7/7.
//

import Foundation
import SKResource
import SpaceInterface
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation

class DKDownloadViewModel {
    typealias ViewData = DKDownloadProgressView.ViewData
    typealias DownloadViewAction = DKDownloadProgressView.DownloadViewAction
    private let fileProvider: DriveSDKFileProvider
    private let _cancelEvent = PublishRelay<()>()
    var completion: (URL?) -> Void
    lazy var viewAction: Driver<DownloadViewAction> = {
        let cancelAction = _cancelEvent.asDriver(onErrorJustReturn: ()).map { (_) -> DownloadViewAction in
            return DownloadViewAction.cancel
        }
        let download = fileProvider.download().takeUntil(cancelAction.asObservable())
            .asDriver(onErrorJustReturn: .interrupted(reason: BundleI18n.SKResource.Slide_Slide_FontDownloadFailed))
            .map {[weak self] (state) -> DownloadViewAction in
                guard let self = self else {
                    let data = ViewData(text: "", textColor: UIColor.ud.colorfulRed, progress: nil, progressBarColor: UIColor.ud.colorfulBlue)
                    return .update(data: data)
                }
                switch state {
                case .downloading(let progress):
                    return self.progressViewData(progress)
                case .interrupted(let reason):
                    DocsLogger.driveInfo("DriveSDK.DownloadOrigin: interrupted with reason \(reason)")
                    return self.failedViewData(reason)
                case .success(let fileURL):
                    DocsLogger.driveInfo("DriveSDK.DownloadOrigin: success")
                    return .success(url: fileURL)
                }
            }
        return Driver.merge([download, cancelAction]).startWith(self.progressViewData(0.0))
            .do(onNext: {[weak self] (action) in
                guard let self = self else { return }
                self.notifyCompletionIfNeed(action: action)
            })
    }()
    
    init(fileProvider: DriveSDKFileProvider, completion: @escaping ((URL?) -> Void)) {
        self.fileProvider = fileProvider
        self.completion = completion
    }
    
    func cancelDownload() {
        fileProvider.cancelDownload()
        _cancelEvent.accept(())
    }
    
    private func notifyCompletionIfNeed(action: DownloadViewAction) {
        switch action {
        case let .success(url):
            completion(url)
        case .cancel:
            completion(nil)
        default:
            break
        }
    }
    
    private func progressViewData(_ progress: Double) -> DownloadViewAction {
        let tips = "\(Int64(fileProvider.fileSize).memoryFormat) \(BundleI18n.SKResource.Drive_Sdk_Downloading)"
        let data = ViewData(text: tips, textColor: UIColor.ud.N900, progress: progress, progressBarColor: UIColor.ud.colorfulBlue)
        return .update(data: data)
    }
    
    private func failedViewData(_ reason: String) -> DownloadViewAction {
        let data = ViewData(text: reason, textColor: UIColor.ud.colorfulRed, progress: nil, progressBarColor: UIColor.ud.colorfulRed)
        return .update(data: data)
    }
}
