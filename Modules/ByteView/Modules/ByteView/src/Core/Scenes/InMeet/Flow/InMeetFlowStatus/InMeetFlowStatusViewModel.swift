//
//  InMeetFlowStatusViewModel.swift
//  ByteView
//
//  Created by Shuai Zipei on 2023/3/7.
//
import Foundation
import ByteViewCommon
import ByteViewNetwork

protocol InMeetFlowStatusViewModelDelegate: AnyObject {
    func statusItemsDidChange(_ items: [InMeetStatusThumbnailItem])
}

final class InMeetFlowStatusViewModel: InMeetStatusManagerListener, InMeetMeetingProvider {

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    var fullScreenDetector: InMeetFullScreenDetector? { context.fullScreenDetector }
    let statusViewModel: InMeetFlowMeetingStatusViewModel?
    let networkStatusViewModel: InMeetRtcNetworkStatusViewModel?
    let resolver: InMeetViewModelResolver

    private var statusType: InMeetStatusType?

    let statusManager: InMeetStatusManager
    weak var delegate: InMeetFlowStatusViewModelDelegate? {
        didSet {
            delegate?.statusItemsDidChange(items.compactMap { $0 })
        }
    }
    private static let order: [InMeetStatusType] = [.lock, .record, .transcribe, .interpreter, .live, .interviewRecord, .countDown]
    lazy var items: [InMeetStatusThumbnailItem?] = Self.order.map { _ in nil }

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        self.statusViewModel = resolver.resolve()!
        self.networkStatusViewModel = resolver.resolve()!
        self.resolver = resolver
        self.statusManager = resolver.resolve()!
        self.statusManager.addListener(self)

        for (key, value) in self.statusManager.thumbnails {
            if let index = Self.order.firstIndex(where: { $0 == key }) {
                items[index] = value
            }
        }
    }

    func statusDidChange(type: InMeetStatusType) {
        guard let index = Self.order.firstIndex(where: { $0 == type }) else { return }
        items[index] = statusManager.thumbnails[type]
        delegate?.statusItemsDidChange(items.compactMap { $0 })
    }

    // MARK: - Public

    var isFlowPageControlVisible: Bool {
        context.isFlowPageControlVisible
    }

    var meetingTopic: String {
        meeting.topic
    }

    var isPopupEnabled: Bool {
        !statusManager.statuses.isEmpty
    }
}

extension InMeetFlowStatusViewModel: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        guard change == .scope, let scope = userInfo as? InMeetViewScope, scope == .fullScreen else { return }
    }
}
