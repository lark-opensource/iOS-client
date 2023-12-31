//
//  DriveLinearizedImageViewModel.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/18.
//

import Foundation
import RxSwift
import RxCocoa
import SKFoundation

protocol DriveImageLinearizedDownloader: AnyObject {
    typealias ImageResult = DriveImageDownloader.ImageResult
    var downloadStream: Driver<ImageResult> { get }
    var forbidDownload: (() -> Void)? { get set }
    var hostContainer: UIViewController? { get set }
    func downloadLinearizedImage()
    func suspend()
    func resume()
}

class DriveLinearizedImageViewModel {
    private let _imageSource = PublishRelay<DriveImagePreviewResult>()
    private let _forbidDownload = PublishRelay<()>()
    private let bag = DisposeBag()
    private let imageDownloader: DriveImageLinearizedDownloader
    weak var hostContainer: UIViewController? {
        didSet {
            imageDownloader.hostContainer = hostContainer
        }
    }
    lazy var followContentManager = DriveImageFollowManager()

    init(downloader: DriveImageLinearizedDownloader) {
        self.imageDownloader = downloader
    }
    
    private func setupStreaming() {
        imageDownloader.downloadLinearizedImage()
        imageDownloader.downloadStream.flatMap {(result) -> Driver<DriveImagePreviewResult> in
            switch result {
                case .success(let result):
                    if let image = result.0 {
                        return Driver.just(.linearized(image: image))
                    } else if let url = result.1 {
                        return Driver.just(.local(url: url))
                    } else { // 测试发现可能第一次返回的数据解析不到数据，但是线性化加载过程并没有失败，可以继续加载
                        return Driver.empty()
                    }
                case .failure:
                    return Driver.just(.failed)
                @unknown default:
                    spaceAssertionFailure("unknown result")
                    return Driver.just(.failed)
            }
        }.drive(onNext: {[weak self] (source) in
            guard let self = self else { return }
            self._imageSource.accept(source)
        }).disposed(by: bag)

        imageDownloader.forbidDownload = { [weak self] in
            guard let self = self else { return }
            self._forbidDownload.accept(())
        }
    }
}

extension DriveLinearizedImageViewModel: DriveImageViewModelType {
    var imageSource: Driver<DriveImagePreviewResult> {
        return _imageSource.asDriver(onErrorJustReturn: .failed).do( onSubscribed: {[weak self] in
            self?.setupStreaming()
        })
    }
    var forbidDownload: Driver<()> {
        return _forbidDownload.asDriver(onErrorJustReturn: ())
    }

    func suspend() {
        imageDownloader.suspend()
    }
    
    func resume() {
        imageDownloader.resume()
    }
    var isLineImage: Bool { return true }
}
