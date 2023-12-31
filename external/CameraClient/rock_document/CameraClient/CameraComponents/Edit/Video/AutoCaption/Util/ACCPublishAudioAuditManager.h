//
//  ACCPublishAudioAuditManager.h
//  AWEStudio-Pods-Aweme
//
//  Created by hellaflush on 2020/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AWEAudioAuditStage) {
    AWEAudioAuditStageFileCheck,
    AWEAudioAuditStageExtract,
    AWEAudioAuditStageRequestUploadParams,
    AWEAudioAuditStageUpload,
    AWEAudioAuditStageTrack,
};

@interface ACCPublishAudioAuditTask: NSObject <NSCoding, NSCopying>
@property (nonatomic, strong) NSString *awemeId;
@property (nonatomic, assign) NSTimeInterval createTimeInterval;
@property (nonatomic, strong) NSString *audioFilePath;
@property (nonatomic, assign) BOOL useTmpPath;

@end

@interface ACCPublishAudioAuditManager : NSObject
/// use awemeId to match
@property (nonatomic, strong, readonly) NSMutableArray<ACCPublishAudioAuditTask *> *tasks;
+ (instancetype)sharedInstance;
- (void)addAudioAuditTask:(ACCPublishAudioAuditTask *)task;
- (void)removeAudioAuditTask:(ACCPublishAudioAuditTask *)task;
- (void)retryAuidtProcessIfNeeded;
@end

NS_ASSUME_NONNULL_END
