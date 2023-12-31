//
//  BDXAudioModel.h
//  BDXElement-Pods-Aweme
//
//  Created by DylanYang on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import <TTVideoEngine/TTVideoEngineModel.h>
#import <TTVideoEngine/TTVideoEngineModelDef.h>

typedef NS_ENUM(NSUInteger, BDXAudioPlayerEncryptType) {
    BDXAudioPlayerEncryptTypeModel = 1
};


NS_ASSUME_NONNULL_BEGIN

@interface BDXAudioVideoModel : NSObject
@property (nonatomic, assign) BDXAudioPlayerEncryptType encryptType;
@property (nonatomic, assign) TTVideoEngineResolutionType quality;
@property (nonatomic, strong) TTVideoEngineModel* videoEngineModel;

- (instancetype)initWithJSONDict:(NSDictionary *)jsonDict;
@end

@interface BDXAudioModel : NSObject
@property (nonatomic, copy) NSString *modelId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *albumTitle;
@property (nonatomic, assign) double playbackDuration;
@property (nonatomic, copy) NSString *albumCoverUrl;
@property (nonatomic, copy) NSString *playUrl;
@property (nonatomic, copy, nullable) NSString *localUrl;
@property (nonatomic, assign) BOOL canBackgroundPlay;
@property (nonatomic, strong) NSArray<NSString *>* localPath;
@property (nonatomic, strong) NSDictionary *eventData;
@property (nonatomic, assign) NSInteger playActionTimes;
@property (nonatomic, strong) BDXAudioVideoModel* playModel;

- (instancetype)initWithJSONDict:(NSDictionary *)jsonDict;
- (BOOL)isVerified;
@end

NS_ASSUME_NONNULL_END
