//
//  OpusCodec+Stream.h
//  OCOpusCodec
//
//  Created by 李晨 on 2019/3/11.
//  Copyright © 2019 lichen. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<oc-opus-codec/OpusCodec.h>)
#import <oc-opus-codec/OpusConfig.h>
#else
#import "OpusConfig.h"
#endif

@interface OpusStreamCodec : NSObject

- (instancetype _Nullable)initWithConfig:(OpusConfig* _Nonnull)config;
- (nullable NSData*)encode_pcm_data:(nonnull NSData*)data isEnd:(BOOL)isEnd;

@end
