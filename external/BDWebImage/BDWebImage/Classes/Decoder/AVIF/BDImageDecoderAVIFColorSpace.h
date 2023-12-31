//
//  BDImageDecoderAVIFColorSpace.h
//  BDWebImage
//
//  Created by bytedance on 12/30/20.
//

#import "avif.h"


extern CGColorSpaceRef _Nullable BDAVIFCreateColorSpaceMono(avifColorPrimaries const colorPrimaries, avifTransferCharacteristics const transferCharacteristics) __attribute__((visibility("hidden")));
extern CGColorSpaceRef _Nullable BDAVIFCreateColorSpaceRGB(avifColorPrimaries const colorPrimaries, avifTransferCharacteristics const transferCharacteristics) __attribute__((visibility("hidden")));

void BDAVIFCalcColorSpaceMono(avifImage * _Nonnull avif, CGColorSpaceRef _Nullable * _Nonnull ref, BOOL* _Nonnull shouldRelease);
void BDAVIFCalcColorSpaceRGB(avifImage * _Nonnull avif, CGColorSpaceRef _Nullable * _Nonnull ref, BOOL* _Nonnull shouldRelease);
