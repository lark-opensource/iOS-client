//
//  MagicShareOperationViewModel.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/8/1.
//

import Foundation
import RxSwift
import RxCocoa
import Action

class MagicShareOperationViewModel {

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    let backAction: CocoaAction
    let reloadAction: CocoaAction
    let backToMagicSharePresenterAction: CocoaAction
    let backToShareScreenAction: CocoaAction
    let takeControlAciton: CocoaAction
    let transferPresenterRoleAction: CocoaAction
    let stopSharingAction: CocoaAction
    let copyFileURLAction: CocoaAction
    let switchToOverlayAction: CocoaAction
    let shareStatusObservable: Observable<MSShareStatus>
    let isRemoteEqualLocalObservable: Observable<Bool>
    let sharingFileNameDriver: Driver<String>
    let showPassOnSharingObservable: Observable<Bool>
    let showBackButtonObservable: Observable<Bool>
    let isInMagicShareObservable: Observable<Bool>
    let isContentChangeHintDisplayingObservable: Observable<Bool>
    let isGuest: Bool

    init(meeting: InMeetMeeting,
         context: InMeetViewContext,
         backAction: CocoaAction,
         reloadAction: CocoaAction,
         backToMagicSharePresenterAction: CocoaAction,
         backToShareScreenAction: CocoaAction,
         takeOverAction: CocoaAction,
         transferPresenterRoleAction: CocoaAction,
         stopSharingAction: CocoaAction,
         copyFileURLAction: CocoaAction,
         switchToOverlayAction: CocoaAction,
         shareStatusObservable: Observable<MSShareStatus>,
         isRemoteEqualLocalObservable: Observable<Bool>,
         sharingFileNameDriver: Driver<String>,
         showPassOnSharingObservable: Observable<Bool>,
         showBackButtonObservable: Observable<Bool>,
         isInMagicShareObservable: Observable<Bool>,
         isContentChangeHintDisplayingObservable: Observable<Bool>,
         isGuest: Bool) {
        self.meeting = meeting
        self.context = context
        self.backAction = backAction
        self.reloadAction = reloadAction
        self.backToMagicSharePresenterAction = backToMagicSharePresenterAction
        self.backToShareScreenAction = backToShareScreenAction
        self.takeControlAciton = takeOverAction
        self.transferPresenterRoleAction = transferPresenterRoleAction
        self.stopSharingAction = stopSharingAction
        self.copyFileURLAction = copyFileURLAction
        self.switchToOverlayAction = switchToOverlayAction
        self.shareStatusObservable = shareStatusObservable
        self.isRemoteEqualLocalObservable = isRemoteEqualLocalObservable
        self.sharingFileNameDriver = sharingFileNameDriver
        self.showPassOnSharingObservable = showPassOnSharingObservable
        self.showBackButtonObservable = showBackButtonObservable
        self.isInMagicShareObservable = isInMagicShareObservable
        self.isContentChangeHintDisplayingObservable = isContentChangeHintDisplayingObservable
        self.isGuest = isGuest
    }

}
