//
//  ACCEffectDownloadParam.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/27.
//

#import <Mantle/MTLModel.h>
#import <Mantle/MTLJSONAdapter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEffectDownloadParam : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) BOOL needUpzip;

@property (nonatomic, copy) NSArray<NSString *> *urlList;

@end

NS_ASSUME_NONNULL_END
