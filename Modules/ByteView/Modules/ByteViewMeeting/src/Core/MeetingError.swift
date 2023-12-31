//
//  MeetingError.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/6/1.
//

import Foundation

public enum MeetingError: Error {
    /// 没有设置MeetingAdapter
    /// - 通过MeetingSession.setAdapter设置
    case adapterNotFound
}

extension MeetingError: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { debugDescription }

    public var debugDescription: String {
        switch self {
        case .adapterNotFound:
            return "adapterNotFound"
        }
    }
}
