//
//  Tracing+sendMessage.swift
//  LarkSDKInterface
//
//  Created by bytedance on 2021/8/25.
//

import Foundation

/*
    发消息tracting接入
    避免映射关系中的spanName被覆盖通过spanName+cid作为最终的spanName
 */
extension LarkTracingUtil {

    /*
     spanName拼接，适用多线程场景spanName重复导致的问题。
     */
    private static func combineSpanNameWithTag(spanName: String, tag: String) -> String {
        return spanName + tag
    }

    public static func sendMessageReplaceSpanNameWithCid(ondCid: String, newCid: String) {
        guard self.tracingEnable else {
            return
        }
        sendMessageReplaceSpanNameWithCid(spanName: self.sendMessage, ondCid: ondCid, newCid: newCid)
        sendMessageReplaceSpanNameWithCid(spanName: self.messageOnScreen, ondCid: ondCid, newCid: newCid)
        sendMessageReplaceSpanNameWithCid(spanName: self.createQuasiMessage, ondCid: ondCid, newCid: newCid)
    }

    private static func sendMessageReplaceSpanNameWithCid(spanName: String, ondCid: String, newCid: String) {
        let oldSpanName = self.combineSpanNameWithTag(spanName: spanName, tag: ondCid)
        let newSpanName = self.combineSpanNameWithTag(spanName: spanName, tag: newCid)
        self.replaceOldNameByNewName(oldName: oldSpanName, newName: newSpanName)
    }

    public static func sendMessageStartRootSpan(spanName: String, cid: String) {
        guard self.tracingEnable else {
            return
        }
        let sendMessageSpanName = self.combineSpanNameWithTag(spanName: spanName, tag: cid)
        self.startRootSpan(spanName: sendMessageSpanName, displaySpanName: spanName)
    }

    public static func sendMessageStartChildSpanByPName(spanName: String, parentName: String, cid: String) {
        guard self.tracingEnable else {
            return
        }
        let sendMessageSpanName = self.combineSpanNameWithTag(spanName: spanName, tag: cid)
        let sendMessageParentName = self.combineSpanNameWithTag(spanName: parentName, tag: cid)
        self.startChildSpanByPName(spanName: sendMessageSpanName, parentName: sendMessageParentName, displaySpanName: spanName)
    }

    public static func sendMessageEndSpanByName(spanName: String, cid: String, tags: [String: Any]? = nil, error: Bool? = false) {
        guard self.tracingEnable else {
            return
        }
        let sendMessageSpanName = self.combineSpanNameWithTag(spanName: spanName, tag: cid)
        self.endSpanByName(spanName: sendMessageSpanName, tags: tags, error: error)
    }

    public static func sendMessageGetSpanIDByName(spanName: String, cid: String) -> UInt64? {
        guard self.tracingEnable else {
            return 0
        }
        let sendMessageSpanName = self.combineSpanNameWithTag(spanName: spanName, tag: cid)
        return self.getSpanIDByName(spanName: sendMessageSpanName)
    }
}
