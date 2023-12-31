//
//  ACCTemplateTextFragment.h
//  CameraClient
//
//  Created by long.chen on 2020/3/30.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTimeRange.h>

NS_ASSUME_NONNULL_BEGIN

@class LVTemplateTextFragment;
@interface ACCTemplateTextFragment : NSObject

@property (nonatomic, copy, readonly) NSString *payloadID;     // 文字的ID
@property (nonatomic, assign, readonly) CMTimeRange timeRange; // 时间范围
@property (nonatomic, copy) NSString *content;       // 文字内容
@property (nonatomic, strong) UIImage *albumImage;   // 文字开始时间对于的视频预览图

+ (ACCTemplateTextFragment *)convertFromLVTextFragment:(LVTemplateTextFragment *)textFragment;

- (id)copyWithZone:(NSZone *)zone;

@end

NS_ASSUME_NONNULL_END
