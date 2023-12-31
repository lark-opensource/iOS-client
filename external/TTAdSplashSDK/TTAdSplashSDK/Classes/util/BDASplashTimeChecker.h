//
//  BDASplashTimeChecker.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/2/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kBDASplashCorrectTime;

/** 主要用于校验本地时间是否准确，校验准确后才能展示广告，防止用户调整本地时间提前展示素材 */
@interface BDASplashTimeChecker : NSObject

+ (NSTimeInterval)getCorrectTime;

+ (void)updateRemoteTime:(NSTimeInterval)remoteTime;


@end

NS_ASSUME_NONNULL_END
