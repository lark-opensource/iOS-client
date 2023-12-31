//
//  TTVideoEngineEvent.h
//  Pods
//
//  Created by guikunzhi on 16/12/23.
//
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineEventBase.h"
#import "TTVideoEngineEventListModel.h"

enum {
    ONEPLAY_EXIT_CODE_BEFORE_LOADING_NOT_FETCH = -1002,//正片起播前，loading过程中未fetch成功时
    ONEPLAY_EXIT_CODE_BEFORE_LOADING_FETCHED = -1003,//正片起播前，player未创建
    ONEPLAY_EXIT_CODE_BEFORE_DNS_NOT_PARSED = -1004,//正片起播前，dns解析未成功时
    ONEPLAY_EXIT_CODE_BEFORE_DNS_PARSED = -1005,//正片起播前，dns解析成功后未起播时
    ONEPLAY_EXIT_CODE_BEFORE_FORMATER_CREATING = -1006,//正片起播前，formater未创建
    ONEPLAY_EXIT_CODE_BEFORE_DEMUXER_CREATING = -1007,  //正片起播前，demuxer未创建
    ONEPLAY_EXIT_CODE_BEFORE_TCP_CONNECTING = -1008,  //正片起播前，tcp未建联
    ONEPLAY_EXIT_CODE_BEFORE_TCP_FIRST_PACKET = -1009,  //正片起播前，tcp未拿到首包
    ONEPLAY_EXIT_CODE_BEFORE_AVFORMAT_OPENING = -1010,  //正片起播前，avformat_open中
    ONEPLAY_EXIT_CODE_BEFORE_AVFORMAT_FIND_STREAM = -1011,  //正片起播前，avformat_find_stream中
    ONEPLAY_EXIT_CODE_BEFORE_DEC_CREATING = -1012,  //正片起播前，decoder模块未创建
    ONEPLAY_EXIT_CODE_BEFORE_OUTLET_CREATING = -1013,  //正片起播前，outlet模块未创建
    ONEPLAY_EXIT_CODE_BEFORE_VIDEO_DECODER_OPENING = -1014,  //正片起播前，视频解码设备未创建
    ONEPLAY_EXIT_CODE_BEFORE_AUDIO_DECODER_OPENING = -1015,  //正片起播前，音频解码设备未创建
    ONEPLAY_EXIT_CODE_BEFORE_VIDEO_DEVICE_OPENING = -1016,  //正片起播前，视频渲染设备未创建
    ONEPLAY_EXIT_CODE_BEFORE_AUDIO_DEVICE_OPENING = -1017,  //正片起播前，音频渲染设备未创建
    ONEPLAY_EXIT_CODE_BEFORE_VIDEO_FIRST_PACKET = -1018,  //正片起播前，视频首包未拿到
    ONEPLAY_EXIT_CODE_BEFORE_AUDIO_FIRST_PACKET = -1019,  //正片起播前，音频首包未拿到
    ONEPLAY_EXIT_CODE_BEFORE_VIDEO_DECODE_FIRST_FRAME = -1020,  //正片起播前，视频首帧未解码
    ONEPLAY_EXIT_CODE_BEFORE_AUDIO_DECODE_FIRST_FRAME = -1021,  //正片起播前，音频首帧未解码
    ONEPLAY_EXIT_CODE_BEFORE_VIDEO_RENDER_FIRST_FRAME = -1022,  //正片起播前，视频首帧未渲染
    ONEPLAY_EXIT_CODE_BEFORE_AUDIO_RENDER_FIRST_FRAME = -1023,  //正片起播前，音频首帧未渲染
    ONEPLAY_EXIT_CODE_BEFORE_FIRST_FRAME_MSG_NOT_REPORT = -1024,  //正片起播前，首帧消息被阻塞

