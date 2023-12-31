//
//  ACCBeautyDataService.h
//  CameraClient
//
//  Created by machao on 2021/5/24.
//

#ifndef ACCBeautyDataService_h
#define ACCBeautyDataService_h

#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>

@protocol ACCBeautyDataService <NSObject>

@property (nonatomic, copy, readonly) NSString *enterFrom;

@property (nonatomic, assign) NSInteger gender;

@property (nonatomic, assign, readonly) ACCGameType gameType;

- (NSDictionary *)referExtra;

@end

#endif /* ACCBeautyDataService_h */
