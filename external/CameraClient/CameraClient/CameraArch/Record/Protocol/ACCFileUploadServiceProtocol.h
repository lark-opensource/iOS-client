//
//  ACCFileUploadServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by qiyang on 2020/12/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCFileUploadResponseInfoModel;

typedef void(^ACCFileUploadCompletion)(ACCFileUploadResponseInfoModel * _Nullable uploadInfoModel, NSError * _Nullable error);
typedef void(^ACCFileUploadProgressCallback)(CGFloat progress);

@protocol ACCFileUploadServiceProtocol <NSObject>

@property(nonatomic, assign) BOOL isUploading;
@property(nonatomic,   copy) ACCFileUploadProgressCallback progressCallback;
@property(nonatomic, strong) id context;

- (void)stopUploading;
- (void)uploadFileWithProgress:(NSProgress * __autoreleasing *)progress
                    completion:(ACCFileUploadCompletion)completion;
- (void)configActivityFlag;

@end

NS_ASSUME_NONNULL_END
