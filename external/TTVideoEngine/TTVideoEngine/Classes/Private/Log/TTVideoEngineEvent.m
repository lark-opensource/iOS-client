//
//  TTVideoEngineEvent.m
//  Pods
//
//  Created by guikunzhi on 16/12/23.
//
//

#import "TTVideoEngineEvent.h"
#import "NSDictionary+TTVideoEngine.h"
#import "NSArray+TTVideoEngine.h"
#import "TTVideoEngineEventManager.h"
#import "TTVideoEngineUtilPrivate.h"
#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"
#import <AVFoundation/AVFoundation.h>
#import "TTVideoEngineStrategy.h"
#import "TTVideoEngineEventLoggerProtocol.h"

@implementation TTVideoEngineEvent

- (instancetype)init {
    if (self = [super init]) {
        [self initMembers];
    }
    return self;
}

- (instancetype)initWithEventBase:(TTVideoEngineEventBase *)base {
    if (self = [super init]) {
        [self initMembers];
        _eventBase = base;
    }
    return self;
}

/**
 * 如果不是每次必须要上报的埋点，建议默认值置为
 * 整形:LOGGER_INTEGER_EMPTY_VALUE
 * 浮点型:LOGGER_FLOAT_EMPTY_VALUE
 * 其他对象类:nil
 */
