//
//  LVCompileManager.h
//  Pods
//
//  Created by luochaojing on 2020/3/10.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/IESMMTranscodeRes.h>
#import "LVMediaDefinition.h"
#import "LVMediaDraft.h"
#import "LVExporterVideoData.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: - 导出配置
@interface LVExporterConfig: NSObject

// 导出分辨率，6s机子以上是1080，以下是720。
@property (nonatomic, assign) LVExportResolution resolution;

// 写进视频的metaData
// 对应字段名为：com.apple.quicktime.description
@property (nonatomic, copy) NSString *metadataString;

// set metadatastring to artwork space
// 对应字段名为：com.apple.quicktime.artwork
@property (nonatomic, copy) NSString *artworkMetadataJsonString;

// unit: bit/s
@property (nonatomic, assign) int bitrate;

// bitrateSetting change，high priority
@property (nonatomic, copy, nullable) NSString *bitrateSetting;


+ (LVExportResolution)supportResolutionForCurrentDevice;

@end


// MARK: - 视频导出类：更纯粹的导出接口。
@interface LVExporterManager : NSObject

- (instancetype)initWithExportData:(LVExporterVideoData *)exportData config:(LVExporterConfig *)config;

- (void)getPreviewImage:(void (^)(UIImage *_Nullable image, NSTimeInterval atTime))compeletion;

- (void)startExportWithProgressBlock:(void (^_Nullable)(CGFloat progress))progressBlock
                 completeBlock:(compileCompleteBlock)completeBlock;

- (void)cancelTranscode:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
