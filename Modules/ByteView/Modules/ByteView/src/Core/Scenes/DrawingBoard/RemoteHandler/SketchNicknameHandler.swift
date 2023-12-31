//
//  SketchNicknameHandler.swift
//  ByteView
//
//  Created by Prontera on 2019/12/12.
//

import Foundation
import ByteViewNetwork

class SketchNicknameHandler: NSObject {
    let meetingId: String
    let httpClient: HttpClient

    init(meeting: InMeetMeeting) {
        self.meetingId = meeting.meetingId
        self.httpClient = meeting.httpClient
        super.init()
    }

    func singleNicknameDrawable(with user: ByteviewUser, shapeID: ShapeID, position: CGPoint, completion: @escaping (NicknameDrawable) -> Void) {
        httpClient.participantService.participantInfo(pid: user, meetingId: meetingId) { ap in
            let drawable = NicknameDrawable(id: user.participantId.identifier, text: ap.name,
                                            style: TextStyle(textColor: UIColor.ud.primaryOnPrimaryFill,
                                                             font: UIFont.systemFont(ofSize: 12),
                                                             backgroundColor: UIColor.ud.staticBlack.withAlphaComponent(0.6),
                                                             cornerRadius: 2),
                                            leftCenter: position)
            completion(drawable)
        }
    }
}
