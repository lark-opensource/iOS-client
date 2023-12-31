//
//  DriveLocalImageViewModel.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/18.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import SKFoundation

enum DriveImagePreviewResult {
    case failed
    case local(url: SKFilePath)
    case thumb(image: UIImage)
    case linearized(image: UIImage)
}

enum DriveImageDownloadState {
    case progress(progress: String)
    case failed(tips: String)
    case done(tips: String)
    case none
}


protocol DriveImageViewModelType {
    var hostContainer: UIViewController? { get set }
    var imageSource: Driver<DriveImagePreviewResult> { get }
    var downloadState: Driver<DriveImageDownloadState> { get }
    var progressTouchable: Driver<Bool> { get }
    var forbidDownload: Driver<()> { get }
    func suspend()
    func resume()
    var isLineImage: Bool { get }
    var followContentManager: DriveImageFollowManager { get set }
}

extension DriveImageViewModelType {
    var forbidDownload: Driver<()> {
        return Driver.empty()
    }
    var downloadState: Driver<DriveImageDownloadState> {
        return Driver<DriveImageDownloadState>.just(.none)
    }
    var progressTouchable: Driver<Bool> {
        return Driver<Bool>.empty()
    }
    func suspend() {}
    func resume() {}
}

class DriveLocalImageViewModel: DriveImageViewModelType {
    lazy var followContentManager = DriveImageFollowManager()
    
    private let _imageSource: BehaviorRelay<DriveImagePreviewResult>

    var imageSource: Driver<DriveImagePreviewResult> {
        return _imageSource.asDriver()
    }
    var isLineImage: Bool { return false }
    weak var hostContainer: UIViewController?
    let url: SKFilePath

    init(url: SKFilePath) {
        self.url = url
        _imageSource = BehaviorRelay<DriveImagePreviewResult>(value: .local(url: url))
    }
}
