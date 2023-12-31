//
//  ACCFilterDataService.h
//  CameraClient
//
//  Created by bytedance on 2021/5/20.
//

#ifndef ACCFilterDataService_h
#define ACCFilterDataService_h

#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>

@protocol ACCFilterDataService <NSObject>

- (NSDictionary *)referExtra;

- (AWERecordSourceFrom)recordSourceFrom;

- (void)setColorFilterIntensityRatio:(NSNumber *)colorFilterIntensityRatio;

- (NSString *)enterFrom;

- (NSString *)createId;

- (NSString *)referString;

- (AWEVideoType)videoType;

@end

#endif /* ACCFilterDataService_h */
