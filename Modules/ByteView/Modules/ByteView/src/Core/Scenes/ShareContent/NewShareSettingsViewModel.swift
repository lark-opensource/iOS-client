//
//  NewShareSettingsViewModel.swift
//  ByteView
//
//  Created by huangshun on 2020/4/17.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewNetwork
import ByteViewTracker
import UniverseDesignIcon

class NewShareSettingsViewModel: NewShareSettingsVMProtocol, InMeetMeetingProvider {

    lazy var adapter: IterableAdapter = {
        var items: [NewShareContentItem] = []
        if setting.isMagicShareNewDocsEnabled {
            items.append(docs)
        }
        if setting.isMSDocXEnabled {
            items.append(docX)
        }
        items.append(sheet)
        items.append(mind)
        if setting.isMagicShareNewBitableEnabled {
            items.append(bitable)
        }
        let section = SectionPresentable(items)
        return IterableAdapter([section])
    }()

    lazy var validFileTypes: [NewShareContentItem] = {
        var items: [NewShareContentItem] = []
        if setting.isMagicShareNewDocsEnabled {
            items.append(docs)
        }
        if setting.isMSDocXEnabled {
            items.append(docX)
        }
        items.append(sheet)
        items.append(mind)
        if setting.isMagicShareNewBitableEnabled {
            items.append(bitable)
        }
        return items
    }()

    lazy var docs: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_VM_NewDocs,
            image: VcDocType.doc.typeIcon) { [weak self] _ in
                guard self?.isShareContentControlLegal() == true else { return }
                self?.showChangeAlertIfNeeded {
                    VCTracker.post(name: .vc_meeting_onthecall_share_window,
                                   params: [
                                    .from_source: "new_file_list",
                                    .action_name: "create_file",
                                    .extend_value: ["doc_type": 1]
                                   ])
                    MagicShareTracksV2.trackShareWindowOperation(action: .clickNewDocs, isLocal: false)
                    self?.createAndShareDocs(.doc)
                    self?.dismiss()
                }
            }
    }()

    lazy var sheet: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_VM_NewSheets,
            image: VcDocType.sheet.typeIcon) { [weak self] _ in
                guard self?.isShareContentControlLegal() == true else { return }
                self?.showChangeAlertIfNeeded {
                    VCTracker.post(name: .vc_meeting_onthecall_share_window,
                                   params: [
                                    .from_source: "new_file_list",
                                    .action_name: "create_file",
                                    .extend_value: ["doc_type": 2]
                                   ])
                    MagicShareTracksV2.trackShareWindowOperation(action: .clickNewSheets, isLocal: false)
                    self?.createAndShareDocs(.sheet)
                    self?.dismiss()
                }
            }
    }()

    lazy var mind: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_VM_NewMindNotes,
            image: VcDocType.mindnote.typeIcon) { [weak self] _ in
                guard self?.isShareContentControlLegal() == true else { return }
                self?.showChangeAlertIfNeeded {
                    VCTracker.post(name: .vc_meeting_onthecall_share_window,
                                   params: [
                                    .from_source: "new_file_list",
                                    .action_name: "create_file",
                                    .extend_value: ["doc_type": 4]
                                   ])
                    MagicShareTracksV2.trackShareWindowOperation(action: .clickNewMindNotes, isLocal: false)
                    self?.createAndShareDocs(.mindnote)
                    self?.dismiss()
                }
        }
    }()

    lazy var bitable: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_G_CreatNewBitables_SharedScreen,
            image: VcDocType.bitable.typeIcon) { [weak self] _ in
                guard self?.isShareContentControlLegal() == true else { return }
                self?.showChangeAlertIfNeeded {
                    MagicShareTracksV2.trackShareWindowOperation(action: .clickNewBitable, isLocal: false)
                    self?.createAndShareDocs(.bitable)
                    self?.dismiss()
                }
        }
    }()

    lazy var docX: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_VM_NewDocs,
            image: VcDocType.docx.typeIcon,
            showBeta: setting.isMSCreateNewDocXBetaShow) { [weak self] _ in
                guard self?.isShareContentControlLegal() == true else { return }
                self?.showChangeAlertIfNeeded {
                    MagicShareTracksV2.trackShareWindowOperation(action: .clickNewDocX, isLocal: false)
                    self?.createAndShareDocs(.docx)
                    self?.dismiss()
                }
        }
    }()

    let meeting: InMeetMeeting

    // 共享内容权限相关
    let canShareContentRelay: BehaviorRelay<Bool>
    let canReplaceShareContentRelay: BehaviorRelay<Bool>
    let handleShareContentControlForbiddenPublisher: PublishSubject<ShareContentControlToastType>

    var showLoadingObservable: Observable<Bool> = .just(false)

    init(meeting: InMeetMeeting,
         canShareContentRelay: BehaviorRelay<Bool>,
         canReplaceShareContentRelay: BehaviorRelay<Bool>,
         handleShareContentControlForbiddenPublisher: PublishSubject<ShareContentControlToastType>) {
        self.meeting = meeting
        self.canShareContentRelay = canShareContentRelay
        self.canReplaceShareContentRelay = canReplaceShareContentRelay
        self.handleShareContentControlForbiddenPublisher = handleShareContentControlForbiddenPublisher

        VCTracker.post(name: .vc_meeting_onthecall_share_window, params: [.action_name: "create_new"])
    }

    func dismiss() {
        meeting.router.dismissTopMost(animated: false, completion: nil)
    }

    private func showChangeAlertIfNeeded(completion: @escaping () -> Void) {
        if meeting.shareData.isOthersSharingContent {
            ShareContentViewController.showShareChangeAlert { result in
                switch result {
                case .success:
                    completion()
                case .failure:
                    break
                }
            }
        } else {
            completion()
        }
    }

    deinit {
        VCTracker.post(name: .vc_meeting_onthecall_share_window, params: [.from_source: "new_file_list", .action_name: "back"])
    }

    private func createAndShareDocs(_ type: VcDocType) {
        meeting.httpClient.follow.createAndShareDocs(type, meetingId: meeting.meetingId, isExternalMeeting: meeting.setting.isExternalMeeting, breakoutRoomId: meeting.setting.breakoutRoomId, tenantTag: meeting.accountInfo.tenantTag)
    }
}

