//
//  ACCFlowerRedPacketHelperProtocol.h
//  CameraClient-Pods-AwemeCore
//
//  Created by imqiuhang on 2021/11/14.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

@protocol ACCFlowerRedPacketHelperProtocol <NSObject>

/// flower红包活动总开关
+ (BOOL)isFlowerRedPacketActivityOn;

/// 是否是朋友红包雨相关的活动
+ (BOOL)isFlowerRedPacketActivityVideoType:(NSInteger)activityVideoType;

/// 红包雨相关的活动编辑页按钮
+ (NSString *)flowerRedPacketActivityPublishBtnTitle;

/// 卡券默认的发送个数
+ (NSInteger)flowerRedPacketDefaultCouponSendCount;

+ (NSInteger)flowerRedPacketBarItemIndex;

+ (NSString *)flowerRedPacketShootToast;

@end


FOUNDATION_STATIC_INLINE Class<ACCFlowerRedPacketHelperProtocol> ACCFlowerRedPacketHelper() {
    
    return [[ACCBaseServiceProvider() resolveObject:@protocol(ACCFlowerRedPacketHelperProtocol)] class];
}
