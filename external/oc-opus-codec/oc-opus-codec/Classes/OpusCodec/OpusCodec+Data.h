//
//  OpusCodec+Data.h
//  OCOpusCodec
//
//  Created by 李晨 on 2019/3/11.
//  Copyright © 2019 lichen. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<oc-opus-codec/OpusCodec.h>)
#import <oc-opus-codec/OpusCodec.h>
#import <oc-opus-codec/OpusConfig.h>
#else
#import "OpusCodec.h"
#import "OpusConfig.h"
#endif

@interface OpusCodec(Data)

+(nullable NSData*)encode_wav_data:(nonnull NSData*)wav_data;
+(nullable NSData*)encode_wav_data:(nonnull NSData*)wav_data config:(nonnull OpusConfig *)config;

+(nullable NSData*)decode_opus_data:(nonnull NSData*)opus_data;
+(nullable NSData*)decode_opus_data:(nonnull NSData*)opus_data config:(nonnull OpusConfig *)config;

@end
