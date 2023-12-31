//
//  DevAudio.swift
//  ByteViewTracker
//
//  Created by fakegourmet on 2022/2/18.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

extension DevTrackEvent {

    /// 音频
    public enum Audio: String {
        case media_service_lost
        case media_service_reset
        case app_was_suspend
        case built_in_mic_muted
        /// 会中audio session被停止
        case deactived_in_vc
        case category_changed_in_vc
        case mode_changed_in_vc
        case category_options_changed_in_vc
        /// route picker view
        case picker_view_bad_access

        /// audio unit
        case audio_unit_start
        case audio_unit_stop

        /// media service lost 到 media service reset 耗时
        case media_lost_reset_time
        /// media service lost 到 audio unit start 成功耗时
        case media_lost_start_time
        /// interrupt 到 interrupt resume 耗时
        case interrupt_resume_time
        /// interrupt 到 audio unit start 成功耗时
        case interrupt_start_time
        /// overrideOutputAudioPort 调用失败或无效
        case override_output_auidio_port_failed

        /// 媒体锁未及时释放
        case media_lock_leak
        /// AudioSession未及时释放
        case audio_session_scenario_leak
    }

}
