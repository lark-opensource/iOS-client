//
//  StatusInfo.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

public struct StatusInfo: Codable, Equatable {

    public let objectStatus: ObjectStatus
    public let reviewStatus: ReviewStatus
    public let canModify: Bool?
    public let objectVersion: Int
    public let lastEditVersion: Int
    public var schedulerType: MinutesSchedulerType
    public var schedulerDeltaExecuteTime: Int?
    public var canComment: Bool?

    public let summaryStatus: NewSummaryStatus?
    public let agendaStatus: NewSummaryStatus?
    public let speakerAiStatus: NewSummaryStatus?

    private enum CodingKeys: String, CodingKey {
        case objectStatus = "object_status"
        case reviewStatus = "review_status"

        case canModify = "can_modify"
        case objectVersion = "object_version"
        case lastEditVersion = "last_edit_version"
        case schedulerType = "scheduler_type"
        case schedulerDeltaExecuteTime = "scheduler_execute_delta_time"
        case canComment = "can_comment"

        case summaryStatus = "summary_status"
        case agendaStatus = "agenda_status"
        case speakerAiStatus = "speaker_ai_status"
    }
}
