//
//  BDLImageProtocol.h
//  BDLynx
//
//  Created by zys on 2020/2/6.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 图片来源
 */
typedef NS_OPTIONS(NSInteger, BDLImageSourceType) {
  BDLImageSourceTypeUnknow = 0,
  BDLImageSourceTypeAlbum = 1,
  BDLImageSourceTypeCamera = 1 << 1
};

/**
 * 图片尺寸的类型
 */
typedef NS_OPTIONS(NSInteger, BDLImageSizeType) {
  BDLImageSizeTypeUnknow = 0,
  BDLImageSizeTypeOriginal = 1,
  BDLImageSizeTypeCompressed = 1 << 1
};

/**
 * 调用宿主图片功能
 */
@protocol BDLImageProtocol <NSObject>

/**
 * 单例对象
 */
+ (instancetype)sharedInstance;

@required
//
//
- (void)requestImage:(NSURL *)url
             channel:(NSString *)channel
                path:(NSString *)path
            complete:(void (^)(UIImage *, NSError *__nullable))complete;

@optional

/**
 * 预览图片，
 * @param images 图片的数组，数组里面是图片的地址
 * @param startIndex 开始的index
 */
- (void)previewImageWithURLs:(NSArray<NSString *> *)images startImageIndex:(NSInteger)startIndex;

/**
 * 选择图片
 * @param maxCount 最多可以选择的图片张数，一般头条是9张，抖音是12张。
 * @param sourceType 选择图片的来源, 可能是相册也可能是相机。
 * @param sizeType 所选的图片的尺寸，有['original', 'compressed'],
 * @param completion 返回选择图片(支持多个)的回调(images为nil代表用户取消)
 */
- (void)chooseImageWithMaxCount:(NSInteger)maxCount
                     sourceType:(BDLImageSourceType)sourceType
                       sizeType:(BDLImageSizeType)sizeType
                     completion:(void (^)(NSArray<UIImage *> *images))completion;

@end

NS_ASSUME_NONNULL_END
