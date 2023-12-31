//
//  AWESingleStickerDownloader.h
//  Pods
//
//  Created by liyingpeng on 2020/8/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;

@interface AWESingleStickerDownloadResult : NSObject

@property (nonatomic, strong) NSError * _Nullable error;
@property (nonatomic, copy) NSString * _Nullable filePath;
@property (nonatomic, assign) BOOL failed;

@end

@interface AWESingleStickerDownloadInfo : NSObject

@property (nonatomic, copy) NSString *effectIdentifier;
@property (nonatomic, copy) NSString *effectName;
@property (nonatomic, copy) NSArray *fileDownloadURLs;
@property (nonatomic, copy) NSString *stickerUrl;
@property (nonatomic, assign) NSInteger duration;

@property (nonatomic, strong) AWESingleStickerDownloadResult *result;

@end

@interface AWESingleStickerDownloadParameter : NSObject

@property (nonatomic, strong, nullable) IESEffectModel *sticker;
@property (nonatomic, copy, nullable) void(^downloadProgressBlock)(CGFloat);
@property (nonatomic, copy) void(^compeletion)(AWESingleStickerDownloadInfo *);
@property (nonatomic, assign) BOOL cancelled;

@end

@interface AWESingleStickerDownloader : NSObject

- (void)downloadSticker:(AWESingleStickerDownloadParameter *)downloadParam;

@end

NS_ASSUME_NONNULL_END
