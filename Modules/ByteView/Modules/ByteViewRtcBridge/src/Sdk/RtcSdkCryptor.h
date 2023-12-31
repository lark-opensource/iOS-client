//
//  RtcSdkCryptor.h
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/6/2.
//

#import <Foundation/Foundation.h>
#import <VolcEngineRTC/VolcEngineRTC.h>
#import "RtcCrypting.h"

NS_ASSUME_NONNULL_BEGIN

@interface RtcSdkCryptor : NSObject

- (instancetype)initWithCryptor:(id<RtcCrypting>)cryptor;

- (void)setToEngine:(ByteRtcMeetingEngineKit *)engine;
- (void)removeFromEngine:(ByteRtcMeetingEngineKit *)engine;

@end

NS_ASSUME_NONNULL_END
