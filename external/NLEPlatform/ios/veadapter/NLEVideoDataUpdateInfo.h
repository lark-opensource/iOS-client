//
//  NLEVideoDataUpdateInfo.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/5/27.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <TTVideoEditor/HTSVideoData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEVideoDataUpdateInfo : NSObject

@property (nonatomic, assign) VEVideoDataUpdateType updateType;
@property (nonatomic, copy) NSString *tag;

- (instancetype)initWithUpdate:(VEVideoDataUpdateType)updateType;

@end

NS_ASSUME_NONNULL_END
