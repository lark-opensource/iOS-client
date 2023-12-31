//
//  ACCFlowerCampaignDefine.h
//  CameraClient
//
//  Created by imqiuhang on 2021/11/17.
//

#ifndef ACCFlowerCampaignDefine_h
#define ACCFlowerCampaignDefine_h

/// FLower活动阶段定义
typedef NS_ENUM(NSUInteger, ACCFLOActivityStageType) {
    ACCFLOActivityStageTypeNone,        /// << 非活动阶段
    ACCFLOActivityStageTypeAppointment, /// << 预约阶段
    ACCFLOActivityStageTypeLuckyCard,   /// << 集卡阶段
    ACCFLOActivityStageTypeFreeTime,    /// << 集卡和除夕之间的空挡,发奖期
    ACCFLOActivityStageTypeFirework,    /// << 除夕阶段
    ACCFLOActivityStageTypeOlympic,     /// << 冬奥阶段
};

typedef NSString * ACCFLOSceneName;

// 相机内奖励弹窗（包含复访进入的奖励弹窗，相机内拍摄任务、编辑页）
static ACCFLOSceneName const ACCFLOSceneCameraBonusModal = @"camera_bonus_modal";

// 在编辑页发布后的奖励(不走相机)
static ACCFLOSceneName const ACCFLOScenePublishBonusModal = @"camera_outer_bonus_modal";

// 个人中心奖励弹窗
static ACCFLOSceneName const ACCFLOScenePersonBonusModal = @"person_bonus_modal";

// 任务弹窗
static ACCFLOSceneName const ACCFLOSceneCameraTask       = @"camera_task";

// 预约成功
static ACCFLOSceneName const ACCFLOSceneReserveSuccess   = @"reserve_success";

// NPC初次进入触发派卡
static ACCFLOSceneName const ACCFLOSceneNpcDispatchCard  = @"npc_dispatch_card";

// 红包雨-任务完成提示弹窗
static ACCFLOSceneName const ACCFLOSceneRpRainNotice     = @"rp_rain_notice";

// 红包雨-任务完成提示弹窗
static ACCFLOSceneName const ACCFLOSceneCameraCutDown    = @"camera_cutdown";

#endif /* ACCFlowerCampaignDefine_h */
