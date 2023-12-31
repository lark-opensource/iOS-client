//
//  NLEVECallBackProtocol.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/8/5.
//

#import <Foundation/Foundation.h>
#import "NLEAllKeyFrameInfo.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NLEVECallBackProtocol <NSObject>
/// 目前是VE pin 结果回调通知
- (void)veCallBackChanged:(BOOL) result error:(NSError *_Nonnull) error;

@end


@protocol NLEKeyFrameCallbackProtocol <NSObject>

- (void)nleDidChangedWithPTS:(CMTime)time keyFrameInfo:(NLEAllKeyFrameInfo *)info;

@end

NS_ASSUME_NONNULL_END
