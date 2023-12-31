//
//  TTAVPlayerMaskInfoInterface.h
//  TTAVPlayer
//
//  Created by jiangyue.666 on 2020/9/6.
//

#import <Foundation/Foundation.h>

#ifndef TTM_DUAL_CORE_TTPLAYER_MASK_PROTOCOL_H
#define TTM_DUAL_CORE_TTPLAYER_MASK_PROTOCOL_H

NS_ASSUME_NONNULL_BEGIN

@protocol TTAVPlayerMaskInfoInterface <NSObject>
- (void)onMaskInfoCallBack:(NSString*)svg pts:(NSUInteger)pts;
@end

NS_ASSUME_NONNULL_END

#endif // TTM_DUAL_CORE_TTPLAYER_MASK_PROTOCOL_H
