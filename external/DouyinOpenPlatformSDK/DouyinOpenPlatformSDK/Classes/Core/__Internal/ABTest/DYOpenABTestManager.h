//
//  DYOpenABTestManager.h
//  BDTDebugBox-BDTDebugBox
//
//  Created by AnchorCat on 2022/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYOpenABTestManager : NSObject

/**
 单例获取方法

 @return 单例
 */
+ (instancetype)sharedManager;

/**
 触发一个实验的的曝光

 @param vid 实验名称，vid将被加入曝光区
 */
- (void)exposeABTest:(NSString *)vid;


/**
 获取曝光区内vid

 @return 曝光区内vid，以逗号分隔
 */
- (NSString *)exposureVidString;

/**
 更新vidInfo
 */
- (void)handleVidInfo:(id)vidInfo;

@end

NS_ASSUME_NONNULL_END
