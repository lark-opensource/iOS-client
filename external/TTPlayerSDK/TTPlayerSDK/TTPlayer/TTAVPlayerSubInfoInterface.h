//
//  TTAVPlayerSubInfoInterface.h
//  TTAVPlayer
//
//  Created by jiangyue.666 on 2020/9/6.
//

#import <Foundation/Foundation.h>

#ifndef TTM_DUAL_CORE_TTPLAYER_SUBINFO_PROTOCOL_H
#define TTM_DUAL_CORE_TTPLAYER_SUBINFO_PROTOCOL_H

NS_ASSUME_NONNULL_BEGIN

static NSString *const kTTAVPlayerSubInfoPts = @"kTTAVPlayerSubInfoPts";
static NSString *const kTTAVPlayerSubInfoDuration = @"kTTAVPlayerSubInfoDuration";
static NSString *const kTTAVPlayerSubInfoContent = @"kTTAVPlayerSubInfoContent";
static NSString *const kTTAVPlayerSubLoadInfoFirstPts = @"kTTAVPlayerSubLoadInfoFirstPts";

@protocol TTAVPlayerSubInfoInterface <NSObject>
- (void)onSubInfoCallBack:(NSDictionary *)subInfo;
- (void)onSubSwitchCompleted:(BOOL)success languageId:(NSInteger)languageId;
- (void)onSubLoadFinished:(BOOL)success code:(NSInteger)code;
- (void)onSubLoadFinished:(BOOL)success code:(NSInteger)code info:(NSDictionary *)info;
@end

NS_ASSUME_NONNULL_END

#endif //TTM_DUAL_CORE_TTPLAYER_SUBINFO_PROTOCOL_H
