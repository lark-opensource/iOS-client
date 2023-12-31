//
//  ACCIronManServiceProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/30.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCModuleService.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCIronManPage)
{
    ACCIronManPageUnknown = 0,
    ACCIronManPageRecord,
    ACCIronManPageEdit,
    ACCIronManPagePublish,
};

typedef NS_ENUM(NSInteger, ACCIronManPublishStatus)
{
    ACCIronManPublishStatusUnknown,  // 小程序未调起拍摄器或剪裁器
    ACCIronManPublishStatusRecord,   // 调起拍摄页或者剪裁器的状态
    ACCIronManPublishStatusPublish,  // 进入到发布页的状态
};

@protocol ACCIronManServiceProtocol <NSObject>

/*
 * 设置小程序status
 */
-(void)setIronManPublishStatusForPage:(ACCIronManPage)page;

/*
 * 发送消息给share task
 */
-(void)sendIronManMessageAtPage:(ACCIronManPage)page;


- (ACCIronManPublishStatus)ironManPublishStatus;

/// 获取设备名称
- (NSString * _Nullable)getDeviceName;

@end

NS_ASSUME_NONNULL_END
