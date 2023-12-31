//
//  SpaceNoticeViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/30.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import RxSwift
import RxRelay
import RxCocoa
import SKResource
import SwiftyJSON
import SpaceInterface
import LarkContainer

enum SpaceNoticeType: Equatable {
    case networkUnreachable
    case serverBulletin(info: BulletinInfo)
    case historyFolder
    case folderVerify(type: ComplaintState, tips: NSAttributedString, token: String)
    static func == (lhs: SpaceNoticeType, rhs: SpaceNoticeType) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnreachable, .networkUnreachable):
            return true
        case let (.serverBulletin(lInfo), .serverBulletin(rInfo)):
            return lInfo.id == rInfo.id
        case (.historyFolder, .historyFolder):
            return true
        case let (.folderVerify(lType, _, _), .folderVerify(rType, _, _)):
            return lType == rType
        default:
            return false
        }
    }

    var isServerBulletin: Bool {
        if case .serverBulletin = self {
            return true
        }
        return false
    }
}

public class SpaceNoticeViewModel {
    public typealias Action = SpaceSection.Action
    let bulletinManager: DocsBulletinManager?
    let commonTrackParams: [String: String]

    let noticesRelay = BehaviorRelay<[SpaceNoticeType]>(value: [])
    var noticesUpdated: Driver<[SpaceNoticeType]> {
        noticesRelay.asDriver()
    }

    let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private let disposeBag = DisposeBag()
    let userResolver: UserResolver

    public init(userResolver: UserResolver,
                bulletinManager: DocsBulletinManager?,
                commonTrackParams: [String: String]) {
        self.userResolver = userResolver
        self.commonTrackParams = commonTrackParams
        self.bulletinManager = bulletinManager
        bulletinManager?.addObserver(self)

        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] reachable in
                if reachable {
                    self?.removeNetworkUnreachableIfNeed()
                } else {
                    self?.addNetworkUnreachableIfNeed()
                }
            })
            .disposed(by: disposeBag)
    }

    deinit {
        bulletinManager?.removeObserver(self)
    }

    func prepare() {
        guard bulletinManager != nil else { return }
        NotificationCenter.default.post(name: DocsBulletinManager.bulletinRequestShowIfNeeded, object: self)
    }

    func addNetworkUnreachableIfNeed() {
        var currentNotices = noticesRelay.value
        if currentNotices.contains(.networkUnreachable) { return }
        currentNotices.insert(.networkUnreachable, at: 0)
        noticesRelay.accept(currentNotices)
    }

    func removeNetworkUnreachableIfNeed() {
        var currentNotices = noticesRelay.value
        guard let unreachableIndex = currentNotices.firstIndex(of: .networkUnreachable) else {
            DocsLogger.info("space.notice.vm --- unreachable notice index not found when removing")
            return
        }
        currentNotices.remove(at: unreachableIndex)
        noticesRelay.accept(currentNotices)
    }

    public func showHistoryFolderIfNeed(input: Single<Bool>) {
        input.subscribe(onSuccess: { [weak self] haveHistoryFolder in
            guard let self = self, haveHistoryFolder else { return }
            var currentNotices = self.noticesRelay.value
            if currentNotices.contains(.historyFolder) { return }
            currentNotices.append(.historyFolder)
            self.noticesRelay.accept(currentNotices)
        })
            .disposed(by: disposeBag)
    }

    public func bannerRefresh() {}
}

extension SpaceNoticeViewModel: DocsBulletinResponser {
    // 只处理首页的公告
    public func canHandle(_ type: [String]) -> Bool { type.contains(DriveConstants.driveMountPoint) }

    /// 展示公告
    public func bulletinShouldShow(_ info: BulletinInfo) {
        var currentNotices = noticesRelay.value
        //同一时间只会展示一个远端公告，所以要将原先显示的给下掉。
        currentNotices = currentNotices.filter { !$0.isServerBulletin }
        currentNotices.append(.serverBulletin(info: info))
        noticesRelay.accept(currentNotices)
        bulltinTrack(event: .view(bulletin: info))
    }

    /// 关闭指定公告，若为nil则关闭任何公告
    public func bulletinShouldClose(_ info: BulletinInfo?) {
        var currentNotices = noticesRelay.value
        if let infoToClose = info {
            if let noticeIndex = currentNotices.firstIndex(of: .serverBulletin(info: infoToClose)) {
                currentNotices.remove(at: noticeIndex)
                noticesRelay.accept(currentNotices)
            }
        } else {
            currentNotices = currentNotices.filter { !$0.isServerBulletin }
            noticesRelay.accept(currentNotices)
        }
    }

//    private func closeAllServerNotices() {
//        let notices = noticesRelay.value
//        if notices.contains(.networkUnreachable) {
//            noticesRelay.accept([.networkUnreachable])
//        } else {
//            noticesRelay.accept([])
//        }
//    }

    public func bulltinTrack(event: DocsBulletinTrackEvent) {
        bulletinManager?.track(event, commonParams: commonTrackParams)
    }
}

extension SpaceNoticeViewModel: BulletinViewDelegate {
    public func shouldClose(_ bulletinView: BulletinView) {
        guard let info = bulletinView.info else { return }
        bulltinTrack(event: .close(bulletin: info))
        NotificationCenter.default.post(name: DocsBulletinManager.bulletinCloseNotification, object: nil, userInfo: ["id": info.id])
    }

    public func shouldOpenLink(_ bulletinView: BulletinView, url: URL) {
        guard let info = bulletinView.info else { return }
        bulltinTrack(event: .openLink(bulletin: info))
        openBulletinURL(url)
        NotificationCenter.default.post(name: DocsBulletinManager.bulletinOpenLinkNotification, object: nil, userInfo: ["id": info.id])
    }

    private func openBulletinURL(_ url: URL) {
        if let type = DocsType(url: url),
           let objToken = DocsUrlUtil.getFileToken(from: url, with: type) {
            let file = SpaceEntryFactory.createEntry(type: type, nodeToken: "", objToken: objToken)
            file.updateShareURL(url.absoluteString)
            let body = SKEntryBody(file)
            actionInput.accept(.open(entry: body, context: [:]))
        } else {
            actionInput.accept(.openURL(url: url, context: nil))
        }
    }
}

extension SpaceNoticeViewModel: SpaceHistoryFolderViewDelegate {
    public func shouldOpenHistoryFolder(_ historyFolderView: SpaceHistoryFolderView) {
        guard let userID = User.current.basicInfo?.userID else {
            spaceAssertionFailure("无法读取到 UserID")
            return
        }
        
        guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
            DocsLogger.error("can not get SpaceVCFactory")
            return
        }

        let shareFoldersViewController = vcFactory.makeShareFolderListController(apiType: .shareFolderV2)
        actionInput.accept(.push(viewController: shareFoldersViewController))
    }
}
