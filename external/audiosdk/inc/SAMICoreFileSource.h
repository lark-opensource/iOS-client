//
// Created by CHENZEMIN on 2022/7/7.
//

#ifndef SAMI_CORE_OC_MEFILESOURCE_H
#define SAMI_CORE_OC_MEFILESOURCE_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

@interface SAMICore_FileSource: NSObject

- (_Nullable id)create:(NSString* _Nonnull)path;

- (bool)seek:(size_t)position;

- (void* _Nonnull)readWithNumFrame:(size_t)frame_num RealSize:(size_t* _Nonnull)size;

- (size_t)getNumChannel;

- (size_t)getSampleRate;

- (size_t)getNumFrames;

- (size_t)getNumBit;

- (size_t)getPosition;

- (NSString* _Nullable)getPath;

- (void)close;

@end

#ifdef __cplusplus
}   // extern "C"
#endif

#endif  //SAMI_CORE_OC_MEFILESOURCE_H
