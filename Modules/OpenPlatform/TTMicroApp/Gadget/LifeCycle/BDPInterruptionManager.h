//
//  BDPInterruptionManager.h
//  Timor
//
//  Created by CsoWhy on 2018/10/18.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPModel.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPModuleEngineType.h>

typedef NS_ENUM(NSInteger, BDPInterruptionStatus) {
    BDPInterruptionStatusBegin,
    BDPInterruptionStatusStop
};

@interface BDPInterruptionManager : NSObject

@property (nonatomic, assign) BOOL didEnterBackground;

+ (instancetype)sharedManager;

// TODO: yinyuan 冗余 Type 信息待确认
//触发自 BDPAppController viewwillappear
+ (void)postEnterForegroundNotification:(BDPType)type uniqueID:(BDPUniqueID *)uniqueID;
//触发自 BDPBaseContainerController,BDPAppController viewDidDisappear
+ (void)postEnterBackgroundNotification:(BDPType)type uniqueID:(BDPUniqueID *)uniqueID;
//触发自 BDPAppController viewdidappear
+ (void)postDidEnterForegroundNotification:(BDPType)type uniqueID:(BDPUniqueID *)uniqueID;

@end
