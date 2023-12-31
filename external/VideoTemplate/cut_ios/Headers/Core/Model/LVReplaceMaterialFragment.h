//
//  LVReplaceMaterialFragment.h
//  LVTemplate
//
//  Created by luochaojing on 2020/2/13.
//

#import <Foundation/Foundation.h>
#import "LVModelType.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVReplaceMaterialFragment : NSObject

@property(nonatomic, copy) NSString *materialId; // 素材id 定位 project segment 用
@property(nonatomic, assign) NSUInteger targetStartTime; // 排序需要
@property(nonatomic, assign) BOOL isMutable; // true 表示可变，需要用户选择视频填充
@property(nonatomic, assign) LVMutableConfigAlignMode alignMode; // 视频素材对齐方式
@property(nonatomic, assign) BOOL isReverse; // 是否需要倒放
@property(nonatomic, assign) BOOL isCartoon; // 是否需要漫画

@property(nonatomic, assign) NSUInteger width; // 宽
@property(nonatomic, assign) NSUInteger height; // 高
@property(nonatomic, assign) NSUInteger duration; // 时长

@property(nonatomic, copy) NSString *path; // 路径
@property(nonatomic, assign) NSUInteger sourceStartTime; // 时间裁剪起始点
@property(nonatomic, assign) BOOL isVideo; // 视频类型, 图片或者正常视频
@property(nonatomic, strong) LVVideoCropInfo *crop; // 空间裁剪区域

@end

NS_ASSUME_NONNULL_END
