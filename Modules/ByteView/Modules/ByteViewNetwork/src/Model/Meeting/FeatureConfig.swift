//
//  VideoChatFeatureConfig.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_FeatureConfig， doc: https://bytedance.feishu.cn/docs/doccnOjMaLngjJcVPssUztr8zFe
public struct FeatureConfig: Equatable {
    public init(liveEnable: Bool, recordEnable: Bool, localRecordEnable: Bool, hostControlEnable: Bool,
                pstn: Pstn, shareMeeting: ShareMeeting, sip: Sip, magicShare: MagicShare, relationChain: RelationChain,
                interpretationEnable: Bool, chatHistoryEnabled: Bool, recordCloseReason: RecordCloseReason,
                voteConfig: VoteConfig, whiteboardConfig: WhiteboardConfig, transcriptConfig: TranscriptConfig, myAIConfig: MyAIConfig) {
        self.liveEnable = liveEnable
        self.recordEnable = recordEnable
        self.localRecordEnable = localRecordEnable
        self.hostControlEnable = hostControlEnable
        self.pstn = pstn
        self.shareMeeting = shareMeeting
        self.sip = sip
        self.magicShare = magicShare
        self.relationChain = relationChain
        self.interpretationEnable = interpretationEnable
        self.chatHistoryEnabled = chatHistoryEnabled
        self.recordCloseReason = recordCloseReason
        self.voteConfig = voteConfig
        self.whiteboardConfig = whiteboardConfig
        self.transcriptConfig = transcriptConfig
        self.myAIConfig = myAIConfig
    }

    public init() {
        self.init(liveEnable: false, recordEnable: false, localRecordEnable: false, hostControlEnable: false,
                  pstn: .init(outGoingCallEnable: false, incomingCallEnable: false),
                  shareMeeting: .init(inviteEnable: false, copyMeetingLinkEnable: false, shareCardEnable: false),
                  sip: .init(outGoingCallEnable: false, incomingCallEnable: false),
                  magicShare: .init(startCcmEnable: false, newCcmEnable: false),
                  relationChain: .init(browseUserProfileEnable: false, enterGroupEnable: false),
                  interpretationEnable: false, chatHistoryEnabled: false, recordCloseReason: .unknown,
                  voteConfig: .init(allowVote: false, quotaIsOn: false), whiteboardConfig: .init(startWhiteboardEnable: false), transcriptConfig: .init(transcriptEnable: false), myAIConfig: .init(myAiEnable: false))
    }

    public var liveEnable: Bool

    public var recordEnable: Bool

    /// 是否允许本地录制
    public var localRecordEnable: Bool

    public var hostControlEnable: Bool

    public var pstn: Pstn

    public var shareMeeting: ShareMeeting

    public var sip: Sip

    public var magicShare: MagicShare

    public var relationChain: RelationChain

    /// 同声传译是否可用
    public var interpretationEnable: Bool

    // 是否支持会中聊天历史记录
    public var chatHistoryEnabled: Bool

    public var recordCloseReason: RecordCloseReason

    public var voteConfig: VoteConfig

    public var whiteboardConfig: WhiteboardConfig

    public var transcriptConfig: TranscriptConfig

    public var myAIConfig: MyAIConfig

    public struct Sip: Equatable {
        public var outGoingCallEnable: Bool
        public var incomingCallEnable: Bool
        public init(outGoingCallEnable: Bool, incomingCallEnable: Bool) {
            self.outGoingCallEnable = outGoingCallEnable
            self.incomingCallEnable = incomingCallEnable
        }
    }

    public struct Pstn: Equatable {
        public var outGoingCallEnable: Bool
        public var incomingCallEnable: Bool
        public init(outGoingCallEnable: Bool, incomingCallEnable: Bool) {
            self.outGoingCallEnable = outGoingCallEnable
            self.incomingCallEnable = incomingCallEnable
        }
    }


    public struct ShareMeeting: Equatable {
        /// 会中的呼叫
        public var inviteEnable: Bool

        /// 分享会议链接
        public var copyMeetingLinkEnable: Bool

