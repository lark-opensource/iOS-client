//
//  BytedCertVideoRecordParameter.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/18.
//

#import "BytedCertParameter.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertVideoRecordParameter : BytedCertParameter

@property (nonatomic, copy, nullable) NSString *readText;
@property (nonatomic, assign) NSInteger msPerWord;
@property (nonatomic, assign) BOOL skipFaceDetect;
@property (nonatomic, copy, nullable) NSString *faceEnvBase64;

- (double)totalReadDurationInSeconds;

@end

NS_ASSUME_NONNULL_END
