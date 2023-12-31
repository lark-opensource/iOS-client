//
//  BDPXScreenManager.h
//  TTMicroApp
//
//  Created by qianhongqiang on 2022/8/30.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>

@interface BDPXScreenManager : NSObject

+ (BOOL)isXScreenMode:(BDPUniqueID *)uniqueID;

+ (CGFloat)XScreenPresentationRate:(BDPUniqueID *)uniqueID;

+ (nullable NSString *)XScreenPresentationStyle:(BDPUniqueID *)uniqueID;


/// 合适的半屏小程序展示高度
/// @param uniqueID uniqueID
+ (CGFloat)XScreenAppropriatePresentationHeight:(BDPUniqueID *)uniqueID;


/// 合适的半屏小程序蒙层高度
/// @param uniqueID uniqueID
+ (CGFloat)XScreenAppropriateMaskHeight:(BDPUniqueID *)uniqueID;

/// 将半屏的类型(NSString *)转换成占屏幕比例
/// @param style 半屏幕类型
+ (CGFloat)castPresentationStyleToRate:(NSString *)style;

+ (BOOL)isXScreenFGConfigEnable;

@end