        /// 分享会议卡片
        public var shareCardEnable: Bool

        public init(inviteEnable: Bool, copyMeetingLinkEnable: Bool, shareCardEnable: Bool) {
            self.inviteEnable = inviteEnable
            self.copyMeetingLinkEnable = copyMeetingLinkEnable
            self.shareCardEnable = shareCardEnable
        }
    }

    public struct MagicShare: Equatable {

        /// 发起ccm共享
        public var startCcmEnable: Bool

        /// 新建 ccm文档
        public var newCcmEnable: Bool

        public init(startCcmEnable: Bool, newCcmEnable: Bool) {
            self.startCcmEnable = startCcmEnable
            self.newCcmEnable = newCcmEnable
        }
    }

    public struct RelationChain: Equatable {
        ///查看user_profile
        public var browseUserProfileEnable: Bool

        /// 创建群和进入群操作，当前主要是用来控制 日历想起中群按钮的显示
        public var enterGroupEnable: Bool

        public init(browseUserProfileEnable: Bool, enterGroupEnable: Bool) {
            self.browseUserProfileEnable = browseUserProfileEnable
            self.enterGroupEnable = enterGroupEnable
        }
    }

    public enum RecordCloseReason: Int {
        case unknown
        case admin
    }

    public struct VoteConfig: Equatable {
        public var allowVote: Bool
        public var quotaIsOn: Bool
    }

    public struct WhiteboardConfig: Equatable {
        public var startWhiteboardEnable: Bool
    }

    public struct TranscriptConfig: Equatable {
        public var transcriptEnable: Bool
    }

    public struct MyAIConfig: Equatable {
        /// my ai入口配置
        public var myAiEnable: Bool
    }
}

extension FeatureConfig: CustomStringConvertible {
    public var description: String {
        String(
            indent: "FeatureConfig",
            "live=\(liveEnable.toInt)",
            "record=\(recordEnable.toInt)",
            "localRecord=\(localRecordEnable.toInt)",
            "host=\(hostControlEnable.toInt)",
            "interpret=\(interpretationEnable.toInt)",
            "chatHistory=\(chatHistoryEnabled.toInt)",
            "\(pstn)",
            "\(sip)",
            "\(shareMeeting)",
            "\(magicShare)",
            "\(relationChain)",
            "\(voteConfig)",
            "startWhiteboardEnable:\(whiteboardConfig.startWhiteboardEnable)",
            "transcriptEnable:\(transcriptConfig.transcriptEnable)",
            "myAIEnabled: \(myAIConfig.myAiEnable)"
        )
    }
}

extension FeatureConfig.VoteConfig: CustomStringConvertible {
    public var description: String {
        String(indent: "Vote", "allow=\(allowVote.toInt)", "quota=\(quotaIsOn.toInt)")
    }
}

extension FeatureConfig.Pstn: CustomStringConvertible {
    public var description: String {
        String(indent: "Pstn", "out=\(outGoingCallEnable.toInt)", "in=\(incomingCallEnable.toInt)")
    }
}

extension FeatureConfig.Sip: CustomStringConvertible {
    public var description: String {
        String(indent: "Sip", "out=\(outGoingCallEnable.toInt)", "in=\(incomingCallEnable.toInt)")
    }
}

extension FeatureConfig.ShareMeeting: CustomStringConvertible {
    public var description: String {
        String(indent: "ShareMeeting",
               "invite=\(inviteEnable.toInt)",
               "copy=\(copyMeetingLinkEnable.toInt)",
               "share=\(shareCardEnable.toInt)")
    }
}

extension FeatureConfig.MagicShare: CustomStringConvertible {
    public var description: String {
        String(indent: "MagicShare", "start=\(startCcmEnable.toInt)", "new=\(newCcmEnable.toInt)")
    }
}

extension FeatureConfig.RelationChain: CustomStringConvertible {
    public var description: String {
        String(indent: "RelationChain", "profile=\(browseUserProfileEnable.toInt)", "group=\(enterGroupEnable.toInt)")
    }
}