    ONEPLAY_EXIT_CODE_AFTER_PLAYING = -2001,//正片起播后，播放过程中退出
    ONEPLAY_EXIT_CODE_AFTER_LOADING_SEEK = -2002,//正片起播后，seek过程中退出
    ONEPLAY_EXIT_CODE_AFTER_LOADING_NET = -2003,//正片起播后，网络造成的loading时退出
    ONEPLAY_EXIT_CODE_AFTER_DECODE = -2004,//正片起播后，解码造成的卡顿时退出
    ONEPLAY_EXIT_CODE_AFTER_SWITCH = -2005,//正片起播后，切清晰度过程中退出
};

@interface TTVideoEngineEvent : NSObject

@property (nonatomic, strong) TTVideoEngineEventBase* eventBase;

@property (nonatomic, copy) NSString *logType;
@property (nonatomic, assign) long long pt;  //用户点击播放的时间戳，单位为毫秒
@property (nonatomic, assign) long long at;  //获取视频列表结束的时间戳，单位是毫秒
@property (nonatomic, assign) long long dns_t; //播放器DNS结束的时间戳，单位是毫秒
@property (nonatomic, assign) long long tran_ct; //TCP连接成功的时间戳，单位是毫秒
@property (nonatomic, assign) long long tran_ft; //TCP第一报时间戳，单位是毫秒
@property (nonatomic, assign) long long re_f_videoframet; //demuxer读到首帧未解码视频数据，单位是毫秒
@property (nonatomic, assign) long long re_f_audioframet; //demuxer读到首帧未解码音频数据，单位是毫秒
@property (nonatomic, assign) long long de_f_videoframet; //decoder解码出第一帧视频帧，单位是毫秒
@property (nonatomic, assign) long long de_f_audioframet; //decoder解码出第一帧音频帧，单位是毫秒
@property (nonatomic, assign) long long video_open_time;
@property (nonatomic, assign) long long video_opened_time;
@property (nonatomic, assign) long long audio_open_time;
@property (nonatomic, assign) long long audio_opened_time;
@property (nonatomic, assign) int64_t first_frame_rendered_time;
@property (nonatomic, assign) NSInteger av_sync_start_enable;
@property (nonatomic, assign) long long bu_acu_t; //卡顿累计时长
@property (nonatomic, assign) long long vt;  //第一帧画面的时间戳，单位是毫秒
@property (nonatomic, assign) long long et;  //用户本次点播视频播放结束的时间戳，单位是毫秒
@property (nonatomic, assign) long long lt;  //用户没有播放视频就离开的时间，单位是毫秒
@property (nonatomic, assign) long long bft; //用户本次点播视频流加载结束的时间戳，单位是毫秒
@property (nonatomic, assign) NSInteger bc; //网络引起卡顿的次数
@property (nonatomic, assign) NSInteger br; //用户是否发生播放中断
@property (nonatomic, copy) NSArray *vu; //播放url
@property (nonatomic, assign) NSInteger vd; //视频总片长
@property (nonatomic, assign) int64_t vs; //视频总大小
@property (nonatomic, copy) NSString *codec;    //视频编码类型
@property (nonatomic, copy) NSString *acodec;    //音频编码类型
@property (nonatomic, assign) int64_t vps;    //视频播放的字节数
@property (nonatomic, assign) int64_t vds;    //视频加载的字节数
@property (nonatomic, assign) int64_t accu_vds; //视频加载的字节数，循环播放累加
@property (nonatomic, assign) int64_t video_preload_size; //视频预加载大小(播放前)
@property (nonatomic, copy) NSString *df;   //视频清晰度(360p, 480p, 720p)
@property (nonatomic, copy) NSString *lf;   //切换前的清晰度
@property (nonatomic, assign) NSInteger errt;   //播放器返回的错误类型
@property (nonatomic, assign) NSInteger errc;   //播放器返回的错误码
@property (nonatomic, strong) NSDictionary *merror;  //main error
@property (nonatomic, assign) NSInteger first_errt;   //播放器首次错误发生事件
@property (nonatomic, assign) NSInteger first_errc; //播放器首次错误码
@property (nonatomic, assign) NSInteger first_errc_internal;    //播放器首次错误内核错误码
@property (nonatomic, assign) BOOL hijack;      // 是否被劫持
@property (nonatomic, strong) NSDictionary *ex;  //附加信息
@property (nonatomic, assign) NSInteger vsc;    //视频状态码
@property (nonatomic, copy) NSString *initialURL;
@property (nonatomic, copy) NSString *customStr;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *subtag;
@property (nonatomic, assign) NSInteger lc; // loopCount 循环播放次数
@property (nonatomic, assign) long long first_buf_startt; //起播后首次卡顿开始
@property (nonatomic, assign) long long first_buf_endt; //起播后首次卡顿结束
@property (nonatomic, assign) long long before_play_buf_startt; //buffer_directly模式下起播前卡顿开始时间戳
@property (nonatomic, assign) long long before_play_buf_endt; //buffer_directly模式下起播后卡顿开始时间戳
@property (nonatomic, copy) NSString *vtype; //video type
@property (nonatomic, assign) NSInteger width; //视频宽
@property (nonatomic, assign) NSInteger height; //视频高
@property (nonatomic, copy) NSString *initial_host;///< 初始播放host
@property (nonatomic, copy) NSString *initial_ip;///< 初始播放使用的ip
@property (nonatomic, copy) NSString *internal_ip;///< 最后播放用到的ip
@property (nonatomic, copy) NSString *initial_resolution;///< 初始播放使用的分辨率
@property (nonatomic, copy) NSString *initial_quality;///< 初始播放使用的质量
@property (nonatomic, assign) long long prepare_before_play_t;///< play之前调用prepareToPlay的时间戳，单位毫秒
@property (nonatomic, assign) long long prepare_start_time;///< prepare开始的时间戳，单位是毫秒
@property (nonatomic, assign) long long prepare_end_time;///< prepared的时间戳，单位是毫秒
@property (nonatomic, copy) NSString* render_type;///< 渲染类型
@property (nonatomic, assign) NSInteger video_model_version;///<是否使用新版videomodel
@property (nonatomic, assign) long long vpls; ///< video_preload_size, 视频预加载大小(播放前)
@property (nonatomic, assign) NSInteger finish;///< 播放是否完成
@property (nonatomic, assign) long cur_play_pos;///< 当前视频的播放进度：ms
@property (nonatomic, assign) NSInteger seek_acu_t;///< seek累积时长
@property (nonatomic, strong) NSMutableArray* per_buffer_duration;///< 每次缓冲的时间段(取绝对时间)
@property (nonatomic, strong) NSMutableDictionary* playparam;///< 业务方设置的播放参数
@property (nonatomic, assign) CGFloat video_out_fps;///< 渲染帧率
@property (nonatomic, assign) NSInteger audio_drop_cnt;///<audio_outlet丢帧数量统计
@property (nonatomic, assign) NSInteger video_decoder_fps;
@property (nonatomic, assign) NSInteger watch_dur;///<本次观看时长统计：ms ,-1无效
@property (nonatomic, assign) NSInteger switch_resolution_c; ///<分辨率切换的次数
@property (nonatomic, assign) NSInteger disable_accurate_start;
@property (nonatomic, assign) NSInteger sc;///< seek 次数，默认为 0
@property (nonatomic, copy) NSString *api_string;//play接口请求url
@property (nonatomic, copy) NSString *net_client;//网络库类型，own/user
@property (nonatomic, assign) NSInteger engine_state;//上报日志时engine状态
@property (nonatomic, assign) NSInteger apiver;//play接口version
@property (nonatomic, copy) NSString *auth;//play接口auth
@property (nonatomic, assign) NSInteger start_time;//用户设置的起播时间
@property (nonatomic, assign) NSInteger bitrate;///< videoModel中的码率，或内核计算的视频bitrate，bps
@property (nonatomic, assign) NSInteger audioBitrate;///内核中取出的音频bitrate, bps
@property (nonatomic, assign) NSInteger bufferTimeOut;
@property (nonatomic, assign) NSInteger enable_bash;///< 是否开启bash
@property (nonatomic, copy) NSString *dynamic_type;///< dash类型，如segment_base
@property (nonatomic, copy) NSString *traceID;/// trace-id
@property (nonatomic, assign) long long last_seek_start_t; //最后一次seek开始时间，单位是毫秒
@property (nonatomic, assign) long long last_seek_end_t; //最后一次seek结束时间，单位是毫秒
@property (nonatomic, assign) long long last_buffer_start_t; //最后一次卡顿开始时间，单位是毫秒
@property (nonatomic, assign) long long last_buffer_end_t; //最后一次卡顿结束时间，单位是毫秒
@property (nonatomic, assign) long long last_resolution_start_t; //最后一次切换分辨率开始时间，单位是毫秒
@property (nonatomic, assign) long long last_resolution_end_t; //最后一次切换分辨率结束时间，单位是毫秒
@property (nonatomic, assign) NSInteger last_seek_positon;//最后一次seek的位置
@property (nonatomic, assign) NSInteger enable_boe;///< 是否开启boe
@property (nonatomic, copy) NSString *dns_server_ip;//dns服务器ip
@property (nonatomic, assign) CGFloat mem_use;//视频播放过程中 app 内存占用 m
@property (nonatomic, assign) CGFloat cpu_use;//视频播放过程中，cpu 平均占用 %
@property (nonatomic, assign) NSInteger leave_method; //离开时调用的方法
@property (nonatomic, assign) NSInteger check_hijack;
@property (nonatomic, assign) NSInteger first_hijack_code;
@property (nonatomic, assign) NSInteger last_hijack_code;

