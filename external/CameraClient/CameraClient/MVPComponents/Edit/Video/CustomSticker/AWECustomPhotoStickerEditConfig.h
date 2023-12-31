//
//  AWECustomPhotoStickerEditConfig.h
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/22.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@class AWECustomStickerLimitConfig,YYImage;

@interface AWECustomPhotoStickerEditConfig : NSObject

@property (nonatomic, assign, readonly) BOOL isGIF;

@property (nonatomic, assign, readonly) BOOL shouldUsePNGRepresentation;

@property (nonatomic, strong, readonly) AWECustomStickerLimitConfig *configs;
//Output data
@property(nonatomic, strong) YYImage *animatedImage;
//Compressed input image ,input to preview page
@property(nonatomic, strong) UIImage *inputImage;
//Processed image ,maybe nil, but always PNG format
@property(nonatomic, strong) UIImage *processedImage;
//Use Processed
@property(nonatomic, assign) BOOL useProcessedData;

- (instancetype)initWithUTI:(NSString *)dataUTI limit:(AWECustomStickerLimitConfig *)configs;

@end

@interface AWECustomPhotoStickerClipedInfo : MTLModel<MTLJSONSerializing>
//base64
@property (nonatomic, copy) NSString *content;
//
@property (nonatomic, copy) NSArray <NSArray *> *points;

@property (nonatomic, copy) NSDictionary *bbox;

- (CGRect)boxRect;

- (BOOL)clipInfoValid;

@end
