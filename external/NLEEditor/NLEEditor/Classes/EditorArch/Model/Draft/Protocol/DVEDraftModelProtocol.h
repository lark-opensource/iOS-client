//
//  DVEDraftProtocol.h
//  BDAlogProtocol
//
//  Created by bytedance on 2021/10/15.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import "DVENLEEditorProtocol.h"
#import <DVEFoundationKit/DVECommonDefine.h>

NS_ASSUME_NONNULL_BEGIN

@class DVEVCContext;

@protocol DVEDraftModelProtocol <NSObject>
//草稿名称
@property (nonatomic, copy) NSString *name;
//草稿封面路径
@property (nonatomic, copy) NSString *iconFileUrl;
//草稿最后修改时间
@property (nonatomic, copy) NSString *date;
//草稿ID
@property (nonatomic, copy) NSString *draftID;
//草稿的时长
@property (nonatomic, assign) NSTimeInterval duration;
//草稿片段数量
@property (nonatomic, assign) NSInteger videoSegmentNum;

@property (nonatomic, assign, readonly) DVEBusinessType modelType;

@property (nonatomic, copy) NSString *appPath;

@property (nonatomic, copy) NSString *bundlePath;

/// 草稿复制，并返回复制的草稿
- (id<DVEDraftModelProtocol>)copyDraft;

/// 保存草稿
/// @param vcContext 编辑上下文
- (void)storeDraft:(DVEVCContext *)vcContext;

/// 恢复草稿
/// @param vcContext 编辑上下文
- (void)restoreDraft:(DVEVCContext *)vcContext;

/// 当前草稿资源文件夹位置
- (NSString *)draftPath;

/// 草稿model转化成json字符串
- (NSString *)modelToJson;

/// 草稿根据json字符串进行初始化
/// @param jsonStr json字符串
+ (id<DVEDraftModelProtocol>)modelWithModelJson:(NSString *)jsonStr;

@end

NS_ASSUME_NONNULL_END
