//
//  CursorFrame.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2023/1/18.
//

import Foundation
import RustPB
import SwiftProtobuf

/// Videoconference_V1_CursorFrame
public struct CursorFrame: Equatable {

    public init(
        timestamp: UInt64, sequenceNumber: UInt64,
        userID: String, targetUserID: String,
        sharedRectWidth: CGFloat, sharedRectHeight: CGFloat,
        cursorFrameWidth: CGFloat, cursorFrameHeight: CGFloat,
        cursorRenderSrcX: CGFloat, cursorRenderSrcY: CGFloat,
        cursorRenderWidth: CGFloat, cursorRenderHeight: CGFloat,
        cursorRenderDstX: CGFloat, cursorRenderDstY: CGFloat,
        cursorDataFormat: CursorFrame.CursorImageFormat,
        cursorDataLength: Int32,
        cursorData: Data,
        imageKey: String,
        sendTimestamp: UInt64,
        recvTimestamp: UInt64,
        renderTimestamp: UInt64
    ) {
        self.timestamp = timestamp
        self.sequenceNumber = sequenceNumber
        self.userID = userID
        self.targetUserID = targetUserID
        self.sharedRectWidth = sharedRectWidth
        self.sharedRectHeight = sharedRectHeight
        self.cursorFrameWidth = cursorFrameWidth
        self.cursorFrameHeight = cursorFrameHeight
        self.cursorRenderSrcX = cursorRenderSrcX
        self.cursorRenderSrcY = cursorRenderSrcY
        self.cursorRenderWidth = cursorRenderWidth
        self.cursorRenderHeight = cursorRenderHeight
        self.cursorRenderDstX = cursorRenderDstX
        self.cursorRenderDstY = cursorRenderDstY
        self.cursorDataFormat = cursorDataFormat
        self.cursorDataLength = cursorDataLength
        self.cursorData = cursorData
        self.imageKey = imageKey
        self.sendTimestamp = sendTimestamp
        self.recvTimestamp = recvTimestamp
        self.renderTimestamp = renderTimestamp
    }

    public init(serializedData: Data) throws {
        do {
            var options = BinaryDecodingOptions()
            options.discardUnknownFields = true
            let frame = try Videoconference_V1_CursorFrame.init(serializedData: serializedData, options: options)
            self = frame.vcType
            self.recvTimestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        } catch {
            throw error
        }
    }

    public var timestamp: UInt64

    public var sequenceNumber: UInt64

    public var userID: String

    public var targetUserID: String

    /// 当前共享窗口的宽度信息
    public var sharedRectWidth: CGFloat

    /// 当前共享窗口的宽度信息
    public var sharedRectHeight: CGFloat

    /// 当前光标宽度
    public var cursorFrameWidth: CGFloat

    /// 当前光标高度
    public var cursorFrameHeight: CGFloat

    // --- 可能存在光标和抓屏区域边界重合的情况，以下定义光标中用于渲染的区域

    /// 当前光标渲染起点x坐标
    public var cursorRenderSrcX: CGFloat

    /// 当前光标渲染起点y坐标
    public var cursorRenderSrcY: CGFloat

    /// 当前光标渲染宽度
    public var cursorRenderWidth: CGFloat

    /// 当前光标渲染高度
    public var cursorRenderHeight: CGFloat

    // --- 渲染目标区域起点

    /// 目前区域起点x坐标，相对于共享窗口
    public var cursorRenderDstX: CGFloat

    /// 目前区域起点y坐标，相对于共享窗口
    public var cursorRenderDstY: CGFloat

    // --- 光标类型以及对应的图片资源信息

    /// 光标数据像素格式
    /// e.g. ARGB / RGBA
    public var cursorDataFormat: CursorImageFormat

    /// 光标数据长度
    public var cursorDataLength: Int32

    /// 光标数据
    public var cursorData: Data

    /// 光标图片标识符
    public var imageKey: String

    /// 发送时间
    public var sendTimestamp: UInt64

    /// 接收时间
    public var recvTimestamp: UInt64

    /// 渲染时间
    public var renderTimestamp: UInt64

    public enum CursorImageFormat: Int {
        case argb
        case bgra
        case ya
    }
}

extension Videoconference_V1_CursorFrame {
    var vcType: CursorFrame {
        .init(
            timestamp: timestamp,
            sequenceNumber: sequenceNumber,
            userID: userID,
            targetUserID: targetUserID,
            sharedRectWidth: CGFloat(sharedRectWidth),
            sharedRectHeight: CGFloat(sharedRectHeight),
            cursorFrameWidth: CGFloat(cursorFrameWidth),
            cursorFrameHeight: CGFloat(cursorFrameHeight),
            cursorRenderSrcX: CGFloat(cursorRenderSrcX),
            cursorRenderSrcY: CGFloat(cursorRenderSrcY),
            cursorRenderWidth: CGFloat(cursorRenderWidth),
            cursorRenderHeight: CGFloat(cursorRenderHeight),
            cursorRenderDstX: CGFloat(cursorRenderDstX),
            cursorRenderDstY: CGFloat(cursorRenderDstY),
            cursorDataFormat: cursorDataFormat.vcType,
            cursorDataLength: cursorDataLength,
            cursorData: cursorData,
            imageKey: "\(imageKey)",
            sendTimestamp: sendTimestamp,
            recvTimestamp: recvTimestamp,
            renderTimestamp: renderTimestamp
        )
    }
}

extension Videoconference_V1_CursorImageFormat {
    var vcType: CursorFrame.CursorImageFormat {
        switch self {
        case .argb: return .argb
        case .bgra: return .bgra
        case .ya: return .ya
        @unknown default: return .argb
        }
    }
}

extension CursorFrame: CustomStringConvertible {
    public var description: String {
        String(
            indent: "CursorFrame",
            "timestamp: \(timestamp)",
            "sequenceNumber: \(sequenceNumber)",
            "userID: \(userID)",
            "targetUserID: \(targetUserID)",
            "sharedRectWidth: \(sharedRectWidth)",
            "sharedRectHeight: \(sharedRectHeight)",
            "cursorFrameWidth: \(cursorFrameWidth)",
            "cursorFrameHeight: \(cursorFrameHeight)",
            "cursorRenderSrcX: \(cursorRenderSrcX)",
            "cursorRenderSrcY: \(cursorRenderSrcY)",
            "cursorRenderWidth: \(cursorRenderWidth)",
            "cursorRenderHeight: \(cursorRenderHeight)",
            "cursorRenderDstX: \(cursorRenderDstX)",
            "cursorRenderDstY: \(cursorRenderDstY)",
            "cursorDataFormat: \(cursorDataFormat)",
            "cursorDataLength: \(cursorDataLength)",
            "imageKey: \(imageKey)",
            "sendTimestamp: \(sendTimestamp)",
            "recvTimestamp: \(recvTimestamp)",
            "renderTimestamp: \(renderTimestamp)"
        )
    }
}