- (void)initMembers {
    _eventBase = nil;
    _pt = LOGGER_INTEGER_EMPTY_VALUE;
    _at = LOGGER_INTEGER_EMPTY_VALUE;
    _vt = LOGGER_INTEGER_EMPTY_VALUE;
    _et = LOGGER_INTEGER_EMPTY_VALUE;
    _lt = LOGGER_INTEGER_EMPTY_VALUE;
    _bft = LOGGER_INTEGER_EMPTY_VALUE;
    _bc = 0, _br = 0, _lc = 0;
    _vu = [NSMutableArray array];
    _vd = LOGGER_INTEGER_EMPTY_VALUE;
    _vs = LOGGER_INTEGER_EMPTY_VALUE;
    _vps = LOGGER_INTEGER_EMPTY_VALUE;
    _vds = LOGGER_INTEGER_EMPTY_VALUE;
    _video_preload_size = LOGGER_INTEGER_EMPTY_VALUE;
    _errt = LOGGER_INTEGER_EMPTY_VALUE;
    _errc = LOGGER_INTEGER_EMPTY_VALUE;
    _df = nil, _lf = nil, _initial_host = @"", _initial_ip = @"", _initial_resolution = @"";
    _prepare_start_time = LOGGER_INTEGER_EMPTY_VALUE;
    _prepare_end_time = LOGGER_INTEGER_EMPTY_VALUE;
    _render_type = @"";
    _vpls = LOGGER_INTEGER_EMPTY_VALUE;
    _finish = LOGGER_INTEGER_EMPTY_VALUE;
    _cur_play_pos = LOGGER_INTEGER_EMPTY_VALUE;
    _seek_acu_t = 0;
    _video_out_fps = LOGGER_FLOAT_EMPTY_VALUE;
    _watch_dur = LOGGER_INTEGER_EMPTY_VALUE;
    _switch_resolution_c = 0;
    _sc = LOGGER_INTEGER_EMPTY_VALUE;
    _mem_use = LOGGER_FLOAT_EMPTY_VALUE;
    _cpu_use = LOGGER_FLOAT_EMPTY_VALUE;
    _audio_drop_cnt = LOGGER_INTEGER_EMPTY_VALUE;
    _playparam = [NSMutableDictionary dictionary];
    _per_buffer_duration = [NSMutableArray array];
    _merror = [NSMutableDictionary dictionary];
    _ex = [NSMutableDictionary dictionary];
    _mFeatures = [NSMutableDictionary dictionary];
    _initialURL = nil;
    _customStr = nil;
    _vsc = LOGGER_INTEGER_EMPTY_VALUE;
    _first_buf_startt = LOGGER_INTEGER_EMPTY_VALUE;
    _first_buf_endt = LOGGER_INTEGER_EMPTY_VALUE;
    _video_model_version = LOGGER_INTEGER_EMPTY_VALUE;
    _vtype = nil;
    _width = LOGGER_INTEGER_EMPTY_VALUE;
    _height = LOGGER_INTEGER_EMPTY_VALUE;
    _api_string = @"";
    _net_client = @"";
    _engine_state = LOGGER_INTEGER_EMPTY_VALUE;
    _apiver = LOGGER_INTEGER_EMPTY_VALUE;
    _auth = nil;
    _start_time = LOGGER_INTEGER_EMPTY_VALUE;
    _bitrate = LOGGER_INTEGER_EMPTY_VALUE;
    _audioBitrate = LOGGER_INTEGER_EMPTY_VALUE;
    _enable_bash = LOGGER_INTEGER_EMPTY_VALUE;
    _dynamic_type = nil;
    _traceID = nil;
    _last_seek_start_t = LOGGER_INTEGER_EMPTY_VALUE;
    _last_seek_end_t = LOGGER_INTEGER_EMPTY_VALUE;
    _last_buffer_start_t = LOGGER_INTEGER_EMPTY_VALUE;
    _last_buffer_end_t = LOGGER_INTEGER_EMPTY_VALUE;
    _last_resolution_start_t = LOGGER_INTEGER_EMPTY_VALUE;
    _last_resolution_end_t = LOGGER_INTEGER_EMPTY_VALUE;
    _last_seek_positon = LOGGER_INTEGER_EMPTY_VALUE;
    _enable_boe = LOGGER_INTEGER_EMPTY_VALUE;
    _dns_server_ip = nil;
    _leave_method = LOGGER_INTEGER_EMPTY_VALUE;
    _initial_quality = @"";
    _internal_ip = @"";
    _check_hijack = LOGGER_INTEGER_EMPTY_VALUE;
    _first_hijack_code = LOGGER_INTEGER_EMPTY_VALUE;
    _last_hijack_code = LOGGER_INTEGER_EMPTY_VALUE;
    _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_LOADING_NOT_FETCH;
    _leave_block_t = LOGGER_INTEGER_EMPTY_VALUE;
    _dnsMode = LOGGER_INTEGER_EMPTY_VALUE;
    _enable_mdl = LOGGER_INTEGER_EMPTY_VALUE;
    _mdl_version = nil;
    _first_errc = LOGGER_INTEGER_EMPTY_VALUE;
    _first_errt = LOGGER_INTEGER_EMPTY_VALUE;
    _first_errc_internal = LOGGER_INTEGER_EMPTY_VALUE;
    _prepare_before_play_t = LOGGER_INTEGER_EMPTY_VALUE;
    //subtitle
    _sub_error = nil;
    _sub_languages_count = LOGGER_INTEGER_EMPTY_VALUE;
    _sub_enable_opt_load = LOGGER_INTEGER_EMPTY_VALUE;
    _sub_lang_switch_count = 0;
    _sub_load_finished_time = LOGGER_INTEGER_EMPTY_VALUE;
    _sub_request_finished_time = LOGGER_INTEGER_EMPTY_VALUE;
    _sub_req_url = nil;
    _sub_enable = LOGGER_INTEGER_EMPTY_VALUE;
    _sub_thread_enable = LOGGER_INTEGER_EMPTY_VALUE;
    //mask
    _mask_open_time = LOGGER_INTEGER_EMPTY_VALUE;
    _mask_opened_time = LOGGER_INTEGER_EMPTY_VALUE;
    _mask_error_code = LOGGER_INTEGER_EMPTY_VALUE;
    _mask_thread_enable = LOGGER_INTEGER_EMPTY_VALUE;
    _mask_enable = LOGGER_INTEGER_EMPTY_VALUE;
    _mask_url = nil;
    
    _setds_t = LOGGER_INTEGER_EMPTY_VALUE;
    _ps_t = LOGGER_INTEGER_EMPTY_VALUE;
    _pt_new = LOGGER_INTEGER_EMPTY_VALUE;
    _a_dns_start_t = LOGGER_INTEGER_EMPTY_VALUE;
    _a_dns_t = LOGGER_INTEGER_EMPTY_VALUE;
    _formater_create_t = LOGGER_INTEGER_EMPTY_VALUE;
    _avformat_open_t = LOGGER_INTEGER_EMPTY_VALUE;
    _demuxer_begin_t = LOGGER_INTEGER_EMPTY_VALUE;
    _demuxer_create_t = LOGGER_INTEGER_EMPTY_VALUE;
    _dec_create_t = LOGGER_INTEGER_EMPTY_VALUE;
    _outlet_create_t = LOGGER_INTEGER_EMPTY_VALUE;
    _v_render_f_t = LOGGER_INTEGER_EMPTY_VALUE;
    _a_render_f_t = LOGGER_INTEGER_EMPTY_VALUE;
    _a_dec_start_t = LOGGER_INTEGER_EMPTY_VALUE;
    _a_dec_opened_t = LOGGER_INTEGER_EMPTY_VALUE;
    _v_dec_start_t = LOGGER_INTEGER_EMPTY_VALUE;
    _v_dec_opened_t = LOGGER_INTEGER_EMPTY_VALUE;
    _dns_start_t = LOGGER_INTEGER_EMPTY_VALUE;
    _dns_end_t = LOGGER_INTEGER_EMPTY_VALUE;
    _video_stream_disabled = 0;
    _audio_stream_disabled = 0;
    _isReplay = LOGGER_INTEGER_EMPTY_VALUE;
    _av_gap = LOGGER_INTEGER_EMPTY_VALUE;
    _moov_pos = LOGGER_INTEGER_EMPTY_VALUE;
    _mdat_pos = LOGGER_INTEGER_EMPTY_VALUE;
    _min_audio_frame_size = LOGGER_INTEGER_EMPTY_VALUE;
    _min_video_frame_size = LOGGER_INTEGER_EMPTY_VALUE;
    _feed_in_before_decoded = LOGGER_INTEGER_EMPTY_VALUE;
    _a_tran_ct = LOGGER_INTEGER_EMPTY_VALUE;
    _a_tran_ft = LOGGER_INTEGER_EMPTY_VALUE;
    _enable_nnsr = LOGGER_INTEGER_EMPTY_VALUE;
    _container_fps = LOGGER_INTEGER_EMPTY_VALUE;
    _log_id = nil;
    _video_codec_profile = LOGGER_INTEGER_EMPTY_VALUE;
    _audio_codec_profile = LOGGER_INTEGER_EMPTY_VALUE;
    _mAVOutsyncCount = LOGGER_INTEGER_EMPTY_VALUE;
    _avOutsyncList = [[TTVideoEngineEventListModel alloc] init];
    _no_a_list = [[TTVideoEngineEventListModel alloc] init];
    _no_v_list = [[TTVideoEngineEventListModel alloc] init];
    _rebufList = [[TTVideoEngineEventListModel alloc] init];
    _seek_list = [[TTVideoEngineEventListModel alloc] init];
    _resolution_list = [[TTVideoEngineEventListModel alloc] init];
    _pause_list = [[TTVideoEngineEventListModel alloc] init];
    _play_list = [[TTVideoEngineEventListModel alloc] init];
    _error_list = [[TTVideoEngineEventListModel alloc] init];
    _playspeed_list = [[TTVideoEngineEventListModel alloc] init];
    _radiomode_list = [[TTVideoEngineEventListModel alloc] init];
    _loop_list = [[TTVideoEngineEventListModel alloc] init];
    _bright_list = [[TTVideoEngineEventListModel alloc] init];
    _view_size_list = [[TTVideoEngineEventListModel alloc] init];
    _foreback_switch_list = [[TTVideoEngineEventListModel alloc] init];
    _headset_switch_list = [[TTVideoEngineEventListModel alloc] init];
    _bad_interlaced_list = [[TTVideoEngineEventListModel alloc] init];
    _cur_view_bounds = CGRectZero;
    _cur_brightness = LOGGER_FLOAT_EMPTY_VALUE;
    _mDropCount = LOGGER_INTEGER_EMPTY_VALUE;
    _color_trc = LOGGER_INTEGER_EMPTY_VALUE;
    _color_space = LOGGER_INTEGER_EMPTY_VALUE;
    _color_primaries = LOGGER_INTEGER_EMPTY_VALUE;
    _video_pixel_bit = LOGGER_INTEGER_EMPTY_VALUE;
    _core_volume = LOGGER_INTEGER_EMPTY_VALUE;
    _isMute = LOGGER_INTEGER_EMPTY_VALUE;
    _volume = LOGGER_INTEGER_EMPTY_VALUE;
    _before_play_buf_startt = LOGGER_INTEGER_EMPTY_VALUE;
    _before_play_buf_endt = LOGGER_INTEGER_EMPTY_VALUE;
    _video_buffer_len = LOGGER_INTEGER_EMPTY_VALUE;
    _audio_buffer_len = LOGGER_INTEGER_EMPTY_VALUE;
    _v_decbuf_len = LOGGER_INTEGER_EMPTY_VALUE;
    _a_decbuf_len = LOGGER_INTEGER_EMPTY_VALUE;
    _v_basebuf_len = LOGGER_INTEGER_EMPTY_VALUE;
    _a_basebuf_len = LOGGER_INTEGER_EMPTY_VALUE;
    _mIsEngineReuse = NO;
    _playerview_hidden = LOGGER_INTEGER_EMPTY_VALUE;
    _video_decoder_fps = LOGGER_INTEGER_EMPTY_VALUE;
    _network_connect_count = LOGGER_INTEGER_EMPTY_VALUE;
    _v_http_open_t = LOGGER_INTEGER_EMPTY_VALUE;
    _a_http_open_t = LOGGER_INTEGER_EMPTY_VALUE;
    _v_tran_open_t = LOGGER_INTEGER_EMPTY_VALUE;
    _a_tran_open_t = LOGGER_INTEGER_EMPTY_VALUE;
    _v_sock_create_t = LOGGER_INTEGER_EMPTY_VALUE;
    _a_sock_create_t = LOGGER_INTEGER_EMPTY_VALUE;
    _mEnableGlobalMuteFeature = NO;
    _mGlobalMuteDic = nil;
    _video_style = LOGGER_INTEGER_EMPTY_VALUE;
    _dimension = LOGGER_INTEGER_EMPTY_VALUE;
    _projection_model = LOGGER_INTEGER_EMPTY_VALUE;
    _view_size = LOGGER_INTEGER_EMPTY_VALUE;
    _mMDLRetryInfo = nil;
    _crosstalk_count = LOGGER_INTEGER_EMPTY_VALUE;
    _crosstalk_info_list = nil;
    _mFromEnginePool = nil;
    _mEngineHash = LOGGER_INTEGER_EMPTY_VALUE;
    _mCorePoolSizeUpperLimit = LOGGER_INTEGER_EMPTY_VALUE;
    _mCorepoolSizeBeforeGetEngine = LOGGER_INTEGER_EMPTY_VALUE;
    _mCountOfEngineInUse = LOGGER_INTEGER_EMPTY_VALUE;
    _st_speed = LOGGER_FLOAT_EMPTY_VALUE;
    _mExpirePlayCode = 0;
    _accu_vds = LOGGER_INTEGER_EMPTY_VALUE;
    _mMaskDownloadSize = LOGGER_INTEGER_EMPTY_VALUE;
    _mSubtitleDownloadSize = LOGGER_INTEGER_EMPTY_VALUE;
    _mask_enable_mdl = LOGGER_INTEGER_EMPTY_VALUE;
    _mask_file_hash = nil;
    _mask_file_size = LOGGER_INTEGER_EMPTY_VALUE;
    _mPreloadGear = nil;
    _mVideoFileHash = nil;
    _mAudioFileHash = nil;
    _netblockBufferthreshold = LOGGER_INTEGER_EMPTY_VALUE;
    _mCustomCompanyId = nil;
}

