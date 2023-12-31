//
//  InMeetNotesContainerViewModel.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/6/13.
//

import Foundation
import ByteViewNetwork

class InMeetNotesContainerViewModel: InMeetNotesDataListener {

    /// 会中有其他人和自己同时创建纪要时返回的错误码，此时端上不需要弹失败的toast，后端会推View_G_Notes_CreatedRefreshView的toast
    static let errorCodeForParallelCreation: Int = 239100

    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver
    var bvTemplate: BVTemplate?

    weak var notesContainerChangeDelegate: InMeetNotesContainerChangeDelegate?

    init(meeting: InMeetMeeting, resolver: InMeetViewModelResolver) {
        self.meeting = meeting
        self.resolver = resolver
    }

    // MARK: - InMeetNotesDataListener

    func didChangeNotesInfo(_ notes: NotesInfo?, oldValue: NotesInfo?) {
        notesContainerChangeDelegate?.didChangeNotesInfo(to: notes, from: oldValue)
    }

    func requestLatestNotes() {
        meeting.notesData.addListener(self)
    }

    func pauseDataIfNeeded() {
        meeting.notesData.removeListener(self)
    }

}

extension InMeetNotesContainerViewModel: BVTemplateSelectedDelegate {

    func templateOnItemSelected(_ viewController: UIViewController, item: BVTemplateItem) {
        Logger.notes.info("templateOnItemSelected, item: \(item)")
        NotesTracks.trackClickTemplate(with: item.objToken)
        notesContainerChangeDelegate?.showLoadingState(true)
        meeting.httpClient.notes.createNotes(meeting.meetingId,
                                             templateToken: item.objToken,
                                             templateId: item.id,
                                             locale: BundleI18n.currentLanguage.identifier.lowercased(),
                                             timeZone: TimeZone.current.identifier, completion: { [weak self] result in
            self?.notesContainerChangeDelegate?.showLoadingState(false)
            switch result {
            case .success(let rsp):
                Logger.notes.info("createNotes succeeded, response: \(rsp)")
            case .failure(let error):
                Logger.notes.info("createNotes failed, error: \(error)")
                if let code = error.toErrorCode(), code == Self.errorCodeForParallelCreation {
                    // 不显示toast
                } else {
                    self?.notesContainerChangeDelegate?.showCreateFailedToast()
                }
            }
        })
    }

    func templateOnEvent(onEvent event: BVTemplatePageEvent) {
        Logger.notes.info("templateOnEvent, event: \(event)")
        if case .onNavigationItemClick(let item) = event {
            switch item {
            case InMeetNotesKeyDefines.NavigationBarItem.close:
                NotesTracks.trackClickNotesNavigationBar(on: .close)
                notesContainerChangeDelegate?.didTapCloseButton()
            case InMeetNotesKeyDefines.NavigationBarItem.more:
                NotesTracks.trackClickNotesNavigationBar(on: .more)
            case InMeetNotesKeyDefines.NavigationBarItem.notification:
                NotesTracks.trackClickNotesNavigationBar(on: .notification)
            case InMeetNotesKeyDefines.NavigationBarItem.share:
                NotesTracks.trackClickNotesNavigationBar(on: .share)
            default:
                break
            }
        }
    }
}
