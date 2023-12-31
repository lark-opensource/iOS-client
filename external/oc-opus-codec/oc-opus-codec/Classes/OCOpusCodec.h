//
//  OCOpusCodec.h
//  OCOpusCodec
//
//  Created by 李晨 on 2019/3/11.
//  Copyright © 2019 lichen. All rights reserved.
//

#ifndef OCOpusCodec_h
#define OCOpusCodec_h

#if __has_include(<oc-opus-codec/OpusCodec.h>)
#import <oc-opus-codec/OpusCodec.h>
#import <oc-opus-codec/OpusCodec+Wav.h>
#import <oc-opus-codec/OpusCodec+Data.h>
#import <oc-opus-codec/OpusCodec+Stream.h>
#import <oc-opus-codec/OpusConfig.h>
#else

#import "OpusCodec.h"
#import "OpusCodec+Wav.h"
#import "OpusCodec+Data.h"
#import "OpusCodec+Stream.h"
#import "OpusConfig.h"

#endif

#endif /* OCOpusCodec_h */
