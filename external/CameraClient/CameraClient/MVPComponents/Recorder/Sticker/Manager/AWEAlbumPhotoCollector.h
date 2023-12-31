//
//  AWEAlbumPhotoCollector.h
//  Pods
//
//  Created by zhangchengtao on 2019/6/27.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VERecorder.h>
#import <TTVideoEditor/IESFaceDetector.h>
#import "AWEAlbumImageModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;

@class AWEAssetModel;
@class AWEAlbumImageModel;

@protocol AWEAlbumPhotoCollectorObserver;

@interface AWEAlbumPhotoCollector : NSObject

// 已检测的符合条件的图片资源
@property (nonatomic, readonly) NSArray<AWEAlbumImageModel *> *detectedResult;

// 观察者，监控探测结果的变化状况，刷新UI显示
@property (nonatomic, weak) id<AWEAlbumPhotoCollectorObserver> observer;

@property (nonatomic, copy, readonly) NSString *identifier;

@property (nonatomic, assign) NSInteger maxDetectCount;

- (instancetype)initWithIdentifier:(nonnull NSString *)identifier;

- (instancetype)init NS_UNAVAILABLE;

- (void)startDetect;

- (void)stopDetect;

- (void)reset;

- (AWEAlbumImageModel * __nullable)imageFrom:(AWEAssetModel *)assetModel;

@end

@protocol AWEAlbumPhotoCollectorObserver <NSObject>

// 照片检测开始
- (void)collectorDidStartDetect:(AWEAlbumPhotoCollector *)collector;

// 检测到符合条件的照片，数据发生变化，需要更新UI
- (void)collector:(AWEAlbumPhotoCollector *)collector detectResultDidChange:(NSDictionary *)change;

// 照片检测暂停
- (void)collectorDidPauseDetect:(AWEAlbumPhotoCollector *)collector;

// 照片检测结束
- (void)collectorDidFinishDetect:(AWEAlbumPhotoCollector *)collector;

@end

// AR抠脸收集
@interface AWEAlbumFacePhotoCollector : AWEAlbumPhotoCollector

@end

// pixaloop图片收集
@interface AWEAlbumPixaloopPhotoCollector : AWEAlbumPhotoCollector

@property (nonatomic, copy, readonly) NSArray<NSString *> *pixaloopAlg;
@property (nonatomic, copy, readonly) NSString *pixaloopRelation;
@property (nonatomic, copy, readonly) NSString *pixaloopImgK;

- (instancetype)initWithIdentifier:(NSString *)identifier
                       pixaloopAlg:(NSArray<NSString *> *)pixaloopAlg
                  pixaloopRelation:(NSString *)pixaloopRelation
                      pixaloopImgK:(NSString *)pixaloopImgK
                  pixaloopSDKExtra:(NSDictionary *)pixaloopSDKExtra;

- (AWEAlbumPhotoCollectorDetectResult)isPixaloopSupportWithAsset:(PHAsset *)asset;

@end

// 视频收集
@interface AWEAlbumVideoCollector : AWEAlbumPhotoCollector

@property (nonatomic, copy, readonly) NSString *pixaloopVKey;

@property (nonatomic, copy, readonly) NSString *pixaloopResourcePath;

- (instancetype)initWithIdentifier:(NSString *)identifier pixaloopVKey:(NSString *)pixaloopK pixaloopResourcePath:(NSString*)pixaloopResourcePath;

@end

NS_ASSUME_NONNULL_END