@property (nonatomic, assign) NSInteger leave_reason;
@property (nonatomic, assign) NSInteger leave_block_t;

@property (nonatomic, assign) NSInteger dnsMode; //dns类型，0表示点播dns，1表示内核dns
@property (nonatomic, assign) NSInteger enable_mdl;/// 播放时是否使用 mdl
@property (nonatomic, copy) NSString* mdl_version;
@property (nonatomic, copy) NSString* mdl_loader_type;
@property (nonatomic, assign) int64_t pbt;//记录起播buffering结束的时间
@property (nonatomic, assign) int enable_nnsr;
//@property (nonatomic, assign) NSInteger render_error_msg;///< 渲染相关错误信息，直接CheckError之后返回,0表示正常
//@property (nonatomic, assign) NSInteger action_before_finish;///< 结束之前执行的操作 ,为了便于统计什么操作影响了结束，操作记录是互斥的，只保留最后一个操作。
//@property (nonatomic, assign) NSInteger action_before_buffer;///< 缓冲之前相关操作，为了便于统计什么造成缓冲，操作记录是互斥的，只保留最后一个操作。
//@property (nonatomic, strong) NSDictionary *player_parameters;///< 结束播放时上传播放器相关参数
//@property (nonatomic, assign) NSInteger video_out_fps;///< 当前渲染帧率

