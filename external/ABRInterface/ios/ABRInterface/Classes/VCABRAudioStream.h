//
//  ABRAudioStream.h
//  abrmodule
//
//  Created by guikunzhi on 2020/3/29.
//  Copyright © 2020 gkz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVCABRStream.h"

NS_ASSUME_NONNULL_BEGIN

@interface VCABRAudioStream : NSObject <IVCABRAudioStream>

@property (nonatomic, copy, nullable, getter=getStreamId) NSString *streamId;
@property (nonatomic, copy, nullable, getter=getCodec) NSString *codec;
@property (nonatomic, assign, getter=getSegmentDuration) int segmentDuration;
@property (nonatomic, assign, getter=getBandwidth) int bandwidth;
@property (nonatomic, assign, getter=getSampleRate) int sampleRate;

@end

NS_ASSUME_NONNULL_END
