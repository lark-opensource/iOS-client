//
//  InMeetFollowViewModel+MagicShareRuntimeDelegate.swift
//  ByteView
//
//  Created by chentao on 2020/4/13.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewNetwork
import ByteViewUI

/// > 刚发现Google docs移动端下的链接会被改成下面这样：
/// > 原链接：https://docs.google.com/document/d/19I1vZSN5gI5tUatdj7Gpw0q9K21KtEwDdaLJ1sb5jng/edit
/// > 新链接：https://www.google.com/url?q=https://www.google.com/url?q%3Dhttps://docs.google.com/document/d/19I1vZSN5gI5tUatdj7Gpw0q9K21KtEwDdaLJ1sb5jng/edit%26amp;sa%3DD%26amp;ust%3D1587982345693000&sa=D&ust=1587982345735000&usg=AFQjCNElSBpIF4go-lZ2qa2haHL5BYlpbg
/// > 遇到这种url，在重定向完之后的url，也是希望能在follower那边打开的
private func trimGoogleLink(link: String) -> String {
    if link.lowercased().starts(with: "https://www.google.com/url?q="),
       let url = URL(string: link),
       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let queryItems = components.queryItems,
       let param = queryItems.first(where: { $0.name == "q" })?.value?.removingPercentEncoding,
       URL(string: param) != nil {
        return trimGoogleLink(link: param)
    } else {
        return link
    }
}

extension InMeetFollowViewModel: MagicShareRuntimeDelegate {

