//
//   DVEAlbumResourcePickerModel.h
//   NLEEditor
//
//   Created  by ByteDance on 2021/9/9.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import "DVEResourcePickerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEAlbumResourcePickerModel :NSObject<DVEResourcePickerModel>

@property (nonatomic, assign) DVEResourcePickerModelType type;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) AVURLAsset *videoAsset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, strong) AVAsset *imageAsset;
@property (nonatomic, assign) CMTime imageDuration;
@property (nonatomic, assign) float videoSpeed;
@property (nonatomic, assign) BOOL isGIFImage;

- (instancetype)initWithURL:(NSURL *)videoUrl;

+ (NSString*)tempImageResourceDirectory;
@end

NS_ASSUME_NONNULL_END
