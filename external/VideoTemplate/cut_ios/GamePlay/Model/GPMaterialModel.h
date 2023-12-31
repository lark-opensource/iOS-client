//
//  GPMaterialModel.h
//  VideoTemplate
//
//  Created by bytedance on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, GPMaterialFileType) {
    GPMaterialFileTypePhoto,
    GPMaterialFileTypeVideo,
};


@interface GPMaterialModel : NSObject

@property (nonatomic, copy) NSString *gameplayAlgorithm;
@property (nonatomic, copy) NSString * algorithmConfig;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, assign) GPMaterialFileType fileType;
@property (nonatomic, assign) GPMaterialFileType outputType;

@end

@interface GPMaterialOutputModel : NSObject

@property (nonatomic, assign) GPMaterialFileType outputType;
@property (nonatomic, strong) NSURL *originURL;
//处理后的图片
@property (nonatomic, copy  ) NSURL *processedImageFileURL;
@property (nonatomic, strong) UIImage *processedImage;
@property (nonatomic, copy) NSString *processedImageName;
@property (nonatomic, assign) CGSize processedImageSize;
//处理后的视频
@property (nonatomic, strong) AVURLAsset *processAsset;
@property (nonatomic, strong) NSError *error;
//视频或图片的config信息
@property (nonatomic ,copy) NSString *dataConfig;

- (instancetype)initWithMaterial:(GPMaterialModel *)material;

@end

NS_ASSUME_NONNULL_END
