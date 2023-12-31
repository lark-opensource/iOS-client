//
//  ACCRepoUserIncentiveModelProtocol.h
//  CameraClient
//
//  Created by guoshuai on 2021/4/11.
//

#ifndef ACCRepoUserIncentiveModelProtocol_h
#define ACCRepoUserIncentiveModelProtocol_h

typedef NS_ENUM(NSUInteger, ACCPostTaskType) {
    ACCPostTaskTypePUGCSevenDaysPost = 1,  // 七日投稿任务
    ACCPostTaskTypeUGCFreshmanPost = 2,  // 新手投稿任务
    ACCPostTaskTypePUGCMillionPost = 3,  // 百万粉低活召回任务
    ACCPostTaskTypePUGCInactivePost = 4,  // 万粉低活任务
    ACCPostTaskTypeUGCPostUpload = 5,  // 上传
    ACCPostTaskTypeUGCPostProp = 6,  // 道具
    ACCPostTaskTypeUGCPostMV = 7,  // 影集
    ACCPostTaskTypeUGCPostNormal = 8,  // 发布任意视频任务
};

@protocol ACCRepoUserIncentiveModelProtocol <NSObject>

@property (nonatomic, copy) NSString *motivationTaskID;
@property (nonatomic, assign) NSUInteger motivationTaskType;
@property (nonatomic, assign) BOOL shouldShowEditIncentiveBubble;

- (NSString * _Nullable)motivationTaskReward;
- (NSString * _Nullable)motivationTaskTargetText;

@end

#endif /* ACCRepoUserIncentiveModelProtocol_h */