@property (nonatomic, assign) int64_t setds_t;  //set datasource时间，ms
@property (nonatomic, assign) int64_t pt_new;  //首次调用play时间，不可覆盖，ms
@property (nonatomic, assign) int64_t ps_t;   //prepare或play事件，不可覆盖，ms
@property (nonatomic, assign) int64_t a_dns_start_t;  //dash音视频分离时，音频流dns开始时间，ms
@property (nonatomic, assign) int64_t a_dns_t;  //dash音视频分离时，音频流dns结束时间，ms
@property (nonatomic, assign) int64_t dns_start_t;  //开始dns的时间，ms
@property (nonatomic, assign) int64_t dns_end_t;  //dns完成时间，ms
@property (nonatomic, assign) int64_t formater_create_t;
@property (nonatomic, assign) int64_t avformat_open_t;
@property (nonatomic, assign) int64_t demuxer_create_t;
@property (nonatomic, assign) int64_t demuxer_begin_t;
@property (nonatomic, assign) int64_t dec_create_t;
@property (nonatomic, assign) int64_t outlet_create_t;
@property (nonatomic, assign) int64_t v_render_f_t;
@property (nonatomic, assign) int64_t a_render_f_t;
@property (nonatomic, assign) int64_t a_dec_start_t;
@property (nonatomic, assign) int64_t v_dec_start_t;
@property (nonatomic, assign) int64_t a_dec_opened_t;
@property (nonatomic, assign) int64_t v_dec_opened_t;
@property (nonatomic, assign) int64_t a_tran_ct;
@property (nonatomic, assign) int64_t a_tran_ft;
@property (nonatomic, assign) int64_t v_http_open_t;
@property (nonatomic, assign) int64_t a_http_open_t;
@property (nonatomic, assign) int64_t v_tran_open_t;
@property (nonatomic, assign) int64_t a_tran_open_t;
@property (nonatomic, assign) int64_t v_sock_create_t;
@property (nonatomic, assign) int64_t a_sock_create_t;

