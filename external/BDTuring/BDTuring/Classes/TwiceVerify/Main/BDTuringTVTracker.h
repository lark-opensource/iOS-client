//
//  BDTuringTVTracker.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/2.
//

#import <Foundation/Foundation.h>
#import "BDTuringTVDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringTVTracker : NSObject

+ (void)trackerShowTwiceVerifyWithScene:(NSString *)scene type:(kBDTuringTVBlockType)type aid:(NSString *)aid;

+ (void)trackerTwiceVerifySubmitWithScene:(NSString *)scene type:(kBDTuringTVBlockType)type aid:(NSString *)aid result:(BOOL)success;

@end

NS_ASSUME_NONNULL_END