- (void)parseLeaveReason {
    //解析未起播离开原因,按照起播流程的顺序拆分
    if ([_eventBase.source_type isEqualToString:@"vid"]) {
        if (_at <= 0) {
            _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_LOADING_NOT_FETCH;
        }
    }
    if (_dns_end_t <= 0 && _a_dns_t <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_DNS_NOT_PARSED;
        return;
    }
    if (_prepare_start_time <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_LOADING_FETCHED;
        return;
    }
    if (_formater_create_t <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_FORMATER_CREATING;
        return;
    }
    if (_demuxer_begin_t <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_DEMUXER_CREATING;
        return;
    }
    if (_tran_ct <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_TCP_CONNECTING;
        return;
    }
    if (_tran_ft <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_TCP_FIRST_PACKET;
        return;
    }
    if (_avformat_open_t <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_AVFORMAT_OPENING;
        return;
    }
    if (_demuxer_create_t <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_AVFORMAT_FIND_STREAM;
        return;
    }
    if (_dec_create_t <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_DEC_CREATING;
        return;
    } else {
        if (_eventBase.radioMode == 0 && _v_dec_opened_t <= 0) {
            _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_VIDEO_DECODER_OPENING;
            return;
        }
        if (_a_dec_opened_t <= 0) {
            _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_AUDIO_DECODER_OPENING;
            return;
        }
    }
    if (_outlet_create_t <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_OUTLET_CREATING;
        return;
    } else {
        if (_eventBase.radioMode == 0 && _video_opened_time <= 0) {
            _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_VIDEO_DEVICE_OPENING;
            return;
        }
        if (_audio_opened_time <= 0) {
            _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_AUDIO_DEVICE_OPENING;
            return;
        }
    }
    if (_eventBase.radioMode == 0 && _re_f_videoframet <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_VIDEO_FIRST_PACKET;
        return;
    }
    if (_re_f_audioframet <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_AUDIO_FIRST_PACKET;
        return;
    }
    if (_eventBase.radioMode == 0 && _de_f_videoframet <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_VIDEO_DECODE_FIRST_FRAME;
        return;
    }
    if (_de_f_audioframet <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_AUDIO_DECODE_FIRST_FRAME;
        return;
    }
    if (_eventBase.radioMode == 0 && _v_render_f_t <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_VIDEO_RENDER_FIRST_FRAME;
        return;
    }
    if (_a_render_f_t <= 0) {
        _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_AUDIO_RENDER_FIRST_FRAME;
        return;
    }
    _leave_reason = ONEPLAY_EXIT_CODE_BEFORE_FIRST_FRAME_MSG_NOT_REPORT;
}