    /// 创建或复用现有Runtime
    /// - Parameters:
    ///   - document: 创建使用的源MS文档
    ///   - createSource: 创建的操作来源
    /// - Returns: runtime实例 & runtime是否是新创建的
    func createRuntime(with document: MagicShareDocument,
                       createSource: MagicShareRuntimeCreateSource,
                       participantsCount: Int,
                       forceCreate: Bool = false) -> (MagicShareRuntime, Bool) {
        InMeetFollowViewModel.logger.info("create magic share runtime url.hash: \(document.urlString.hash)")
        if let runtime = manager.currentRuntime,
           runtime.documentInfo == document,
           !forceCreate {
            runtime.setDelegate(self)
            runtime.setDocumentChangeDelegate(self.manager)
            runtime.updateParticipantCount(participantsCount)
            Self.logger.info("runtime hits the cache, documentVC:\(runtime.documentVC)")
            runtime.ownerID = ObjectIdentifier(self)
            return (runtime, false)
        } else {
            let runtime = manager.magicShareRuntimeFactory
                .createRuntime(document: document,
                               meeting: self.meeting,
                               delegate: self,
                               documentChangeDelegate: self.manager,
                               createSource: createSource,
                               participantsCount: participantsCount)
            runtime.ownerID = ObjectIdentifier(self)
            manager.currentRuntime = runtime
            Self.logger.info("runtime doesn't hit the cache")
            return (runtime, true)
        }
    }

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onOperation operation: MagicShareOperation) {
        switch operation {
        case .openUrl(let rawLink):
            Self.logger.debug("current runtime will open: \(rawLink.hash)")
            openTappedUrl(rawLink, magicShareRuntime: magicShareRuntime)
        case .openMoveToWikiUrl(wikiUrl: let wikiUrl, originUrl: let originUrl):
            Self.logger.debug("current runtime will open wiki: \(wikiUrl.hash), and remove origin: \(originUrl.hash)")
            openTappedUrl(wikiUrl, magicShareRuntime: magicShareRuntime, toBeRemovedUrl: originUrl)
        case .openUrlWithHandlerBeforeOpen(url: let rawLink, handler: let handler):
            Self.logger.debug("current runtime will clean and open: \(rawLink.hash)")
            openTappedUrl(rawLink, magicShareRuntime: magicShareRuntime, handlerBeforeOpen: handler)
        case .onTitleChange(title: let changedTitle):
            Self.logger.debug("current runtime will change title to: \(changedTitle.hash)")
            self.manager.changeDocumentTitle(magicShareRuntime.documentInfo, title: changedTitle)
        case .showUserProfile(userId: let userId):
            Self.logger.debug("current runtime will show user profile")
            InMeetUserProfileAction.show(userId: userId, meeting: meeting)
        case .setFloatingWindow(getFromVCHandler: let handler):
            Self.logger.debug("current runtime will set floating and do operation")
            self.larkRouter.activeWithTopMost { [weak self] vc in
                guard let self = self else { return }
                self.router.setWindowFloating(true)
                handler(vc)
            }
        case .openOrCloseAttachFile(isOpen: let isOpen):
            Self.logger.debug("current runtime will open subhost, isOpen: \(isOpen), event ignored")
        }
    }

    func magicShareRuntimeDidReady(_ magicShareRuntime: MagicShareRuntime) {
        if manager.localDocuments.count == 1, magicShareRuntime.currentDocumentStatus == .sharing {
            Toast.showOnVCScene(BundleI18n.ByteView.View_G_ParticipantsCanViewYourSharedDoc_Toast)
        }
        didReadySubject.onNext(Void())
    }

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onPresenterFollowerLocationChange location: MagicSharePresenterFollowerLocation) {
    }

    /// 主/被共享人有相对位置变化时，在自由浏览下，驱动箭头显示变化
    /// 判断是否为同一篇文档
    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onRelativePositionChange position: MagicShareRelativePosition) {
        Self.logger.debug("update relative position, angle: \(position.angle), pointerVisible: \(position.pointerVisible)")
        guard let remoteDocument = remoteMagicShareDocument else {
            Self.logger.info("update skipped, due to invalid remote document")
            directionSubject.onNext(.free)
            magicShareRuntime.setLastDirection(.free)
            return
        }
        if magicShareRuntime.documentInfo.hasEqualContentTo(remoteDocument) {
            if !position.pointerVisible {
                directionSubject.onNext(.free)
                magicShareRuntime.setLastDirection(.free)
            } else {
                // disable-lint: magic number
                switch position.angle {
                case -90:
                    directionSubject.onNext(.left)
                    magicShareRuntime.setLastDirection(.left)
                case 0:
                    directionSubject.onNext(.top)
                    magicShareRuntime.setLastDirection(.top)
                case 90:
                    directionSubject.onNext(.right)
                    magicShareRuntime.setLastDirection(.right)
                case 180:
                    directionSubject.onNext(.bottom)
                    magicShareRuntime.setLastDirection(.bottom)
                default:
                    directionSubject.onNext(.free)
                    magicShareRuntime.setLastDirection(.free)
                }
                // enable-lint: magic number
            }
        } else {
            Self.logger.debug("update skipped, due to viewing different document")
            directionSubject.onNext(.free)
            magicShareRuntime.setLastDirection(.free)
        }
    }

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onApplyStates states: [FollowState], uuid: String, timestamp: CGFloat) {
        manager.trackManager.handleApplyStates(uuid: uuid, timestamp: timestamp)
    }

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onFirstPositionChangeAfterFollow receiveFollowInfoTime: TimeInterval) {
        manager.canShowPositionSyncedToast = true
        manager.showPositionSyncedToastIfNeeded()
        manager.trackManager.trackOnFirstPositionChangeAfterFollow(
            with: magicShareRuntime.documentInfo.shareID,
            receiveFollowInfo: receiveFollowInfoTime
        )
    }

    // disable-lint: long function
    /// 用户收到openUrl或openMoveToWikiUrl回调后打开文档的动作
    /// - Parameters:
    ///   - rawLink: 点击的文档
    ///   - magicShareRuntime: 当前runtime
    ///   - toBeRemovedUrl: 需要被移除的中转url，在openUrl下为空
    ///   - handlerBeforeOpen: 跳转前执行的操作
    func openTappedUrl(_ rawLink: String, magicShareRuntime: MagicShareRuntime, toBeRemovedUrl: String? = nil, handlerBeforeOpen: (() -> Void)? = nil) {
        let url = trimGoogleLink(link: rawLink)
        self.resetEventRelay.onNext(Void())
        if self.shouldIntercept(url) {
            self.openAndMinimizeWindowIfNeeded(url)
            return
        }
        let user = meeting.accountInfo
        self.loadingRelay.accept(true)
        let setFloatingAndOpenUrlClosure: ((String) -> Void) = { [weak self] url in
            if let linkUrl = URL(string: url) {
                self?.router.setWindowFloating(true)
                Util.runInMainThread {
                    self?.larkRouter.push(linkUrl)
                }
            }
        }
        fullScreenDetector?.postInterruptEvent() // 点击文档中的链接后后退出全屏模式
        self.manager.currentRuntime?.setStoreCurrentLocation()
        if self.isPresenter {
            let openUrlConfirmAlertClosure: ((String) -> Void) = { url in
                ByteViewDialog.Builder()
                    .id(.openLinkInMagicShareConfirm)
                    .needAutoDismiss(true)
                    .title(I18n.View_MV_OpenLinkBrowser)
                    .message(I18n.View_MV_FollowersCantSee)
                    .leftTitle(I18n.View_MV_CancelButtonTwo)
                    .leftHandler({ _ in
                        MagicShareTracks.trackClickOpenUrlAlert(false)
                        return
                    })
                    .rightTitle(I18n.View_VM_OpenLink)
                    .rightHandler({ _ in
                        MagicShareTracks.trackClickOpenUrlAlert(true)
                        setFloatingAndOpenUrlClosure(url)
                    })
                    .show { [weak self] alert in
                        if let self = self {
                            self.openLinkConfirmAlertDismissTrigger.take(1).subscribe(onNext: { [weak alert] in
                                alert?.dismiss()
                            }).disposed(by: alert.rx.disposeBag)
                        }
                    }
            }
            httpClient.follow.startShareDocument(
                url,
                meetingId: self.meetingID,
                lifeTime: .permanent,
                initSource: .initFromLink,
                authorityMask: nil,
                breakoutRoomId: self.meeting.data.breakoutRoomId) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let response):
                        MagicShareTracks.trackClickFileLink(
                            token: response.followInfo.docToken,
                            shareType: response.followInfo.shareType,
                            shareSubType: response.followInfo.shareSubtype,
                            isPresenter: true,
                            shareId: response.followInfo.shareID)
                        self.loadingRelay.accept(false)
                        // 非CCM的URL，小窗并通过Lark打开；否则等待FollowInfo的推送
                        if response.openInBrowser {
                            MagicShareTracks.trackViewOpenUrlAlert()
                            openUrlConfirmAlertClosure(url)
                        } else {
                            // 与当前共享为相同文档，toast提示
                            if magicShareRuntime.documentInfo.hasEqualContentTo(response.followInfo) {
                                Toast.show(I18n.View_VM_SamePageTip, type: .error)
                            }
                            // 如文档为move to wiki，删除当前堆栈中toBeRemovedUrl对应的文档
                            if let originUrl = toBeRemovedUrl {
                                self.manager.removeLatestDocumentOnUpdating(with: originUrl)
                            }
                            Util.runInMainThread {
                                handlerBeforeOpen?()
                            }
                        }
                    case .failure(let error):
                        Self.logger.info("open url failed due to server error, followStatus is sharing, errorCode: \(error.toErrorCode())")
                        self.loadingRelay.accept(false)
                    }
                }
        } else {
            let httpClient = self.httpClient
            RxTransform.single {
                httpClient.getResponse(GetUrlBriefsRequest(urls: [url]), completion: $0)
            }.flatMap { [weak self] (response) -> Single<MagicShareDocument?> in
                guard let urlBrief = response.urlBriefs[url] else {
                    InMeetFollowViewModel.logger.warn("url brief is nil")
                    return .error(VCError.unknown)
                }
                guard !urlBrief.isDirty else {
                    InMeetFollowViewModel.logger.warn("url brief is dirty")
                    return .error(VCError.urlDirty)
                }
                guard let self = self else {
                    InMeetFollowViewModel.logger.warn("self is nil")
                    return .error(VCError.unknown)
                }
                if urlBrief.openInBrowser || (urlBrief.subtype == .ccmBitable && !self.setting.isMagicShareNewBitableEnabled) {
                    self.loadingRelay.accept(false)
                    setFloatingAndOpenUrlClosure(url)
                    return .just(nil)
                }
                // 判断是否是投屏转妙享
                let isSSToMS = self.localDocuments.last?.isSSToMS == true
                let document = MagicShareDocument(shareType: .init(rawValue: urlBrief.type.rawValue) ?? .unknown,
                                                  shareSubType: .init(rawValue: urlBrief.subtype.rawValue) ?? .unknown,
                                                  urlString: urlBrief.url,
                                                  userID: user.userId,
                                                  userType: .larkUser,
                                                  userName: user.userName,
                                                  deviceID: user.deviceId,
                                                  strategies: [],
                                                  initSource: .initFromLink,
                                                  docTitle: urlBrief.title,
                                                  rawUrl: urlBrief.url,
                                                  isSSToMS: isSSToMS,
                                                  docTenantWatermarkOpen: urlBrief.docTenantWatermarkOpen,
                                                  docTenantID: urlBrief.docTenantID)
                MagicShareTracks.trackClickFileLink(
                    token: nil,
                    shareType: document.shareType,
                    shareSubType: document.shareSubType,
                    isPresenter: false,
                    shareId: document.shareID ?? "")
                return .just(document)
            }
            .observeOn(MainScheduler.instance)
            .compactMap { $0 }
            .subscribe(
                onSuccess: { [weak self] (document: MagicShareDocument) in
                    guard let self = self else {
                        InMeetFollowViewModel.logger.warn("self(InMeetFollowViewModel) is nil")
                        return
                    }
                    guard let currentDoc = self.manager.currentRuntime?.documentInfo else {
                        InMeetFollowViewModel.logger.warn("lastLocalRuntime.document is empty")
                        return
                    }
                    guard !currentDoc.hasEqualContentTo(document) else {
                        InMeetFollowViewModel.logger.debug("brief.url == lastLocalRuntime.url")
                        self.loadingRelay.accept(false)
                        Toast.show(I18n.View_VM_SamePageTip, type: .error)
                        return
                    }
                    // 如文档为move to wiki，删除当前堆栈中toBeRemovedUrl对应的文档
                    if let originUrl = toBeRemovedUrl {
                        self.manager.removeLatestDocumentOnUpdating(with: originUrl)
                    }
                    self.loadingRelay.accept(false)
                    handlerBeforeOpen?()
                    self.manager.checkShouldShowPresenterChangedContentHintOnLocalChange(to: document)
                    // 点击的和远端正在共享的是同一篇，那么就push远端的文档，以确保Groot通道有效
                    if let remoteDocument = self.remoteMagicShareDocument,
                       remoteDocument.hasEqualContentTo(document) {
                        self.manager.pushDocument(remoteDocument, status: remoteDocument.isSSToMS ? .sstomsFree : .free, createSource: .untracked)
                    } else {
                        self.manager.pushDocument(document, status: document.isSSToMS ? .sstomsFree : .free, createSource: .untracked)
                    }
                },
                onError: { [weak self] (error: Error) in
                    Self.logger.info("open url failed due to server error, followStatus is free, errorCode: \(error.toErrorCode())")
                    self?.loadingRelay.accept(false)
                    guard let vcError = error as? VCError else {
                        Self.logger.info("convert error to vcError failed, will toast server error info")
                        return
                    }
                    Toast.show(vcError.description, type: .error)
                }
            )
            .disposed(by: self.bag)
        }
    }
    // enable-lint: long function
}

extension InMeetFollowViewModel {

    /// 检查点击的文档内容链接是否需要单独处理
    /// 如果链接已在Lark中注册，返回true，其他情况返回false
    /// - Parameter urlString: 在共享文档中点击的URL链接
    /// - Returns: 是否需要打断后续操作（URLBrief请求）
    func shouldIntercept(_ urlString: String) -> Bool {
        if urlString.starts(with: "http") || urlString.starts(with: "https") {
            return false
        } else if let url = URL(string: urlString), meeting.larkRouter.canOpen(url) {
            return true
        } else {
            return false
        }
    }

    /// 尝试打开url对应的页面，如果成功打开一个ViewController，令VC页面小窗
    /// - Parameter urlString: 在共享文档中点击的URL链接
    func openAndMinimizeWindowIfNeeded(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        self.larkRouter.push(url, completion: { [weak self] (isValid, _) in
            if isValid {
                self?.router.setWindowFloating(true)
            }
        })
    }

}
