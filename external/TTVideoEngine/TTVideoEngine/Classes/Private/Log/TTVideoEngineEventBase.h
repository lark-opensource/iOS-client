//
//  TTVideoEngineEventBase.h
//  Pods
//
//  Created by chibaowang on 2019/10/20.
//

#ifndef TTVideoEngineEventBase_h
#define TTVideoEngineEventBase_h

#import <Foundation/Foundation.h>

@protocol TTVideoEngineEventLoggerDelegate;

@interface TTVideoEngineMDLTrackInfo : NSObject

@property (nonatomic, assign) int mdl_mem_buffer_len;
@property (nonatomic, assign) int64_t mdl_disk_buffer_len;
@property (nonatomic, assign) int64_t mdl_send_offset;
@property (nonatomic, assign) int64_t mdl_last_req_offset;
@property (atomic, copy, nullable) NSString *mdl_last_ip_list;

- (void)update:(NSDictionary *_Nullable)dic;

@end

@interface TTVideoEngineEventBase : NSObject

@property (nonatomic, weak) id<TTVideoEngineEventLoggerDelegate> delegate;

@property (nonatomic, strong) NSMutableDictionary *videoInfo;
@property (nonatomic, copy) NSString* session_id;
@property (nonatomic, copy) NSString* device_id;
@property (nonatomic, copy) NSString *sv;   //统计接口的服务端版本号
@property (nonatomic, copy) NSString *pv;   //播放器版本号
@property (nonatomic, copy) NSString *pc;   //内核版本号
@property (nonatomic, copy) NSString *sdk_version;  //sdk版本号
@property (nonatomic, copy) NSString *vid;    //视频ID
@property (nonatomic, copy) NSString *source_type;//视频的播放类型
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *subtag;
@property (nonatomic, copy) NSString *lastResolution;
@property (nonatomic, copy) NSString *currentResolution;
@property (nonatomic, assign) NSInteger beginSwitchResolutionCurPos;
@property (nonatomic, assign) UInt64 beginSwitchResolutionTime;
@property (nonatomic, copy) NSString *initialQualityDesc;
@property (nonatomic, copy) NSString *currentQualityDesc;  //西瓜清晰度码
@property (nonatomic, copy) NSString *initial_ip;///< 初始播放使用的ip
@property (nonatomic, copy) NSString *initial_resolution;///< 初始播放使用的分辨率
@property (nonatomic, copy) NSString *curURL;//当前播放器使用的URL
@property (nonatomic, copy) NSString *initialURL;//初始播放使用的url
@property (nonatomic, copy) NSString *internal_ip;///< 最后播放用到的ip
@property (nonatomic, assign) NSInteger drm_type;
@property (nonatomic, copy) NSString *drm_token_url;
@property (nonatomic, assign) NSInteger play_type;///< 0表示点播，1表示直播回放
@property (nonatomic, assign) NSInteger audio_codec_nameId;//音频的解码器名称
@property (nonatomic, assign) NSInteger video_codec_nameId;//视频的解码器名称
@property (nonatomic, assign) NSInteger format_type;//视频封装格式
@property (nonatomic, assign) BOOL hw; //是否启用硬解
@property (nonatomic, assign) BOOL hw_user; //业务设置是否硬解
@property (nonatomic, assign) CGFloat playSpeed;
@property (nonatomic, assign) NSInteger reuse_socket;
@property (nonatomic, strong) NSDictionary *abr_info; // abr 相关埋点
@property (nonatomic, assign) BOOL isEnableABR;
@property (nonatomic, strong) NSString *vtype;
@property (nonatomic, assign) int64_t video_stream_duration;
@property (nonatomic, assign) int64_t audio_stream_duration;

@property (nonatomic, assign) UInt64 lastForebackSwitchTime;
@property (nonatomic, assign) UInt64 lastAVSwitchTime;
@property (nonatomic, assign) UInt64 lastResSwitchTime;
@property (nonatomic, assign) UInt64 lastHeadsetSwithTime;
@property (nonatomic, assign) NSInteger isInBackground;
@property (nonatomic, assign) NSInteger radioMode;
@property (nonatomic, assign) NSInteger curHeadset;
@property (nonatomic, assign) NSInteger blueTooth;
@property (nonatomic, copy) NSDictionary *r_stage_errcs;

