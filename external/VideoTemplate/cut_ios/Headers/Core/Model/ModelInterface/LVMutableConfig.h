//
//  LVMutableConfig.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"
#import "LVModelType.h"
#import "LVMediaDefinition.h"

NS_ASSUME_NONNULL_BEGIN
@interface LVMutableConfig (Interface)<LVCopying>
/**
 对齐画布/视频
 */
@property (nonatomic, assign) LVMutableConfigAlignMode alignMode;

///**
// 可变的轨道信息
// */
//@property (nonatomic, copy, nullable) NSArray<LVMutablePayloadInfo *> *mutableInfos;

/**
 可变的轨道信息
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, LVMutablePayloadInfo *> *mutableInfoDict;

@end

NS_ASSUME_NONNULL_END
