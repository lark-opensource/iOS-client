//
//  SheetSegmentParser.swift
//  SKSheet
//
//  Created by lijuyou on 2022/4/5.
//  


import Foundation
import HandyJSON
import SKBrowser

struct SheetSegmentParser {
    static func parse(_ data: [[String: Any]], style: SheetStyleJSON? = nil) -> [SheetSegmentBase] {
        var sink = [SheetSegmentBase]()
        for currentRawValue in data {
            let currentSegmentBase = SheetSegmentBase.deserialize(from: currentRawValue) ?? SheetSegmentBase()
            switch currentSegmentBase.type {
            case .text:
                let textSeg = SheetTextSegment.deserialize(from: currentRawValue) ?? SheetTextSegment()
                if currentRawValue["style"] == nil {
                    textSeg.style = style
                }
                sink.append(textSeg)
            case .url:
                let urlSeg = SheetHyperLinkSegment.deserialize(from: currentRawValue) ?? SheetHyperLinkSegment()
                if currentRawValue["style"] == nil {
                    urlSeg.style = style
                }
                sink.append(urlSeg)
            case .mention:
                let mentionSeg = SheetMentionSegment.deserialize(from: currentRawValue) ?? SheetMentionSegment()
                if currentRawValue["style"] == nil {
                    mentionSeg.style = style
                }
                sink.append(mentionSeg)
            case .attachment:
                let attachSeg = SheetAttachmentSegment.deserialize(from: currentRawValue) ?? SheetAttachmentSegment()
                if currentRawValue["style"] == nil {
                    attachSeg.style = style
                }
                sink.append(attachSeg)
            case .embedImage:
                let imgSeg = SheetEmbedImageSegment.deserialize(from: currentRawValue) ?? SheetEmbedImageSegment()
                if currentRawValue["style"] == nil {
                    imgSeg.style = style
                }
                sink.append(imgSeg)
            case .pano:
                let panoSeg = SheetPanoSegment.deserialize(from: currentRawValue) ?? SheetPanoSegment()
                if currentRawValue["style"] == nil {
                    panoSeg.style = style
                }
                sink.append(panoSeg)
            }
        }
        return sink
    }
}
