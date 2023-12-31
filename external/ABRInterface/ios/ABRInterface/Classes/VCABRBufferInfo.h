//
//  ABRBufferInfo.h
//  abrmodule
//
//  Created by guikunzhi on 2020/3/29.
//  Copyright © 2020 gkz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVCABRBufferInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface VCABRBufferInfo : NSObject<IVCABRBufferInfo>

@property (nonatomic, copy, nullable, getter=getStreamId) NSString *streamId;
@property (nonatomic, assign, getter=getPlayerAvailDuration) float playerAvailDuration;
@property (nonatomic, assign, getter=getFileAvailSize) int64_t fileAvailSize;
@property (nonatomic, assign, getter=getHeadSize) int64_t headSize;

@end

NS_ASSUME_NONNULL_END