- (NSDictionary *)jsonDict {
    TTVideoEngineEventUtil *sharedEventUtil = [TTVideoEngineEventUtil sharedInstance];
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    if (_eventBase != nil) {
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"sv", _eventBase.sv);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"pv", _eventBase.pv);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"pc", _eventBase.pc);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"sdk_version", _eventBase.sdk_version);
        if (_eventBase.source_type && ![_eventBase.source_type isEqualToString:@"dir_url"]) {
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"v", _eventBase.vid);
        }
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"source_type", _eventBase.source_type);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"drm_type", @(_eventBase.drm_type));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"drm_token_url", _eventBase.drm_token_url);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"play_type", @(_eventBase.play_type));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_codec_nameId", @(_eventBase.audio_codec_nameId));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_codec_nameId", @(_eventBase.video_codec_nameId));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"format_type", @(_eventBase.format_type));
        NSInteger hw = _eventBase.hw ? 1 : 0;
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"hw", @(hw));
        NSInteger hw_user = _eventBase.hw_user ? 1 : 0;
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"hw_user", @(hw_user));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"abr_info", _eventBase.abr_info);
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_duration", @(_eventBase.video_stream_duration));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_duration", @(_eventBase.audio_stream_duration));
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"r_stage_errcs", _eventBase.r_stage_errcs);
        
        {
            //add for version2
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"app_sessionid", sharedEventUtil.appSessionId);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"player_sessionid", _eventBase.session_id);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"last_sessionid", sharedEventUtil.lastPlaySessionId);
            sharedEventUtil.lastPlaySessionId = _eventBase.session_id ?: @"";
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"lv_reason", @(_leave_reason));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"lv_bt", @(_leave_block_t));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"net_type", [_eventBase getNetworkType]);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"radio_mode", @(_eventBase.radioMode));
            
            //mdl related
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_loader_type", _mdl_loader_type);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_req_pos", @(_eventBase.mdl_cur_req_pos));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_end_pos", @(_eventBase.mdl_cur_end_pos));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_cache_pos", @(_eventBase.mdl_cur_cache_pos));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cache_type", @(_eventBase.mdl_cache_type));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_ip", _eventBase.mdl_cur_ip);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_host", _eventBase.mdl_cur_host);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_url", _eventBase.mdl_cur_url);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"reply_size", @(_eventBase.mdl_reply_size));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"down_pos", @(_eventBase.mdl_down_pos));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"player_wait_time", @(_eventBase.mdl_player_wait_time));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"player_wait_num", @(_eventBase.mdl_player_wait_num));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_speed", @(_eventBase.mdl_speed));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_file_key", _eventBase.mdl_file_key);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_is_socrf", @(_eventBase.mdl_is_socrf));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_req_num", @(_eventBase.mdl_req_num));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_url_index", @(_eventBase.mdl_url_index));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_re_url", _eventBase.mdl_re_url);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_cur_source", @(_eventBase.mdl_cur_soure));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_extra_info", _eventBase.mdl_extra_info);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_ec", @(_eventBase.mdl_error_code));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_fs", @(_eventBase.mdl_fs));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_stage", @(_eventBase.mdl_stage));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"req_t", @(_eventBase.mdl_req_t));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"end_t", @(_eventBase.mdl_end_t));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_dns_t", @(_eventBase.mdl_dns_t));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"tcp_con_start_t", @(_eventBase.mdl_tcp_start_t));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"tcp_con_t", @(_eventBase.mdl_tcp_end_t));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"tcp_first_pack_t", @(_eventBase.mdl_ttfp));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"http_first_body_t", @(_eventBase.mdl_httpfb));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"http_open_end_t", @(_eventBase.mdl_http_open_end_t));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"http_code", @(_eventBase.mdl_http_code));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_p2p_sp", @(_eventBase.mdl_pcdn_full_speed));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_res_err", @(_eventBase.mdl_res_err));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_read_src", @(_eventBase.mdl_read_src));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_seek_num", @(_eventBase.mdl_seek_num));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_last_msg", _eventBase.mdl_last_msg);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_server_timing", _eventBase.mdl_server_timing);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_v_lt", @(_eventBase.mdl_v_lt));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_v_p2p_ier", @(_eventBase.mdl_v_p2p_ier));
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_ip_list", _eventBase.mdl_ip_list);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_blocked_ips", _eventBase.mdl_blocked_ips);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_response_cinfo", _eventBase.mdl_response_cinfo);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_response_cache", _eventBase.mdl_response_cache);
            TTVideoEngineLoggerPutToDictionary(jsonDict, @"dns_type", _eventBase.mdl_dns_type);
        }
    }
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"log_type", @"video_playq");
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"pt", @(_pt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"at", @(_at));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vt", @(_vt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"et", @(_et));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"lt", @(_lt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bc", @(_bc));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"br", @(_br));
    if(![_eventBase.source_type isEqualToString:@"dir_url"]){
        TTVideoEngineLoggerPutToDictionary(jsonDict, @"vu", _vu);
    }
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vd", @(_vd));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vs", @(_vs));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vps", @(_vps));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vds", @(_vds));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"accumulate_vds", @(_accu_vds));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_preload_size", @(_video_preload_size));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"errt", @(_errt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"errc", @(_errc));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"df", _df);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"lf", _lf);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"fir_errt", @(_first_errt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"fir_errc", @(_first_errc));
    NSInteger hijack = _hijack ? 1 : 0;
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"hijack", @(hijack));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"ex", _ex);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vsc", @(_vsc));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"initial_url", _initialURL);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"custom_str", _customStr);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"codec", _codec);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_codec", _acodec);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"lc", @(_lc));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"dns_t", @(_dns_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"tran_ct", @(_tran_ct));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"tran_ft", @(_tran_ft));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"re_f_videoframet", @(_re_f_videoframet));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"re_f_audioframet", @(_re_f_audioframet));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"de_f_videoframet", @(_de_f_videoframet));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"de_f_audioframet", @(_de_f_audioframet));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_device_start_t", @(_video_open_time));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_device_opened_t", @(_video_opened_time));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_device_start_t", @(_audio_open_time));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_device_opened_t", @(_audio_opened_time));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bu_acu_t", @(_bu_acu_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"tag", _tag);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"subtag", _subtag);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"first_buf_startt", @(_first_buf_startt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"first_buf_endt", @(_first_buf_endt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vtype", _vtype);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"initial_host", _initial_host);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"initial_ip", _initial_ip);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"internal_ip", _internal_ip);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"initial_resolution", _initial_resolution);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"initial_quality", _initial_quality);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"prepare_before_play_t", @(_prepare_before_play_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"prepare_start_time", @(_prepare_start_time));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"prepare_end_time", @(_prepare_end_time));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"render_type", _render_type);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_model_version", @(_video_model_version));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"vpls", @(_vpls));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"finish", @(_finish));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"cur_play_pos", @(_cur_play_pos));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"sat", @(_seek_acu_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"playparam", _playparam);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"av_sync_start", @(_av_sync_start_enable));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_out_fps", @(_video_out_fps));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"container_fps", @(_container_fps));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_decoder_fps", @(_video_decoder_fps));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_drop_cnt", @(_audio_drop_cnt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"watch_dur", @(_watch_dur));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"switch_resolution_c", @(_switch_resolution_c));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"width", @(_width));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"height", @(_height));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"disable_accurate_start", @(_disable_accurate_start));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"sc", @(_sc));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"api_str", _api_string);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"net_client", _net_client);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"engine_state", @(_engine_state));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bit_rate", @(_bitrate));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_bitrate", @(_audioBitrate));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"buffer_timeout", @(_bufferTimeOut));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enable_bash", @(_enable_bash));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"dynamic_type", _dynamic_type);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"mem_use", @(_mem_use));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"cpu_use", @(_cpu_use));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"trace_id", _traceID);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"lv_method", @(_leave_method));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"lsst", @(_last_seek_start_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"lset", @(_last_seek_end_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"lbst", @(_last_buffer_start_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"lbet", @(_last_buffer_end_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"lsp", @(_last_seek_positon));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enable_boe", @(_enable_boe));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"dns_server_ip", _dns_server_ip);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"apiver", @(_apiver));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"auth", _auth);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"start_time", @(_start_time));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enable_mdl", @(_enable_mdl));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdl_version", _mdl_version);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enable_nnsr", @(_enable_nnsr));
    if (1 == _enable_nnsr) {
        [jsonDict setObject:@(2) forKey:@"sr_w"];
        [jsonDict setObject:@(2) forKey:@"sr_h"];
    }

    static const NSInteger kMaxLoadBufferRecordCount = 50;
    NSArray* temArray = self.per_buffer_duration.copy;
    if (self.per_buffer_duration.count > kMaxLoadBufferRecordCount) {
        temArray = [self.per_buffer_duration subarrayWithRange:NSMakeRange(0, kMaxLoadBufferRecordCount)];
    }
    NSMutableArray* temDict = [NSMutableArray array];
    [temArray enumerateObjectsUsingBlock:^(NSNumber*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx % 2 == 1) {
            [temDict addObject:@{@"start_time":[self.per_buffer_duration ttvideoengine_objectAtIndex:(idx-1)],
                                 @"end_time":obj
                                 }];
        }
    }];
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"per_buffer_duration", temDict);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"check_hijack", @(_check_hijack));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"first_hijack_code", @(_first_hijack_code));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"last_hijack_code", @(_last_hijack_code));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"dns_mod", @(_dnsMode));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"pbt", @(_pbt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"setds_t", @(_setds_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"pt_new", @(_pt_new));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"ps_t", @(_ps_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"dns_start_t", @(_dns_start_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"dns_end_t", @(_dns_end_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_dns_start_t", @(_a_dns_start_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_dns_t", @(_a_dns_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"formater_create_t", @(_formater_create_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"avformat_open_t", @(_avformat_open_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"demuxer_begin_t", @(_demuxer_begin_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"demuxer_create_t", @(_demuxer_create_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"dec_create_t", @(_dec_create_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"outlet_create_t", @(_outlet_create_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_render_f_t", @(_v_render_f_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_render_f_t", @(_a_render_f_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_dec_start_t", @(_v_dec_start_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_dec_start_t", @(_a_dec_start_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_dec_opened_t", @(_v_dec_opened_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_dec_opened_t", @(_a_dec_opened_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_tran_ft", @(_a_tran_ft));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_tran_ct", @(_a_tran_ct));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_http_open_t", @(_v_http_open_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_http_open_t", @(_a_http_open_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_tran_open_t", @(_v_tran_open_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_tran_open_t", @(_a_tran_open_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_sock_create_t", @(_v_sock_create_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_sock_create_t", @(_a_sock_create_t));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_disabled", @(_video_stream_disabled));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_disabled", @(_audio_stream_disabled));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"is_replay", @(_isReplay));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"av_gap", @(_av_gap));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"moov_pos", @(_moov_pos));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdat_pos", @(_mdat_pos));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"feed_in_before_decoded", @(_feed_in_before_decoded));
    if (_start_time == 0 && _vt > 0 && _feed_in_before_decoded > 0) {
        if (_vtype && [_vtype isKindOfClass:[NSString class]] && [_vtype isEqualToString:@"dash"]) {
            [jsonDict setObject:@(_min_audio_frame_size) forKey:@"min_audio_frame_size"];
            [jsonDict setObject:@(_min_video_frame_size) forKey:@"min_video_frame_size"];
        } else { //mp4
            int64_t maxValue = MAX(_min_audio_frame_size, _min_video_frame_size);
            [jsonDict setObject:@(maxValue) forKey:@"min_video_frame_size"];
        }
        if (_mPreloadGear && [_mPreloadGear isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:_mPreloadGear];
            if (_vtype && [_vtype isKindOfClass:[NSString class]] && [_vtype isEqualToString:@"dash"]) {
                [dic setValue:@(_min_audio_frame_size) forKey:@"agt0"];
                [dic setValue:@(_min_video_frame_size) forKey:@"vgt0"];
            } else {
                int64_t maxValue = MAX(_min_audio_frame_size, _min_video_frame_size);
                [dic setValue:@(maxValue) forKey:@"vgt0"];
            }
            [jsonDict setObject:dic forKey:@"pgd"];
        }
    }
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_file_hash", _mVideoFileHash);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_file_hash", _mAudioFileHash);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"play_log_id", _log_id);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_codec_profile", @(_video_codec_profile));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_codec_profile", @(_audio_codec_profile));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"features", _mFeatures);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"st_net_speed", @(_st_speed));
    
    //subtitle
    NSMutableDictionary *sub_dict = [NSMutableDictionary dictionary];
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"sub_load_fin_ts", @(_sub_load_finished_time));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"sub_req_fin_ts", @(_sub_request_finished_time));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"sub_langs_c", @(_sub_languages_count));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"sub_enable_opt_load", @(_sub_enable_opt_load));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"sub_switch_c", @(_sub_lang_switch_count));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"sub_error", _sub_error);
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"sub_thread_enable", @(_sub_thread_enable));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"sub_enable", @(_sub_enable));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"sub_req_url", _sub_req_url);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"sub_events", sub_dict);
    
    //mask
    NSMutableDictionary *mask_dict = [NSMutableDictionary dictionary];
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"mask_open_ts", @(_mask_open_time));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"mask_opened_ts", @(_mask_opened_time));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"mask_errc", @(_mask_error_code));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"mask_thread_enable", @(_mask_thread_enable));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"mask_enable", @(_mask_enable));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"mask_url", _mask_url);
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"mask_enable_mdl", @(_mask_enable_mdl));
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"mask_file_hash", _mask_file_hash);
    TTVideoEngineLoggerPutToDictionary(sub_dict, @"mask_file_size", @(_mask_file_size));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"mask_events", mask_dict);
    
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"av_outsync_count", @(_mAVOutsyncCount));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"av_outsync_list", [_avOutsyncList eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"no_a_list", [_no_a_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"no_v_list", [_no_v_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"rebuf_list", [_rebufList eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"seek_list", [_seek_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"resolution_list", [_resolution_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"pause_list", [_pause_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"play_list", [_play_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"error_list", [_error_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"playspeed_list", [_playspeed_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"radiomode_list", [_radiomode_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"loop_list", [_loop_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"view_size_list", [_view_size_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bright_list", [_bright_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"foreback_switch_list", [_foreback_switch_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"bad_interlaced_list", [_bad_interlaced_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"headset_list", [_headset_switch_list eventModels]);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"drop_count", @(_mDropCount));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_pixel_bit", @(_video_pixel_bit));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"color_trc", @(_color_trc));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"color_space", @(_color_space));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"color_primaries", @(_color_primaries));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"mute", @(_isMute));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"core_volume", @(_core_volume));
    _volume = (NSInteger)([[TTVideoEngineEventUtil sharedInstance] currentVolume] * 100);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"volume", @(_volume));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"before_play_buffer_start_t", @(_before_play_buf_startt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"before_play_buffer_end_t", @(_before_play_buf_endt));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enc_key", _encrypt_key);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_length", @(_video_buffer_len));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"audio_length", @(_audio_buffer_len));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_decbuf_len", @(_v_decbuf_len));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_decbuf_len", @(_a_decbuf_len));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"v_basebuf_len", @(_v_basebuf_len));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"a_basebuf_len", @(_a_basebuf_len));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"screen_w", @([[TTVideoEngineEventUtil sharedInstance] screenWidth]));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"screen_h", @([[TTVideoEngineEventUtil sharedInstance] screenHeight]));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"view_scale", @([[TTVideoEngineEventUtil sharedInstance] screenScale]));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"is_reuse_engine", @(_mIsEngineReuse?1:0));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"view_hidden", @(_playerview_hidden));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"net_conn_cnt", @(_network_connect_count));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enable_global_mute_feature", @(_mEnableGlobalMuteFeature));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"global_mute_dic", _mGlobalMuteDic);
    NSDictionary *stDict = [TTVideoEngineStrategy.helper getLogData:_eventBase.vid];
    if (stDict && stDict.count > 0) {
        [jsonDict addEntriesFromDictionary:stDict];
    }
    NSDictionary *stDictTrace = [TTVideoEngineStrategy.helper getLogDataByTraceId:_traceID];
    if (stDictTrace && stDictTrace.count > 0) {
        [jsonDict addEntriesFromDictionary:stDictTrace];
    }

    TTVideoEngineLoggerPutToDictionary(jsonDict, @"video_style", @(_video_style));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"dimension", @(_dimension));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"projection_model", @(_projection_model));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"view_size", @(_view_size));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"mdlretry", _mMDLRetryInfo);

    if (_crosstalk_count >= 2) {
        [jsonDict setObject:@(_crosstalk_count) forKey:@"crosstalk_count"];
        NSArray *crosstalk_info_list = [_crosstalk_info_list copy];
        if (crosstalk_info_list.count > 0) {
            [jsonDict setObject:crosstalk_info_list forKey:@"crosstalk_info_list"];
        }
    }
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enginepool_is_from_enginepool", _mFromEnginePool);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"engine_hashcode", @(_mEngineHash));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enginepool_corepoolsize_upper_limit", @(_mCorePoolSizeUpperLimit));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enginepool_corepoolsize_before_getengine", @(_mCorepoolSizeBeforeGetEngine));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"enginepool_count_of_engine_in_use", @(_mCountOfEngineInUse));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"expire_play_code", @(_mExpirePlayCode));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"header_info", _mPlayerHeaderInfo);
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"mask_download_size", @(_mMaskDownloadSize));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"subtitle_download_size", @(_mSubtitleDownloadSize));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"net_block_buffer_threshold", @(_netblockBufferthreshold));
    TTVideoEngineLoggerPutToDictionary(jsonDict, @"company_id", _mCustomCompanyId);
    
    /// vod strategy log end
    TTVideoEngineLog(@"setds_t:%lld,pt_new:%lld,ps_T:%lld,dns_start_t:%lld,dns_end_t:%lld,a_dns_start:%lld,a_dns_t:%lld,formater_create_t:%lld,avformat_open_t:%lld,demuxer_begin_t:%lld,demuxer_create_t:%lld,dec_create_t:%lld,outlet_create_t:%lld,v_render_f_t:%lld,a_render_f_t:%lld,v_dec_start_t:%lld,a_dec_start_t:%lld,v_dec_opened_t:%lld,a_dec_opened_t:%lld,a_tran_ct:%lld,a_tran_ft:%lld,v_disabled:%d,a_disabled:%d,is_replay:%d",
                     _setds_t, _pt_new, _ps_t, _dns_start_t, _dns_end_t, _a_dns_start_t, _a_dns_t, _formater_create_t, _avformat_open_t, _demuxer_begin_t, _demuxer_create_t, _dec_create_t, _outlet_create_t, _v_render_f_t, _a_render_f_t, _v_dec_start_t, _a_dec_start_t, _v_dec_opened_t, _a_dec_opened_t, _a_tran_ct, _a_tran_ft, _video_stream_disabled, _audio_stream_disabled, _isReplay);
    return jsonDict;
}

@end
