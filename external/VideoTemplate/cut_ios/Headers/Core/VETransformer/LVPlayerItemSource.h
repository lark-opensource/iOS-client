//
//  LVPlayerItemSource.h
//  Pods
//
//  Created by lxp on 2020/2/5.
//

#import <Foundation/Foundation.h>
//#include <cdom/model/Project.h>
#import "LVMediaDraft.h"
#import "LVReplaceMaterialFragment.h"

NS_ASSUME_NONNULL_BEGIN

@class LVPlayerItemSource;

@protocol LVPlayerItemSourceDelegate <NSObject>

- (void)didSuccessOfSource:(LVPlayerItemSource *)source;
- (void)progressUpdateOfSource:(LVPlayerItemSource *)source progress:(CGFloat)progress;
- (void)didFailedOfSource:(LVPlayerItemSource *)source error:(NSError *)error;

@end

@protocol LVPlayerItemSourceDataSource <NSObject>

- (void)source:(LVPlayerItemSource *)source downloadFile:(NSURL *)fileURL completion:(void(^)( NSString * _Nullable path, NSError * _Nullable error))completion;

- (void)source:(LVPlayerItemSource *)source replaceFragments:(NSArray<LVReplaceMaterialFragment *> *)replaceFragments;

@optional
- (NSString *)source:(LVPlayerItemSource *)source migrationJSONString:(NSString *)jsonString error:(NSError **)error;

@end

typedef void(^LVPlayerItemSourceProgress)(CGFloat progress);
typedef void(^LVPlayerItemSourcecCompletion)(LVPlayerItemSource *source, NSError *_Nullable error);

@interface LVPlayerItemSource : NSObject

@property (nonatomic, copy, readonly) NSString *workspace;

@property (nonatomic, weak) id<LVPlayerItemSourceDelegate> delegate;

@property (nonatomic, weak) id<LVPlayerItemSourceDataSource> dataSource;

- (nonnull instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithWorkspace:(NSString *)workspace;

- (instancetype)initWithDownloadUrl:(NSString *)downloadUrl workspace:(NSString *)workspace;

- (void)setup;

- (void)cancel;

- (void)setupAsyncWithProgress:(LVPlayerItemSourceProgress _Nullable)rogress completion:(LVPlayerItemSourcecCompletion _Nullable)completion;

- (LVMediaDraft *)resultDraft;

- (void)replaceFragments:(NSArray<LVReplaceMaterialFragment *> *)fragments;

- (void)downloadEffects:(LVMediaDraft *)draft
             completion:(void(^)(BOOL success, NSError *error))completion;

+ (NSString *)transDraftToJson:(LVMediaDraft *)draft;

+ (nullable LVMediaDraft *)transJsonToDraft:(NSString *)json;

@end

@interface LVPlayerItemSource ()

+ (BOOL)isUnzipFailedErrorCode:(NSInteger)errorCode;

+ (BOOL)isFetchEffectFailedErrorCode:(NSInteger)errorCode;

+ (BOOL)isDownloadZipFailedErrorCode:(NSInteger)errorCode;

@end

NS_ASSUME_NONNULL_END
