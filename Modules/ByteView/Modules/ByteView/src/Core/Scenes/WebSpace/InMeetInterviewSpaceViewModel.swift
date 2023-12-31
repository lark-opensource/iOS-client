//
//  InMeetInterviewSpaceViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2023/6/6.
//

import Foundation
import ByteViewNetwork
import ByteViewUI

protocol InMeetInterviewSpaceDataObserver {
    func didChangeUrl(urlString: String)
}

class InMeetInterviewSpaceViewModel: InMeetViewModelSimpleComponent {

    var isInterviewSpaceEnabled: Bool {
        Display.pad && meeting.myself.role == .interviewer
    }

    var hasData: Bool {
        urlString != nil
    }

    private var urlString: String?

    private let meeting: InMeetMeeting
    required init(meeting: InMeetMeeting) {
        self.meeting = meeting
        if isInterviewSpaceEnabled {
            fetchData()
        }
    }

    private let listeners = Listeners<InMeetInterviewSpaceDataObserver>()

    func addListener(_ listener: InMeetInterviewSpaceDataObserver, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately, let urlString = urlString {
            listener.didChangeUrl(urlString: urlString)
        }
    }

    func removeListener(_ listener: InMeetInterviewSpaceDataObserver) {
        listeners.removeListener(listener)
    }

    private func fetchData() {
        let request = CheckInterviewMeetingSpaceRequest(meetingID: meeting.meetingId)
        meeting.httpClient.getResponse(request) { [weak self] result in
            switch result {
            case .success(let response):
                guard let url = response.url, !url.isEmpty else {
                    break
                }
                self?.urlString = url
                self?.listeners.forEach {
                    $0.didChangeUrl(urlString: url)
                }
                self?.openInterviewSpace()
            case .failure:
                break
            }
        }
    }

    func openInterviewSpace() {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return
        }
        if VCScene.isAuxSceneOpen {
            meeting.larkRouter.showDetailOrPush(url)
        } else {
            VCScene.openAuxScene(id: "meeting_\(meeting.sessionId)", title: meeting.topic) { [weak self] (_, _) in
                // 回调里直接启动导致在动画过渡中触发UI功能逻辑，会存在UI问题，延迟1秒调用
                let delayTime = 1000
                DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(delayTime), execute: {
                    self?.meeting.larkRouter.showDetailOrPush(url)
                })
            }
        }
    }
}
