//
//  AWERepoTrackModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/14.
//

#import <CreationKitArch/ACCRepoTrackModel.h>


NS_ASSUME_NONNULL_BEGIN

@interface AWERepoTrackModel : ACCRepoTrackModel <NSCopying, ACCRepositoryTrackContextProtocol, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, copy) NSString *creationSessionId; // 创作埋点，离开创作销毁

@property (nonatomic, copy) NSString *selectedMethod; // from which way the user start recording video (mv anchor, sticker anchor, music icon)

@property (nonatomic, copy) NSString *contentType;//视频内容，用于埋点
@property (nonatomic, copy) NSString *shootPreviousPage;//进入拍摄页之前的页面，用于埋点

@property (nonatomic, copy) NSString *friendLabel;

@property (nonatomic, readonly) NSString *tabName;

@property (nonatomic, copy) NSString *magic3ComponentId; //组件ID，区分是哪个魔方组件调起的拍摄
@property (nonatomic, copy) NSString *magic3Source; //投放渠道，区分H5活动的投放资源位
@property (nonatomic, copy) NSString *magic3ActivityId; //活动ID，区分是哪个魔方活动
@property (nonatomic, copy) NSString *storyGuidePlusIconType; //开拍引导入口类型，用于埋点
@property (nonatomic, copy) NSString *entrance; //开拍入口类型，用于埋点
@property (nonatomic, assign) BOOL isClickPlus; // 是否从+路径开拍

@property (nonatomic, assign) BOOL isRestoreFromBackup; // 是否从备份恢复的继续编辑
@property (nonatomic, assign) BOOL hasRecordEnterEvent; // 是否已经打过恢复编辑的埋点
@property (nonatomic, copy) NSDictionary *schemaTrackParmForActivity; // 通过 schema 调起活动的打点参数
@property (nonatomic, copy) NSDictionary *schemaTrackParams; // 通过 schema 调起打点参数
@property (nonatomic, copy) NSDictionary *extraTrackInfo; // 其他外部的打点参数
@property (nonatomic, copy) NSString *lastItemId;
@property (nonatomic, copy) NSString *originalFromMusicId; // 开拍时，上游带入的音乐ID，用户修改音乐也不变
@property (nonatomic, copy) NSString *originalFromMvId; // 开拍时，上游带入的影集ID，用户修改模版也不变
@property (nonatomic, copy) NSString *enterStatus;// 进入拍摄页的状态
@property (nonatomic, assign) NSInteger hdrScene;

@property (nonatomic, copy) NSString *activityExtraJson; // 发布时（create/aweme）, 会作为发布参数传递

@property (nonatomic, strong) NSNumber *isLongTitle; // 发布时，publish 埋点参数，不存草稿实时计算

@property (nonatomic, assign) BOOL isDiskResumeUpload; // 是否启用了磁盘续上传，打点

- (NSDictionary *)performanceTrackInfoDic;

- (BOOL)musicLandingMultiLengthInitially;

- (NSDictionary *)socialInfoTrackDic;

// @description: D侧独有的埋点精简逻辑在videoFragmentInfoDictionary的基础上移除了@"is_speed_change"
//               @"reshape_list" 和 @"smooth_list" 三个字段的上报, 后续可以让外部
//               控制实际需要删减的字段
//        @link: https://bytedance.feishu.cn/sheets/shtcn9Nw3r5CoB6afZMelbZSDIf
- (NSDictionary *)liteVideoFragmentInfoDictionary;

- (NSDictionary *)publishCommonTrackDict;

- (NSString *)isMultiContentValue;

- (NSDictionary *_Nonnull)referExtraByAppend:(NSDictionary *)extras;

@end

@interface AWEVideoPublishViewModel (AWERepoTrack)
 
@property (nonatomic, strong, readonly) AWERepoTrackModel *repoTrack;
 
@end

NS_ASSUME_NONNULL_END
