//
//  BDImageDecoder.h
//  BDWebImage
//
//  Created by 陈奕 on 2021/3/30.
//

#ifndef BDImageDecoder_h
#define BDImageDecoder_h

#import <Foundation/Foundation.h>
#import "BDImageDecoderConfig.h"

typedef NS_ENUM(NSUInteger, BDImageCodeType);

@protocol BDImageDecoder <NSObject>

@required
@property (nonatomic, assign, readonly) BDImageCodeType codeType;

@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, assign, readonly) BOOL progressiveDownloading; // ProgressiveDownload should hold the decoder

@property (nonatomic, assign, readonly) UIImageOrientation imageOrientation;
@property (nonatomic, assign, readonly) NSUInteger imageCount;
@property (nonatomic, assign, readonly) NSUInteger loopCount;
@property (nonatomic, assign, readonly) CGSize originSize;

@property (nonatomic, assign, readonly) BDImageDecoderSizeType sizeType;

@property (nonatomic, strong, readonly) BDImageDecoderConfig *config;

- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithData:(NSData *)data config:(BDImageDecoderConfig *)config;
- (instancetype)initWithContentOfFile:(NSString *)file;

- (CGImageRef)copyImageAtIndex:(NSUInteger)index;
- (CFTimeInterval)frameDelayAtIndex:(NSUInteger)index;

@optional
- (instancetype)initWithIncrementalData:(NSData *)data config:(BDImageDecoderConfig *)config;
- (void)changeDecoderWithData:(NSData *)data finished:(BOOL)finished;
+ (BOOL)supportProgressDecode:(NSData *)data;
+ (BOOL)supportStaticProgressDecode:(BDImageCodeType)type;

+ (BOOL)canDecode:(NSData *)data;

+ (BOOL)isAnimatedImage:(NSData *)data;

@end

@protocol BDThumbImageDecoder <NSObject>

// For Heif Thumb Decoder
+ (BOOL)supportDecodeThumbFromHeicData;
+ (BOOL)isStaticHeicImage:(NSData *)data;
+ (NSInteger)parseThumbLocationForHeicData:(NSData *)data minDataSize:(NSInteger *)minDataSize;
+ (NSMutableData *)heicRepackData:(NSData *)data;
- (CGImageRef)decodeThumbImage;

@end


#endif /* BDImageDecoder_h */
