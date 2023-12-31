//
// Created by liujianlong on 2022/10/10.
//

import Foundation
import ByteViewMeeting
import RxSwift

class WebinarRoleTransitionViewModel {
    let meetingID: String
    let isWebinarAttendee: Bool
    let manager: InMeetWebinarManager
    var router: Router? { manager.session.service?.router }
    var rejoinTimeout: Observable<Void> {
        rejoinTimeoutSubject.asObservable()
    }
    private let rejoinTimeoutSubject = ReplaySubject<Void>.create(bufferSize: 1)
    init(manager: InMeetWebinarManager, isWebinarAttendee: Bool) {
        self.meetingID = manager.meetingID
        self.isWebinarAttendee = isWebinarAttendee
        self.manager = manager
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            self?.rejoinTimeoutSubject.onNext(Void())
        }
    }

    func leaveMeeting() {
        manager.session.leave()
    }

    func rejoinMeeting() {
        manager.rejoin(isWebinarAttendee: isWebinarAttendee)
    }
}
