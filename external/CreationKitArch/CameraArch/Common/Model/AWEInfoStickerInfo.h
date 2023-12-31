//
//  AWEInfoStickerInfo.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/3/30.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEInfoStickerInfo : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *stickerID;
@property (nonatomic, copy) NSString *challengeID;
@property (nonatomic, copy) NSString *challengeName;

@end

NS_ASSUME_NONNULL_END
