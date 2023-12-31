//
//  LVCutSameVideoMaterial.h
//  VideoTemplate-Pods-Aweme
//
//  Created by zhangyuanming on 2021/2/24.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVCutSameVideoMaterial : NSObject <NSCopying>

@property (nonatomic, assign) BOOL isMutable;             // 是否可替换
@property (nonatomic, assign) BOOL isSubVideo;             // 是否是画中画
@property (nonatomic, assign) BOOL isReversed;
@property (nonatomic, assign) BOOL isVideo;                // 是否是视频
@property (nonatomic, assign) CMTime targetStartTime;      // 在时间线上范围
@property (nonatomic, assign) CMTimeRange sourceTimeRange;
@property (nonatomic, copy) NSString *materialId;
@property (nonatomic, copy) NSString *slotId;
@property (nonatomic, copy) NSString *relativePath;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGFloat cropXLeft;
@property (nonatomic, assign) CGFloat cropXRight;
@property (nonatomic, assign) CGFloat cropYLower;
@property (nonatomic, assign) CGFloat cropYUpper;
@property (nonatomic, copy) NSString *originPath;

@end

NS_ASSUME_NONNULL_END
