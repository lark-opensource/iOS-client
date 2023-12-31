//
//  CalendarShareViewModel.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/18/23.
//

import Foundation
import RxRelay
import RxSwift
import LarkBizAvatar
import LarkContainer

enum CalendarShareViewStatus {
    case loading
    case dataLoaded
    case error(_: Error)
}

enum CalendarShareTab: Int {
    case forward = 0
    case link
    case qrcode

    var description: String {
        switch self {
        case .forward: return I18n.Calendar_Legacy_ShareEventToChat_Tab
        case .link: return I18n.Calendar_Detail_LinkMenu
        case .qrcode: return I18n.Calendar_Detail_QRCodeMenu
        }
    }

    var tracerDesc: String {
        switch self {
        case .forward: return "share_member"
        case .link: return "calendar_link"
        case .qrcode: return "calendar_qr_code"
        }
    }
}

struct CalendarShareContext {
    let calID: String
    let isManager: Bool
}

class CalendarShareViewModel: UserResolverWrapper {

    private(set) var rxLinkData: BehaviorRelay<ShareCalendarLinkViewData?> = .init(value: nil)
    private(set) var rxLinkViewStatus: BehaviorRelay<CalendarShareViewStatus> = .init(value: .loading)

    private(set) var rxQRCodeData: BehaviorRelay<CalendarShareQRCodeViewData?> = .init(value: nil)
    private(set) var rxQRCodeViewStatus: BehaviorRelay<CalendarShareViewStatus> = .init(value: .loading)

    private(set) var tabs: [CalendarShareTab] = [.forward, .link, .qrcode]

    let userResolver: UserResolver

    @ScopedInjectedLazy var rustAPI: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    private(set) var calContext: CalendarShareContext
    private let rxShareInfo: BehaviorRelay<Server.CalendarShareInfo?> = .init(value: nil)
    private let disposeBag = DisposeBag()

    init(with context: CalendarShareContext, userResolver: UserResolver) {
        calContext = context
        self.userResolver = userResolver
        fetchData()
        bindData()
    }

    func fetchData() {
        rxLinkViewStatus.accept(.loading)
        rxQRCodeViewStatus.accept(.loading)
        rustAPI?.getCalendarShareInfo(with: calContext.calID)
            .subscribeForUI(onNext: { [weak self] response in
                guard let self = self, !response.shareURL.isEmpty else { return }
                self.rxShareInfo.accept(response)
            }, onError: { [weak self] error in
                self?.rxLinkViewStatus.accept(.error(error))
                self?.rxQRCodeViewStatus.accept(.error(error))
                CalendarBiz.shareLogger.error(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }

    private func bindData() {
        // linkData
        rxShareInfo
            .compactMap { [weak self] shareInfo -> ShareCalendarLinkViewData? in
                guard let self = self else { throw ShareInfoError.weakSelfNil }
                guard let shareInfo = shareInfo else { return nil }
                let linkData = ShareCalendarLinkViewData()
                linkData.calTitle = shareInfo.summary
                linkData.calDesc = shareInfo.description_p.isEmpty ? I18n.Calendar_Detail_NoDescription : shareInfo.description_p
                linkData.linkStr = shareInfo.shareURL
                linkData.ownerName = shareInfo.ownerInfo.ownerName
                linkData.invitorName = self.calendarDependency?.currentUser.displayName ?? ""
                linkData.subscriberNum = FG.showSubscribers ? Int(shareInfo.subscriberNum) : 0
                return linkData
            }
            .bind(to: rxLinkData)
            .disposed(by: disposeBag)

        rxLinkData.compactMap { $0 }
            .subscribeForUI(onNext: { [weak self] _ in
                self?.rxLinkViewStatus.accept(.dataLoaded)
            }, onError: { [weak self] error in
                self?.rxLinkViewStatus.accept(.error(error))
                CalendarBiz.shareLogger.error(error.localizedDescription)
            }).disposed(by: disposeBag)

        // qrCodeData
        rxShareInfo
            .flatMap { [weak self] shareInfo -> Observable<CalendarShareQRCodeViewData?> in
                guard let self = self else { throw ShareInfoError.weakSelfNil }
                guard let shareInfo = shareInfo else { return .just(nil) }
                let qrCodeData = CalendarShareQRCodeViewData()
                qrCodeData.calTitle = shareInfo.summary
                qrCodeData.calDesc = shareInfo.description_p.isEmpty ? I18n.Calendar_Detail_NoDescription : shareInfo.description_p
                qrCodeData.linkStr = shareInfo.shareURL
                qrCodeData.ownerName = shareInfo.ownerInfo.ownerName
                qrCodeData.subscriberNum = FG.showSubscribers ? Int(shareInfo.subscriberNum) : 0

                if !shareInfo.coverAvatarKey.isEmpty, let rustAPI = self.rustAPI {
                   return rustAPI
                        .downLoadImage(with: shareInfo.coverAvatarKey).retry(3)
                        .catchErrorJustReturn(nil)
                        .compactMap { path -> CalendarShareQRCodeViewData? in
                            guard let path = path?.asAbsPath(), let image = try? UIImage.read(from: path) else {
                                CalendarBiz.shareLogger.error("Haven't found any image from the path.")
                                return nil
                            }
                            qrCodeData.avatarInfo = .normal(avatar: image, key: shareInfo.coverAvatarKey)
                            return qrCodeData
                        }
                } else if shareInfo.calendarType == .primary {
                    qrCodeData.avatarInfo = .primary(
                        avatarKey: shareInfo.ownerInfo.ownerAvatarKey,
                        identifier: shareInfo.ownerInfo.ownerUserID
                    )
                }
                return .just(qrCodeData)
            }
            .bind(to: rxQRCodeData)
            .disposed(by: disposeBag)

        rxQRCodeData.compactMap { $0 }
            .subscribeForUI(onNext: { [weak self] _ in
                self?.rxQRCodeViewStatus.accept(.dataLoaded)
            }, onError: { [weak self] error in
                self?.rxQRCodeViewStatus.accept(.error(error))
                CalendarBiz.shareLogger.error(error.localizedDescription)
            }).disposed(by: disposeBag)
    }
}

extension CalendarShareViewModel {
    enum ShareInfoError: Error {
        case weakSelfNil
        case emptyShareURL
    }
}