@property (nonatomic, assign) int video_stream_disabled;
@property (nonatomic, assign) int audio_stream_disabled;
@property (nonatomic, assign) int isReplay;
@property (nonatomic, assign) int64_t av_gap;
@property (nonatomic, assign) int64_t moov_pos;
@property (nonatomic, assign) int64_t mdat_pos;
@property (nonatomic, assign) int64_t min_audio_frame_size;
@property (nonatomic, assign) int64_t min_video_frame_size;
@property (nonatomic, assign) int feed_in_before_decoded;


@property (nonatomic, assign) int container_fps;

@property (nonatomic, copy) NSString* log_id;
@property (nonatomic, assign) int video_codec_profile;
@property (nonatomic, assign) int audio_codec_profile;

@property (nonatomic, strong) NSMutableDictionary* mFeatures;
@property (nonatomic, assign) NSInteger video_pixel_bit;  //视频数据位数8/10bit
@property (nonatomic, assign) NSInteger color_trc;  //颜色转换特征，16/18为HDR，参考AVCOL_TRC_XXX
@property (nonatomic, assign) NSInteger color_space;
@property (nonatomic, assign) NSInteger color_primaries;
@property (nonatomic, assign) NSInteger core_volume;
@property (nonatomic, assign) NSInteger volume;
@property (nonatomic, assign) NSInteger isMute;

//subtitle
@property (nonatomic, assign) int64_t sub_load_finished_time;
@property (nonatomic, assign) int64_t sub_request_finished_time;
@property (nonatomic, assign) int sub_languages_count;
@property (nonatomic, assign) int sub_enable_opt_load;
@property (nonatomic, assign) int sub_lang_switch_count;
@property (nonatomic, copy) NSDictionary *sub_error;
@property (nonatomic, copy) NSString *sub_req_url;
@property (nonatomic, assign) int sub_enable;
@property (nonatomic, assign) int sub_thread_enable;

//mask
@property (nonatomic, assign) int64_t mask_open_time;
@property (nonatomic, assign) int64_t mask_opened_time;
@property (nonatomic, assign) int mask_error_code;
@property (nonatomic, assign) int mask_thread_enable;
@property (nonatomic, assign) int mask_enable;
@property (nonatomic, copy) NSString *mask_url;
@property (nonatomic, copy, nullable) NSString *mask_file_hash;
@property (nonatomic, assign) NSInteger mask_enable_mdl;
@property (nonatomic, assign) int64_t mask_file_size;

@property (nonatomic, assign) NSInteger mAVOutsyncCount;
@property (nonatomic, strong) TTVideoEngineEventListModel *avOutsyncList;
@property (nonatomic, strong) TTVideoEngineEventListModel *no_a_list;
@property (nonatomic, strong) TTVideoEngineEventListModel *no_v_list;
@property (nonatomic, assign) NSInteger mDropCount;

