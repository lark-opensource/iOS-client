//
//  Queue.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/8/17.
//

import Foundation

public enum Queue {
    /// 推送，qos = userInitiated
    public static let push = DispatchQueue(label: "ByteView.GlobalQueue.Push", qos: .userInitiated)
    /// tracker
    public static let tracker = DispatchQueue(label: "ByteView.GlobalQueue.Tracker")
    /// logger，qos = utility
    public static let logger = DispatchQueue(label: "ByteView.GlobalQueue.Logger", qos: .utility)
}
