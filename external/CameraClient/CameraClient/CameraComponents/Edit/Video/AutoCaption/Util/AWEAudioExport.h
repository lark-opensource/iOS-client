//
//  AWEAudioExport.h
//  AWEStudio
//
//  Created by liubing on 2018/7/6.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEVideoPublishResponseModel.h>
#import "ACCEditVideoData.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ExportCompletion)(NSURL * _Nonnull url, NSError * _Nonnull error, AVAssetExportSessionStatus status);

@interface AWEAudioExport : NSObject

+ (void)extractAudioAndUploadFromVideoData:(ACCEditVideoData * _Nullable)videoData
                              publishModel:(AWEVideoPublishViewModel * _Nullable)publishModel
                                isOriSound:(BOOL)enable
                               awemeItemId:(NSString * _Nullable)awemeId
                          uploadParameters:(AWEResourceUploadParametersResponseModel * _Nullable)uploadParameters
                                completion:(dispatch_block_t _Nullable)completion;

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel * _Nullable)publishModel;

- (void)exportAudioWithCompletion:(ExportCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
