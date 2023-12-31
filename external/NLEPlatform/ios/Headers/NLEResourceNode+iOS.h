//
//  NLEResourceNode+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#import <Foundation/Foundation.h>
#import "NLENativeDefine.h"
#import "NLENode+iOS.h"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEResourceNode_OC : NLENode_OC
///资源ID
@property (nonatomic, copy) NSString *resourceId;
//资源包的路径
@property (nonatomic, copy) NSString *resourceFile;
///资源名称
@property (nonatomic, copy) NSString *resourceName;
///宽度
@property (nonatomic, assign) uint32_t width;
///高度
@property (nonatomic, assign) uint32_t height;
///资源类型
@property (nonatomic, assign) NLEResourceType resourceType;
///资源标签
@property (nonatomic, assign) NLEResourceTag resourceTag;
///资源时长
@property (nonatomic, assign) CMTime duration;

@end

NS_ASSUME_NONNULL_END