@property (nonatomic, strong) TTVideoEngineEventListModel *rebufList;

@property (nonatomic, strong) TTVideoEngineEventListModel *seek_list;

@property (nonatomic, strong) TTVideoEngineEventListModel *resolution_list;

@property (nonatomic, strong) TTVideoEngineEventListModel *pause_list;

@property (nonatomic, strong) TTVideoEngineEventListModel *play_list;

@property (nonatomic, strong) TTVideoEngineEventListModel *error_list;

@property (nonatomic, strong) TTVideoEngineEventListModel *playspeed_list;

@property (nonatomic, strong) TTVideoEngineEventListModel *radiomode_list;

@property (nonatomic, strong) TTVideoEngineEventListModel *loop_list;
@property (nonatomic, strong) TTVideoEngineEventListModel *foreback_switch_list;
@property (nonatomic, strong) TTVideoEngineEventListModel *headset_switch_list;
@property (nonatomic, strong) TTVideoEngineEventListModel *bright_list;
@property (nonatomic, strong) TTVideoEngineEventListModel *view_size_list;
@property (nonatomic, strong) TTVideoEngineEventListModel *bad_interlaced_list;
@property (nonatomic, assign) CGRect cur_view_bounds;
@property (nonatomic, assign) float cur_brightness;

@property (nonatomic, copy) NSString *encrypt_key;
@property (nonatomic, assign) int64_t video_buffer_len;
@property (nonatomic, assign) int64_t audio_buffer_len;
@property (nonatomic, assign) int64_t v_decbuf_len;
@property (nonatomic, assign) int64_t a_decbuf_len;
@property (nonatomic, assign) int64_t v_basebuf_len;
@property (nonatomic, assign) int64_t a_basebuf_len;
@property (nonatomic, assign) BOOL mIsEngineReuse;
@property (nonatomic, assign) NSInteger playerview_hidden;
@property (nonatomic, assign) NSInteger network_connect_count;
@property (nonatomic, assign) BOOL mEnableGlobalMuteFeature;
@property (nonatomic, strong) NSDictionary *mGlobalMuteDic;
@property (nonatomic, assign) NSInteger video_style;  //视频类型 0：普通视频 1：VR视频
@property (nonatomic, assign) NSInteger dimension;  //维度 0：2D 1：3D上下 2：3D左右
@property (nonatomic, assign) NSInteger projection_model;  //投影模式 0：普通视频 1：等距柱状 2：cube map
@property (nonatomic, assign) NSInteger view_size;  //视野范围 [0, 180, 360]

@property (nonatomic, strong) NSArray *mMDLRetryInfo;
@property (nonatomic, assign) NSInteger crosstalk_count;
@property (nonatomic, strong) NSMutableArray *crosstalk_info_list;
@property (nonatomic, copy) NSString *mFromEnginePool;
@property (nonatomic, assign) NSInteger mEngineHash;
@property (nonatomic, assign) NSInteger mCorePoolSizeUpperLimit;
@property (nonatomic, assign) NSInteger mCorepoolSizeBeforeGetEngine;
@property (nonatomic, assign) NSInteger mCountOfEngineInUse;
@property (nonatomic, assign) float st_speed;
@property (nonatomic, assign) NSInteger mExpirePlayCode;
@property (nonatomic, copy) NSString* _Nullable mPlayerHeaderInfo;
@property (nonatomic, assign) int64_t mMaskDownloadSize;
@property (nonatomic, assign) int64_t mSubtitleDownloadSize;
@property (nonatomic, strong) NSDictionary* mPreloadGear;
@property (nonatomic, copy) NSString* mVideoFileHash;
@property (nonatomic, copy) NSString* mAudioFileHash;
@property (nonatomic, assign) NSInteger netblockBufferthreshold;
@property (nullable, nonatomic, copy) NSString* mCustomCompanyId;

- (instancetype)initWithEventBase:(TTVideoEngineEventBase*)base;

- (NSDictionary *)jsonDict;

@end
