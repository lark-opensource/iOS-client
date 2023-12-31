//
//  LVVEAiMattingCache.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/11/24.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LVVEAIMattingFileManager.h"
#import "LVClipAIMattingDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVAIMattingCache : NSObject

@property(nonatomic, strong, readonly) LVVEAIMattingFileManager *fileManager;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileManager:(LVVEAIMattingFileManager *)fileManager;

- (LVClipAIMattingRecord * _Nullable)recordForAsset:(AVAsset *)asset;
- (void)updateRecord:(LVClipAIMattingRecord *)record forAsset:(AVAsset *)asset;
- (LVClipAIMattingRecord * _Nullable)addRecordIfNeededWithClipAsset:(LVMediaAsset *)clipAsset;
- (void)removeRecordForAsset:(AVAsset *)asset;

- (LVClipAIMattingRecord * _Nullable)recordForSegmentID:(NSString *)segmentID;
- (void)updateRecord:(LVClipAIMattingRecord *)record forSegmentID:(NSString *)segmentID;
- (LVClipAIMattingRecord * _Nullable)addRecordIfNeededWithNewClipAsset:(LVMediaAsset *)clipAsset forSegmentID:(NSString *)segmentID;
- (LVClipAIMattingRecord * _Nullable)updateRecordIfNeededWithNewAsset:(AVAsset *)newAsset forSegmentID:(NSString *)segmentID;
- (LVClipAIMattingRecord * _Nullable)removeRecordForSegmentID:(NSString *)segmentID;
- (NSArray<NSString *> *)allSegmentIDs;

- (void)enumerateRecords:(void(^)(LVClipAIMattingRecord * _Nonnull record, BOOL * _Nonnull stop))block;

@end

NS_ASSUME_NONNULL_END
