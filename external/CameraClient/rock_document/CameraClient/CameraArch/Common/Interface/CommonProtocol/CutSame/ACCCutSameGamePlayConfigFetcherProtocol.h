//
//  ACCCutSameGamePlayConfigFetcherProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCCutSameGamePlayOutputType) {
    ACCCutSameGamePlayOutputTypePhoto,
    ACCCutSameGamePlayOutputTypeVideo,
};

@protocol ACCCutSameGamePlayConfigProtocol <NSObject>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *algorithm;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSArray<NSString *> *resourceTypes;
@property (nonatomic, assign) ACCCutSameGamePlayOutputType outputType;
@property (nonatomic, copy) NSString *config;
@property (nonatomic, assign) BOOL isReshape;
@property (nonatomic, copy) NSString *videoResourceID;

@end

@protocol ACCCutSameGamePlayConfigFetcherProtocol <NSObject>

@required

- (NSDictionary *)reshapeConfig;

- (id<ACCCutSameGamePlayConfigProtocol >)getGameplayConfigWithAlgorithm:(NSString *)algorithm;


@end

NS_ASSUME_NONNULL_END
