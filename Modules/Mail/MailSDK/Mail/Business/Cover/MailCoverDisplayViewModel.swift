//
//  MailCoverDisplayViewModel.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/5/22.
//

import Foundation
import RxSwift
import AppReciableSDK

enum MailCoverDisplayState {
    case none
    case loading(MailSubjectCover?)
    case loadFailed
    case thumbnail(UIImage)
    case cover(UIImage)
}

class MailCoverDisplayViewModel: MailApmHolderAble {
    static let priorityDefault: Int32 = 10
    static let priorityHight: Int32 = 50

    let scene: Scene
    private(set) lazy var coverStateSubject = BehaviorSubject<MailCoverDisplayState>(value: .none)
    lazy var coverStateDriver = coverStateSubject.asDriver(onErrorJustReturn: .none).skip(1)

    typealias EventType = MailAPMEvent.MailLoadCoverData
    var loadDataScene: EventType.EndParam = .coverLoadScene(.add)

    private let disposeBag = DisposeBag()
    private var currentRequestBag: DisposeBag?
    private var currentFailedCover: MailSubjectCover?
    private let photoProvider: OfficialCoverPhotoDataAPI
    private var lastRequestDate: Date?

    init(scene: Scene, photoProvider: OfficialCoverPhotoDataAPI) {
        self.scene = scene
        self.photoProvider = photoProvider
        setupObservers()
    }
}

extension  MailCoverDisplayViewModel {
    func setupObservers() {
        coverStateDriver.drive(onNext: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .none:
                self.currentRequestBag = nil
                self.currentFailedCover = nil
            case .loading(let cover):
                self.loadSelectedCover(cover)
            default:
                break
            }

        }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .larkEventChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                switch push {
                case .dynamicNetStatusChange(let change):
                    switch change.netStatus {
                    case .excellent, .evaluating, .weak:
                        // 封面加载失败后，在有网络时重试
                        guard let cover = self?.currentFailedCover else { return }
                        self?.loadDataScene = .coverLoadScene(.autoReload)
                        self?.loadSelectedCover(cover)
                    case .netUnavailable, .serviceUnavailable, .offline:
                        fallthrough
                    @unknown default:
                        break
                    }
                }
            }).disposed(by: disposeBag)
    }

    func updateCoverState(_ state: MailCoverDisplayState) {
        coverStateSubject.onNext(state)
    }

    func loadSelectedCover(_ cover: MailSubjectCover?) {
        guard let cover = cover else { return }

        startAPMEvent(token: cover.token)

        // 选择新的封面后，需要取消之前的下载请求
        currentRequestBag = nil
        currentFailedCover = nil
        let requestBag = DisposeBag()
        currentRequestBag = requestBag
        lastRequestDate = Date()
        // 当前选择的封面下载优先级最高

        let photoInfo = OfficialCoverPhotoInfo(url: "",
                                               token: cover.token,
                                               priority: Self.priorityDefault,
                                               subjectColorHex: "")
        let thumb = OfficialCoverPhotoInfo(url: "",
                                           token: cover.token,
                                           priority: Self.priorityHight,
                                           subjectColorHex: "")
        // 先下载缩略图，再下载原图
        var fullSizeLoaded = false
        photoProvider.fetchOfficialCoverPhotoDataWith(thumb, coverSize: photoProvider.defaultThumbnailSize, resumeBag: requestBag) { [weak self] image, _, _ in
            guard !fullSizeLoaded, let image = image else { return }
            self?.coverStateSubject.onNext(.thumbnail(image))
        }
        photoProvider.fetchOfficialCoverPhotoDataWith(photoInfo, coverSize: nil, resumeBag: requestBag) { [weak self] image, error, _ in
            guard let self = self else { return }
            if let image = image {
                fullSizeLoaded = true
                self.coverStateSubject.onNext(.cover(image))
            } else if error?.isRequestCanceled == false {
                if let currentState = try? self.coverStateSubject.value() {
                    switch currentState {
                    case .thumbnail:
                        // 如果已经加载出了缩略图，状态就不更新为失败，不断重试大图请求
                        self.currentFailedCover = cover
                    default:
                        self.delayOnFailed()
                    }
                } else {
                    self.delayOnFailed()
                }
            } else {
                MailLogger.info("[Cover] Request canceled, skip update state")
            }
            self.endAPMEvent(error: error)
        }
    }

    // UX需求失败至少有 400ms 延迟
    private func delayOnFailed() {
        if let date = lastRequestDate {
            lastRequestDate = nil
            let timeInterval: Double = 0.4
            let diff = timeInterval - Date().timeIntervalSince(date)
            if diff > 0.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + diff) { [weak self] in
                    guard let self = self else { return }
                    self.coverStateSubject.onNext(.loadFailed)
                }
            } else {
                coverStateSubject.onNext(.loadFailed)
            }
        } else {
            coverStateSubject.onNext(.loadFailed)
        }
    }
}

// MARK: - APM Event

private extension MailCoverDisplayViewModel {
    func startAPMEvent(token: String) {
        let event = EventType()
        event.customScene = scene
        event.endParams.append(loadDataScene)
        event.endParams.append(EventType.EndParam.coverToken(token))
        apmHolder[EventType.self] = event
        apmHolder[EventType.self]?.markPostStart()
    }

    func endAPMEvent(error: Error?) {
        if let error = error {
            if error is OfficialCoverPhotosProviderError {
                apmHolder[EventType.self]?.endParams.append(MailAPMEventConstant.CommonParam.status_exception)
            } else if error.isRequestTimeout {
                apmHolder[EventType.self]?.endParams.append(MailAPMEventConstant.CommonParam.status_timeout)
            } else {
                apmHolder[EventType.self]?.endParams.appendError(error: error)
                apmHolder[EventType.self]?.endParams.append(MailAPMEventConstant.CommonParam.status_http_fail)
            }
        } else {
            apmHolder[EventType.self]?.endParams.append(MailAPMEventConstant.CommonParam.status_success)
        }
        apmHolder[EventType.self]?.postEnd()
    }
}
