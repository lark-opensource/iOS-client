//
//  ACCMusicTransModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Zhihao Zhang on 2021/2/28.
//

#import <Foundation/Foundation.h>

#import <CreationKitArch/ACCURLModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicTransModelProtocol <NSObject>

- (Class)musicModelImplClass;

- (Class)bannerModelImplClass;

- (Class)urlModelImplClass;

@end



@protocol ACCBanneraAdDataModelProtocol <NSObject>
@property (nonatomic, strong) NSNumber *creativeID;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *logExtra;
@end



@protocol ACCBannerModelProtocol <NSObject>
@property (nonatomic, strong) NSString *bannerID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) id<ACCURLModelProtocol> bannerURL;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSString *schema;
@property (nonatomic, copy)   id<ACCBanneraAdDataModelProtocol> adData;
@end


NS_ASSUME_NONNULL_END