//from MDL
@property (nonatomic, assign) BOOL hasAudioTrackInfo;
@property (nonatomic, assign) long long mdl_cur_req_pos;
@property (nonatomic, assign) long long mdl_cur_end_pos;
@property (nonatomic, assign) long long mdl_cur_cache_pos;
@property (nonatomic, assign) NSInteger mdl_cache_type;
@property (nonatomic, copy) NSString * mdl_cur_ip;
@property (nonatomic, copy) NSString * mdl_cur_host;
@property (nonatomic, copy) NSString * mdl_cur_url;
@property (nonatomic, assign) long long mdl_reply_size;
@property (nonatomic, assign) long long mdl_down_pos;
@property (nonatomic, assign) long long mdl_player_wait_time;
@property (nonatomic, assign) NSInteger mdl_player_wait_num;
@property (nonatomic, assign) NSInteger mdl_stage;
@property (nonatomic, assign) NSInteger mdl_error_code;
@property (nonatomic, assign) NSInteger mdl_cur_task_num;
@property (nonatomic, assign) int mdl_conc_count;
@property (nonatomic, assign) NSInteger mdl_speed;
@property (nonatomic, copy) NSString * mdl_file_key;
@property (nonatomic, assign) NSInteger mdl_is_socrf;
@property (nonatomic, assign) NSInteger mdl_req_num;
@property (nonatomic, assign) NSInteger mdl_url_index;
@property (nonatomic, copy) NSString * mdl_re_url;
@property (nonatomic, assign) NSInteger mdl_cur_soure;
@property (nonatomic, copy) NSString * mdl_extra_info;
@property (nonatomic, assign) NSInteger mdl_http_code;
@property (nonatomic, assign) long long mdl_req_t;
@property (nonatomic, assign) long long mdl_end_t;
@property (nonatomic, assign) long long mdl_dns_t;
@property (nonatomic, assign) long long mdl_tcp_start_t;
@property (nonatomic, assign) long long mdl_tcp_end_t;
@property (nonatomic, assign) long long mdl_ttfp;
@property (nonatomic, assign) long long mdl_httpfb;
@property (nonatomic, assign) long long mdl_http_open_end_t;
@property (nonatomic, assign) long long mdl_fs;
@property (nonatomic, assign) NSInteger mdl_pcdn_full_speed;
@property (nonatomic, assign) long long mdl_tbs;
@property (nonatomic, assign) long long mdl_lbs;
@property (nonatomic, assign) NSInteger mdl_res_err;
@property (nonatomic, assign) NSInteger mdl_read_src;
@property (nonatomic, assign) NSInteger mdl_seek_num;
@property (nonatomic, copy) NSString * mdl_last_msg;
@property (nonatomic, copy) NSString * mdl_server_timing;
@property (nonatomic, assign) NSInteger mdl_v_lt;     // video loader type
@property (nonatomic, assign) NSInteger mdl_v_p2p_ier; // video p2p ineffective reason
@property (nonatomic, copy) NSString * mdl_ip_list;
@property (nonatomic, copy) NSString * mdl_blocked_ips;
@property (nonatomic, copy) NSString * mdl_response_cinfo;
@property (nonatomic, copy) NSString * mdl_response_cache;
@property (nonatomic, copy) NSString * _Nullable mdl_dns_type;
@property (nonatomic, assign) NSInteger mdl_p2p_loader;
@property (atomic, nullable, copy) NSDictionary *mdl_features;
@property (nonatomic, strong) TTVideoEngineMDLTrackInfo * _Nullable mdlAudioInfo;
@property (nonatomic, strong) TTVideoEngineMDLTrackInfo * _Nullable mdlVideoInfo;


- (void)initPlay:(nullable NSString *)device_id traceId:(nullable NSString *)traceId;

- (void)beginToPlay:(NSString*)vid;

- (NSString*)getNetworkType;

- (void)updateMDLInfo;

+ (nonnull NSString*)generateSessionID:(nullable NSString*)did;

@end

@interface TTVideoEngineEventUtil : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, assign, readonly) NSInteger screenWidth;
@property (nonatomic, assign, readonly) NSInteger screenHeight;
@property (nonatomic, assign, readonly) float screenScale;

@property (nonatomic, copy) NSString *lastPlaySessionId;
@property (nonatomic, copy, nullable) NSString *appSessionId;

- (float)currentVolume;

@end

#endif /* TTVideoEngineEventBase_h */
