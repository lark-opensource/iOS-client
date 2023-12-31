//
//  MinutesDataTransfer.swift
//  LarkMinutes
//
//  Created by lvdaqian on 2021/2/3.
//

import Foundation
import ServerPB
import MinutesFoundation
import MinutesNetwork

extension CommentContent {
    init(_ pb: ServerPB_Meeting_object_CommentContentItem) {
        self.init(avatarUrl: pb.avatarURL,
               userID: pb.userID,
               userName: pb.userName,
               content: pb.content,
                  contentForIM: (pb.contentForIm.isEmpty ? nil : pb.contentForIm.map({ ContentForIMItem($0) })),
               createTime: Int(pb.createTime),
               updateTime: Int(pb.updateTime),
               id: pb.contentID)
    }
}

extension ContentForIMItem {
    init(_ pb: ServerPB_Meeting_object_IMContentNode) {
        self.init(contentType: pb.contentType,
                  content: pb.textContent,
                  attr: pb.hasAttr ? ContentForIMItemAttr(pb.attr) : nil)
    }
}


extension ContentForIMItemAttr {
    init(_ pb: ServerPB_Meeting_object_IMContentAttr) {
        self.init(type: pb.type, token: pb.token, key: pb.key, messageId: pb.messageID, crypto: (pb.hasCrypto ? CommentImageCrypto(pb.crypto) : nil), origin: (pb.hasOrigin ? CommentImageAttr(pb.origin) : nil), thumbnail: (pb.hasThumbnail ? CommentImageAttr(pb.thumbnail) : nil), href: pb.href, docsType: pb.docsType, iconInfo: (pb.hasIconInfo ? CommentForIMFileIcon(pb.iconInfo) : nil))
    }
}

extension CommentForIMFileIcon {
    init(_ pb: ServerPB_Meeting_object_FileIconInfo) {
        self.init(iconInfo: (pb.hasIconInfo ? CommentForIMFileIconMata(pb.iconInfo) : nil), iconUri: pb.iconUri)
    }
}

extension CommentForIMFileIconMata {
    init(_ pb: ServerPB_Meeting_object_IconStruct) {
        self.init(type: pb.type, key: pb.key, objType: pb.objType, fileType:pb.fileType)
    }
}

extension CommentImageAttr {
    init(_ pb: ServerPB_Meeting_object_IMImage) {
        self.init(key: pb.key, fsUnit: pb.fsUnit, width: pb.width, height: pb.height)
    }
}

extension CommentImageCrypto {
    init(_ pb: ServerPB_Meeting_object_Crypto) {
        self.init(type: pb.type, cipher: CommentImageCipher(pb.cipher))
    }
}


extension CommentImageCipher {
    init(_ pb: ServerPB_Meeting_object_Cipher) {
        self.init(secret: String(data: pb.secret, encoding: .utf8) ?? "", nonce: String(data: pb.nonce, encoding: .utf8) ?? "")
    }
}

extension Comment {
    init(_ pb: ServerPB_Meeting_object_CommentItem) {
        self.init(uuid: pb.uuid,
                  quote: pb.quote,
                  contents: pb.commentContentList.map({ CommentContent($0) }),
                  createTime: Int(pb.createTime),
                  updateTime: Int(pb.updateTime),
                  id: pb.commentID)
    }
}

extension ParagraphCommentsInfo {
    init(_ pb: ServerPB_Meeting_object_ParagraphComment) {
        self.init(pid: pb.pid,
                  commentNum: Int(pb.commentNum),
                  commentList: pb.commentList.map({ Comment($0) }))
    }
}

extension ParagraphCommentsInfoV2 {
    init(_ pb: ServerPB_Meeting_object_ParagraphCommentV2) {
        self.init(pid: pb.pid,
                  commentNum: Int(pb.commentNum))
    }
}


extension Paragraph {
    init(_ pb: ServerPB_Meeting_object_SubtitleParagraph) {
        self.init(id: pb.pid,
                  startTime: pb.startTime,
                  stopTime: pb.stopTime,
                  type: ParagraphType(rawValue: Int(pb.paragraphType)),
                  speaker: Participant(pb.speaker),
                  sentences: pb.sentences.map({ Sentence($0) }))
    }
}

extension Participant {
    init(_ pb: ServerPB_Meeting_object_Participant) {
        self.init(userID: pb.userID,
                  deviceID: pb.deviceID,
                  userType: UserType(rawValue: pb.userType.rawValue),
                  userName: pb.userName,
                  avatarURL: URL(string: pb.avatarURL),
                  isExternal: pb.isExternal,
                  isHostUser: pb.isHostUser)
    }
}

extension Sentence {
    init(_ pb: ServerPB_Meeting_object_SubtitleSentence) {
        self.init(id: pb.sid,
                  language: pb.language,
                  startTime: pb.startTime,
                  stopTime: pb.stopTime,
                  contents: pb.contents.map({ Content($0) }),
                  highlight: pb.highlight.map({ Highlight($0) }))
    }
}

extension Content {
    init(_ pb: ServerPB_Meeting_object_SubtitleWord) {
        self.init(id: pb.cid,
                  language: pb.language,
                  startTime: pb.startTime,
                  stopTime: pb.stopTime,
                  content: pb.content)
    }
}

extension Highlight {
    init(_ pb: ServerPB_Meeting_object_HighlightItemInSubtitle) {
        self.init(offset: Int(pb.offset),
                  size: Int(pb.size),
                  type: Int(pb.type),
                  seq: nil,
                  uuid: pb.uuid,
                  commentID: pb.commentID,
                  startTime: nil,
                  id: pb.highlightID)
    }
}

extension ReactionInfo {
    init(_ pb: ServerPB_Meeting_object_HighlightTimeLineItem) {
        self.init(type: Int(pb.type),
                  emojiCode: pb.emojiCode,
                  count: nil,
                  startTime: Int(pb.startTime))
    }
}
