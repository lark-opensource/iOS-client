//
//  NLESegmentMV+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/11.
//

#import <Foundation/Foundation.h>
#import "NLESegment+iOS.h"
#import "NLEResourceNode+iOS.h"
#import "NLEStyCrop+iOS.h"
#import "NLENativeDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentMV_OC : NLESegment_OC

@property (nonatomic, strong) NLEResourceNode_OC *sourceFile;

/// 用户资源对应的类型, TYPE_IMAGE / TYPE_VIDEO / TYPE_RGBA
@property (nonatomic, assign) NLESegmentMVResourceType sourceFileType;

/// 起始时间
@property (nonatomic, assign) CMTime start;

/// 结束时间
@property (nonatomic, assign) CMTime end;

/// MV素材分辨率 [rgba模式用]
@property (nonatomic, assign) NSUInteger width;

/// MV素材分辨率 [rgba模式用]
@property (nonatomic, assign) NSUInteger height;

/// 裁切信息
@property (nonatomic, strong) NLEStyCrop_OC *crop;

/// 素材原声音量大小
@property (nonatomic, assign) CGFloat volume;

@end

NS_ASSUME_NONNULL_END
