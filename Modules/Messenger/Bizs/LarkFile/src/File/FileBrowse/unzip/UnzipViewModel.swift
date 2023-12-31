//
//  UnzipViewModel.swift
//  LarkFile
//
//  Created by bytedance on 2021/11/11.
//

import Foundation
import LarkMessengerInterface
import LarkContainer
import LarkSDKInterface
import RxSwift
import LKCommonsLogging
import RustPB
import RxCocoa

final class UnzipViewModel {
    enum UnzipStatus {
        case loading
        case success
        case inProgress
        case failed
    }
    private static let logger = Logger.log(UnzipViewModel.self, category: "LarkFile.UnzipViewModel")
    private let fileAPI: SecurityFileAPI
    let pushCenter: PushNotificationCenter
    let file: FileMessageInfo
    var pageCount: Int = 20 /// 默认一页拉取多少个
    var statusChangeNotice: Driver<UnzipStatus?> { return _statusChangeNotice.asDriver(onErrorJustReturn: (nil)) }
    private var _statusChangeNotice = PublishSubject<UnzipStatus?>()
    var status: UnzipStatus = .loading {
        didSet {
            _statusChangeNotice.onNext(status)
        }
    }
    private let disposeBag = DisposeBag()
    var extractPackageObservable: Observable<PushExtractPackage>?
    var extractPackageFailCallBack: (() -> Void)?
    init(pushCenter: PushNotificationCenter,
         fileAPI: SecurityFileAPI,
         file: FileMessageInfo) {
        self.pushCenter = pushCenter
        self.fileAPI = fileAPI
        self.file = file
        configPushCenter()
    }

    func extractPackange() {
        status = .loading
        fileAPI.extractPackageRequest(key: file.fileKey, authToken: file.authToken, authFileKey: file.authFileKey, step: Int64(pageCount), downloadFileScene: file.downloadFileScene)
            .subscribe(onError: { [weak self] error in
                if let callBack = self?.extractPackageFailCallBack {
                    callBack()
                }
                self?.status = .failed
                Self.logger.error("extract package fail", error: error)
            }).disposed(by: disposeBag)
    }

    func configPushCenter() {
        extractPackageObservable = pushCenter.observable(for: PushExtractPackage.self).filter({ [weak self] in
                                                                                                return $0.key != nil && $0.key == self?.file.fileKey })
    }
}
