//
//  OpusCodec+Wav.h
//  OCOpusCodec
//
//  Created by 李晨 on 2019/3/11.
//  Copyright © 2019 lichen. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<oc-opus-codec/OpusCodec.h>)
#import <oc-opus-codec/OpusCodec.h>
#else
#import "OpusCodec.h"
#endif

@interface OpusCodec(Wav)

+(BOOL)isWavFormat:(nullable NSData*)wav_data;

@end