extension NewShareSettingsViewModel {
    func isShareContentControlLegal() -> Bool {
        if !canShareContentRelay.value {
            // 如果无法保证有共享内容权限，toast提示并中止操作
            InMeetFollowViewModel.logger.warn("share content is denied due to lack of permission")
            handleShareContentControlForbiddenPublisher.onNext(.canShareContent)
            return false
        } else if meeting.shareData.isSharingContent && !meeting.shareData.isSelfSharingContent && !canReplaceShareContentRelay.value {
            // 如果此时已经在共享中，并且违背抢共享原则，toast提示并中止操作
            InMeetFollowViewModel.logger.debug("replace share content is denied due to meeting permission")
            handleShareContentControlForbiddenPublisher.onNext(.canReplaceShareContent)
            return false
        }
        return true
    }
}

extension VcDocType {
    var typeIcon: UIImage {
        switch self {
        case .doc:
            return UDIcon.getIconByKeyNoLimitSize(.fileDocColorful)
        case .sheet:
            return UDIcon.getIconByKeyNoLimitSize(.fileSheetColorful)
        case .bitable:
            return UDIcon.getIconByKeyNoLimitSize(.fileBitableColorful)
        case .mindnote:
            return UDIcon.getIconByKeyNoLimitSize(.fileMindnoteColorful)
        case .slide:
            return UDIcon.getIconByKeyNoLimitSize(.fileSlideColorful)
        case .docx:
            return UDIcon.getIconByKeyNoLimitSize(.fileDocxColorful)
        case .unknown:
            return UDIcon.getIconByKeyNoLimitSize(.fileUnknowColorful)
        default:
            return UDIcon.getIconByKeyNoLimitSize(.fileUnknowColorful)
        }
    }
}
