//
//  TabAccessInfos.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_AccessInfos
public struct TabAccessInfos: Equatable {
    public init(pstnIncomingSetting: PstnIncomingSetting, sipSetting: VideoChatSettings.SIPSetting, h323Setting: H323Setting) {
        self.pstnIncomingSetting = pstnIncomingSetting
        self.sipSetting = sipSetting
        self.h323Setting = h323Setting
    }

    /// pstn 配置
    public var pstnIncomingSetting: PstnIncomingSetting

    /// sip 配置
    public var sipSetting: VideoChatSettings.SIPSetting

    /// h323 配置
    public var h323Setting: H323Setting

    /// Videoconference_V1_VideoChatPstnIncomingSetting
    public struct PstnIncomingSetting: Equatable {
        public init(pstnEnableIncomingCall: Bool, pstnIncomingCallCountryDefault: [String], pstnIncomingCallPhoneList: [PSTNPhone]) {
            self.pstnEnableIncomingCall = pstnEnableIncomingCall
            self.pstnIncomingCallCountryDefault = pstnIncomingCallCountryDefault
            self.pstnIncomingCallPhoneList = pstnIncomingCallPhoneList
        }

        /// PSTN 是否允电话呼叫参会(呼入)
        public var pstnEnableIncomingCall: Bool

        /// PSTN 呼入默认国家
        public var pstnIncomingCallCountryDefault: [String]

        /// PSTN 呼入号码列表
        public var pstnIncomingCallPhoneList: [PSTNPhone]
    }
}
