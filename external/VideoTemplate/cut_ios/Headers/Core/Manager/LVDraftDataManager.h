//
//  LVDraftDataManager.h
//  DraftComponent
//
//  Created by zenglifeng on 2019/7/24.
//

#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVDraftDataManager : NSObject

@property (nonatomic, strong, nullable, readonly) LVMediaDraft *draft;

+ (instancetype)sharedManager;

/**
 同步保存模板/草稿
 @return 存储是否成功
 */
- (BOOL)syncWrite:(LVMediaDraft *)draft toPath:(NSString *)path error:(NSError **)error;

/**
 同步保存模板/草稿
 */
- (void)asyncWrite:(LVMediaDraft *)draft toPath:(NSString *)path completion:(nullable void(^)(NSString *path, NSError * _Nullable error, BOOL success))completion;

/**
 同步加载模板/草稿
 */
- (nullable LVMediaDraft *)syncReadFromPath:(NSString *)path error:(NSError **)error;

/**
 同步加载模板/草稿
 */
- (nullable LVMediaDraft *)syncReadFromJson:(NSString *)json error:(NSError **)error;

/**
 异步加载模板/草稿
 */
- (void)asyncReadFromPath:(NSString *)path completion:(nullable void(^)(NSString *path, NSError * _Nullable error, LVMediaDraft * _Nullable draft))completion;

/**
 同步文件拷贝
 */
- (BOOL)syncCopyFromSource:(NSString *)source toDestination:(NSString *)destination error:(NSError **)error;

/**
 异步文件拷贝
 */
- (void)asyncCopyFromSource:(NSString *)source toDestination:(NSString *)destination completion:(nullable void(^)(NSError * _Nullable error, BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
