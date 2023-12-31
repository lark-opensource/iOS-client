//
//  AWEVideoPublishDraftTempProductModel.h
//  CameraClient
//
//  Created by geekxing on 2020/2/25.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

/// persist temporary product in publish draft folder
@interface AWEVideoPublishDraftTempProductModel : MTLModel

@property (nonatomic, copy) NSString *publishTaskId;
@property (nonatomic, copy, nullable) NSURL *uploadMediaURL; ///< upload fileURL in (compose stage). set to new value will trigger old file deletion operation
@property (nonatomic, copy, nullable) NSURL *watermarkVideoURL; ///< watermark fileURL in (watermark stage). set to new value will trigger old file deletion operation

// storage persistance
- (void)synchronize;
- (void)destroy;

+ (instancetype)restoreWithTaskId:(NSString *)taskID;
+ (void)destroyWithTaskId:(NSString *)taskID;
@end

NS_ASSUME_NONNULL_END
