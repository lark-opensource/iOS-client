//
//  LVTemplateDataManager+Fetcher.h
//  VideoTemplate
//
//  Created by luochaojing on 2020/3/18.
//

#import "LVTemplateDataManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVTemplateTextFragment: NSObject

@property (nonatomic, copy, readonly) NSString *payloadID;     // 文字的ID
@property (nonatomic, copy, readonly) NSString *content;       // 文字内容
@property (nonatomic, strong, readonly) UIImage *albumImage;   // 文字开始时间对于的视频预览图
@property (nonatomic, assign, readonly) CMTimeRange timeRange; // 时间范围

@end

@interface LVTemplateTextTemplateFragment: LVTemplateTextFragment

@property (nonatomic, copy, readonly) NSString *textTemplateSegmentID;     // 文字模板片段的ID

@property (nonatomic, assign, readonly) NSInteger idxOfTextPayload;     // 文字Payload的idx

@end

@interface LVTemplateVideoEditFragment : NSObject

@property (nonatomic, copy, readonly) NSString *payloadID;           // 视频ID

@property (nonatomic, assign, readonly) CMTimeRange targetTimeRange; // 在时间线上范围
@property (nonatomic, assign, readonly) CMTimeRange sourceTimeRaneg; // 原视频的时间范围
@property (nonatomic, assign, readonly) BOOL canReplace;             // 是否可替换
@property (nonatomic, assign, readonly) BOOL isSubVideo;             // 是否是画中画
@property (nonatomic, strong, readonly) UIImage *albumImage;         // 文字开始时间对于的视频预览图
@property (nonatomic, strong, readonly) LVVideoCropInfo *crop;       // 四个角的裁剪信息
@property (nonatomic, assign, readonly) BOOL isReversed;
@property (nonatomic, assign, readonly) BOOL isVideo;                // 是否是视频
@property (nonatomic, copy, readonly) NSString *assetPath;           // 视频或者图片的路径

@end

@interface LVTemplateDataManager (Fetcher)

- (NSArray<LVTemplateTextFragment *> *)canReplaceTextFragments;

- (NSArray<LVTemplateVideoEditFragment *> *)allVideoFragments;

/// 视频封面
/// @param fragment 视频片段
/// @param imageSize 图片尺寸：为了保证清晰度，至少传 imageView.size * UIScreen.scale
- (UIImage *)coverOfVideoFragment:(LVTemplateVideoEditFragment *)fragment preferSize:(CGSize)imageSize;

/// 文字片段封面
/// @param fragment 文字片段
/// @param imageSize 图片尺寸：为了保证清晰度，至少传 imageView.size * UIScreen.scale
- (UIImage *)coverOfTextFragment:(LVTemplateTextFragment *)fragment preferSize:(CGSize)imageSize;

// 更新了视频之后，会根据视频的时间范围去更新对应的文字封面。
- (void)updateTextCoversAfterReplaceVideo:(LVTemplateVideoEditFragment *)fragment preferSize:(CGSize)imageSize completion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
