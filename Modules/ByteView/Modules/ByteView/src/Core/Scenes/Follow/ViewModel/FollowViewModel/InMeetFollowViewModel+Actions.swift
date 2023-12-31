//
//  InMeetFollowViewModel+Actions.swift
//  ByteView
//
//  Created by chentao on 2020/4/9.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import UniverseDesignTheme
import ByteViewUI

extension InMeetFollowViewModel {

    /// 返回上一篇文档
    var backAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let self = self else {
                return .empty()
            }
            self.manager.currentRuntime?.setStoreCurrentLocation()
            if let document = self.localSecondLastDocument {
                if case .sharing = self.manager.status {
                    self.loadingRelay.accept(true)
                    self.httpClient.follow.backToPreviousDocument(
                        document.urlString,
                        meetingId: self.meetingID,
                        shareID: document.shareID ?? "",
                        breakoutRoomId: self.meeting.data.breakoutRoomId) { [weak self] _ in
                            self?.loadingRelay.accept(false)
                        }
                } else {
                    if document.isSSToMS {
                        self.manager.checkShouldShowPresenterChangedContentHintOnLocalChange(to: document)
                        ShareScreenToFollowTracks.trackClickBackToLastFileButton()
                    } else {
                        MagicShareTracks.trackContainerBack(subType: document.shareSubType.rawValue,
                                                            followType: document.shareType.rawValue,
                                                            isPresenter: self.isPresenter ? 1 : 0,
                                                            shareId: document.shareID,
                                                            token: document.token)
                        MagicShareTracksV2.trackMagicShareClickOperation(action: .clickBackward, isSharer: self.isPresenter)
                    }
                    if var remoteDocument = self.remoteMagicShareDocument, remoteDocument.hasEqualContentTo(document) {
                        remoteDocument.updateTitleWithLocalDocuments(self.localDocuments)
                        self.manager.popToDocument(remoteDocument, status: remoteDocument.isSSToMS ? .sstomsFree : .free, createSource: .newShare)
                    } else {
                        self.manager.popToDocument(document, status: document.isSSToMS ? .sstomsFree : .free, createSource: .newShare)
                    }
                }
            }
            return .empty()
        })
    }

    /// 重新加载文档
    var reloadAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.debug("tapped reload button")
            guard let self = self, let oldRuntime = self.manager.currentRuntime else {
                Self.logger.warn("in reloadAction, self or currentRuntime is nil, reload ignored")
                return .empty()
            }
            if oldRuntime.documentInfo.isSSToMS {
                ShareScreenToFollowTracks.trackClickReloadButton()
            } else {
                MagicShareTracks.trackContainerReload(subType: oldRuntime.documentInfo.shareSubType.rawValue,
                                                      followType: oldRuntime.documentInfo.shareType.rawValue,
                                                      isPresenter: self.isPresenter ? 1 : 0,
                                                      shareId: oldRuntime.documentInfo.shareID,
                                                      token: oldRuntime.documentInfo.token)
                MagicShareTracksV2.trackReloadFile(token: oldRuntime.documentInfo.token,
                                                   isSharer: self.manager.status.isSharing())
            }
            // config last runtime
            oldRuntime.trackOnMagicShareInitFinished(dueTo: .refreshAbort)
            oldRuntime.reload() // 附件需要刷新时主动调用reload方法触发一些析构操作
            // create and replace with new runtime
            self.manager.reload(with: self)
            return .empty()
        })
    }

    /// 主动指定共享人
    var transferPresenterRoleAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.debug("tapped pass presenter role button")
            guard let self = self else {
                Self.logger.warn("in transferPresenterRoleAction: self is nil")
                return .empty()
            }
            guard let remoteDocument = self.remoteMagicShareDocument else {
                Self.logger.warn("in transferPresenterRoleAction: remote document is nil")
                return .empty()
            }
            if #available(iOS 13.0, *) {
                let correctStyle = UDThemeManager.userInterfaceStyle
                let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
                UITraitCollection.current = correctTraitCollection
            }
            let vm = AssignNewSharerViewModel(meeting: self.meeting, remoteDocument: remoteDocument)
            let viewController = AssignNewSharerViewController(viewModel: vm)
            // TODO: @huangtao.ht pan不加wrap会崩，注意测试下其它地方
            self.router.presentDynamicModal(viewController,
                                            regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                            compactConfig: .init(presentationStyle: .pan, needNavigation: true))
            MagicShareTracksV2.trackMagicShareClickOperation(action: .clickPassSharing, isSharer: self.isPresenter)
            return .empty()
        })
    }

    /// 停止共享
    var stopSharingAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.debug("tapped stop sharing button")
            guard let self = self else {
                Self.logger.warn("in stopSharingAction: self is nil")
                return .empty()
            }
            guard let documentInfo = self.remoteMagicShareDocument else {
                Self.logger.warn("in stopSharingAction: self.documentInfo is nil")
                return .empty()
            }
            MagicShareTracks.trackStopSharingDocument(subType: documentInfo.shareSubType.rawValue,
                                                      followType: documentInfo.shareType.rawValue,
                                                      shareId: documentInfo.shareID,
                                                      token: documentInfo.token)
            MagicShareTracksV2.trackMagicShareClickOperation(action: .clickStopSharing, isSharer: self.isPresenter)
            Self.logger.debug("tapped stop sharing button and share id: \(documentInfo.shareID)")
            self.httpClient.follow.stopShareDocument(documentInfo.urlString, meetingId: self.meetingID,
                                                             breakoutRoomId: self.meeting.data.breakoutRoomId)
            if self.meeting.subType == .screenShare {
                self.meeting.leave()
            }
            return .empty()
        })
    }

    /// 恢复跟随共享人
    var toPresenterAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.debug("tapped to presenter button")
            guard let self = self else {
                Self.logger.warn("in toPresenterAction: self is nil")
                return .empty()
            }
            guard var document = self.remoteMagicShareDocument else {
                Self.logger.warn("in toPresenterAction: remote document is nil")
                return .empty()
            }
            document.updateTitleWithLocalDocuments(self.localDocuments)
            self.manager.followPresenter(document)
            return .empty()
        })
    }

    /// 投屏转妙享-回到共享屏幕
    var backToShareScreenAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.debug("tapped back to share screen button")
            guard let self = self else {
                Self.logger.warn("in backToShareScreenAction: self is nil")
                return .empty()
            }
            ShareScreenToFollowTracks.trackClickBackToShareScreenButton(with: .barIcon)
            self.manager.meeting.shareData.setShareScreenToFollowShow(false)
            if !self.service.storage.bool(forKey: .doubleTapToFree) {
                Toast.showOnVCScene(I18n.View_G_DoubleClickVOMO)
            }
            return .empty()
        })
    }

    /// 切换到自由浏览
    var toViewOnMyOwnAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.debug("tapped to view on my own button")
            guard let self = self else {
                Self.logger.warn("in toViewOnMyOwnAction: self is nil")
                return .empty()
            }
            guard var document = self.remoteMagicShareDocument else {
                Self.logger.warn("in toViewOnMyOwnAction: remote document is nil")
                return .empty()
            }
            document.updateTitleWithLocalDocuments(self.localDocuments)
            guard self.manager.currentRuntime?.didRenderFinish ?? false else {
                Self.logger.warn("in toViewOnMyOwnAction: render not finish")
                return .empty()
            }
            self.manager.freeToBrowse(document)
            return .empty()
        })
    }

    /// 成为共享人
    /// 可以抢占共享：beFollowPresentor == true && （自己的strategy包含follow || 共享的文档是doc类型）
    /// && 有共享权限 && （当前无人共享or当前自己在共享or当前其他人在共享且自己可以抢共享）
    var takeOverAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.debug("tapped take control button")
            guard let self = self, var documentInfo = self.remoteMagicShareDocument else {
                Self.logger.warn("take over skipped due to empty self or remote document")
                return .empty()
            }
            documentInfo.updateTitleWithLocalDocuments(self.localDocuments)
            MagicShareTracks.trackTakeOver(subType: documentInfo.shareSubType.rawValue,
                                           followType: documentInfo.shareType.rawValue,
                                           shareId: documentInfo.shareID,
                                           token: documentInfo.token)
            MagicShareTracksV2.trackMagicShareClickOperation(action: .clickTakeControl, isSharer: self.isPresenter)
            if !self.canShareContent || (self.isSharingContent && !self.isSelfSharingContent && !self.canReplaceShareContent) {
                // 无权限take control
                Self.logger.debug("in takeOverAction: denied due to permission")
                Toast.showOnVCScene(I18n.View_M_UnableToTakeControl)
                return .empty()
            }
            let participantInfo = self.meeting.myself
            let userProduceStgIds = participantInfo.capabilities.followProduceStrategyIds
            var docStgIds: [String] = []
            for docStg in documentInfo.strategies {
                docStgIds.append(docStg.id)
            }
            var isStgContain = true
            for docStgId in docStgIds {
                if !userProduceStgIds.contains(docStgId) {
                    isStgContain = false
                }
            }
            let isDoc = documentInfo.shareSubType == .ccmDoc
            let beFollowPresenter = participantInfo.capabilities.followPresenter
            Self.logger.debug("""
                isDoc: \(isDoc)
                isStgContain: \(isStgContain)
                beFollowPresenter: \(beFollowPresenter)
                docStgIds: \(docStgIds)
                userProduceStgIds: \(userProduceStgIds)
                """)
            if beFollowPresenter && (isDoc || isStgContain) {
                var fileTitle = documentInfo.docTitle
                if fileTitle.count > 40 {
                    let cutFileTitle = fileTitle.vc.substring(from: 0, length: 40)
                    fileTitle = cutFileTitle + "..."
                }
                let alertTitle = I18n.View_VM_YouWillTakeOverSharingFileNameTitle(fileTitle)
                ByteViewDialog.Builder()
                    .colorTheme(.rightGreen)
                    .title(I18n.View_G_YouTakeOverShareDoc)
                    .message(alertTitle)
                    .leftTitle(I18n.View_G_CancelButton)
                    .leftHandler({ _ in
                        Self.logger.debug("tapped cancel in takeControl")
                        MagicShareTracks.trackTakeOverDoubleCheck(isConfirm: false)
                    })
                    .rightTitle(I18n.View_VM_DocsShare)
                    .rightHandler({ [weak self] _ in
                        guard let self = self else { return }
                        Self.logger.debug("tapped confirm in takeControl")
                        MagicShareTracks.trackTakeOverDoubleCheck(isConfirm: true)
                        if let documentInfo = self.remoteMagicShareDocument, let shareID = documentInfo.shareID {
                            self.httpClient.follow.takeOverDocument(
                                documentInfo.urlString,
                                meetingId: self.meetingID,
                                shareID: shareID,
                                breakoutRoomId: self.meeting.data.breakoutRoomId)
                        }
                    })
                    .show { [weak self] alert in
                        guard let self = self else {
                            alert.dismiss()
                            return
                        }
                        self.isSharing.filter { $0 }.distinctUntilChanged().take(1).subscribe(onNext: { [weak alert] _ in
                            alert?.dismiss()
                        }).disposed(by: alert.rx.disposeBag)

                        self.bag.insert(Disposables.create { [weak alert] in
                            alert?.dismiss()
                        })
                    }
            } else {
                Toast.showOnVCScene(I18n.View_VM_YouCanNotTakeControl)
            }
            return .empty()
        })
    }

    /// 复制文档链接
    var copyURLAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.debug("tapped copy url button")
            guard let self = self,
                  let documentInfo = self.manager.currentRuntime?.documentInfo else {
                Self.logger.warn("in copyURLAction: self is nil")
                return .empty()
            }
            if self.security.copy(documentInfo.rawUrl, token: .magicShareCopyDocumentUrl, shouldImmunity: true) {
                Toast.showOnVCScene(I18n.View_VM_FileLinkCopied)
            }
            if documentInfo.isSSToMS {
                ShareScreenToFollowTracks.trackClickCopyFileLinkButton()
            } else {
                MagicShareTracks.trackCopyFileLink(
                    token: documentInfo.token,
                    shareType: documentInfo.shareType,
                    shareSubType: documentInfo.shareSubType,
                    isPresenter: self.isPresenter,
                    shareId: documentInfo.shareID)
                MagicShareTracksV2.trackCopyFileLink(token: documentInfo.token, isSharer: self.isPresenter)
            }
            return .empty()
        })
    }

    /// 点击OperationView，回到堆叠态
    var switchToOverlayAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            self?.fullScreenDetector?.postInterruptEvent()
            return .empty()
        })
    }

    /// 是否正在共享
    var isPresenter: Bool {
        return manager.status.isSharing()
    }
}
