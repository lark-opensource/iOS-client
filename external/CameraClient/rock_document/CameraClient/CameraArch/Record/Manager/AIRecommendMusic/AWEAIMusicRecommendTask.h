//
//  AWEAIMusicRecommendTask.h
//  AWEStudio
//
//  Created by Bytedance on 2019/1/17.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import "AWEEditAlgorithmManager.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@protocol ACCMusicModelProtocol;

typedef NS_ENUM(NSUInteger, AWEAIMusicFetchType) {
    AWEAIMusicFetchTypeNone,       // 未获取到数据
    AWEAIMusicFetchTypeSettings,   // settings 兜底数据
    AWEAIMusicFetchTypeAI,         // 从 AI Lab 拿的
    AWEAIMusicFetchTypeLib         // 从曲库拿的
};

typedef void (^AWEAIMusicRecommendTaskCompletion)(NSString *_Nullable zipURI,
                                                  AWEAIRecommendStrategy recommendStrategyType,
                                                  NSString *_Nullable firstFrameURI,
                                                  NSArray<UIImage *> *_Nullable frameImageInZipArray,
                                                  NSError * _Nullable error);

typedef void (^AWEAIMusicRecommendTaskFetchCompletion)(AWEAIMusicFetchType fetchType,
                                                       NSString * _Nullable requestID,
                                                       NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList,
                                                       NSNumber *hasMore,
                                                       NSNumber *cursor,
                                                       NSError * _Nullable error);


@interface AWEAIMusicRecommendTask : NSObject

@property(nonatomic, readonly) NSString *taskIdentifier;
@property(nonatomic, copy, nullable) NSArray<NSString *> *originFramesPathArray;

- (instancetype)initWithIdentifier:(nonnull NSString *)taskIdentifier
                      publishModel:(nullable AWEVideoPublishViewModel *)model
                  recordFramePaths:(nullable NSArray<NSArray *> *)frames
                             count:(NSInteger)count
                          callback:(nullable AWEAIMusicRecommendTaskCompletion)completion;

- (void)resume; // only fetch zip_uri

- (void)fetchAIMusicListWithURI:(NSString *)zipURI otherParam:(nullable NSDictionary *)param callback:(AWEAIMusicRecommendTaskFetchCompletion)completion;

#pragma mark - public class methods

+ (BOOL)shootTypeSupportWithModel:(nullable AWEVideoPublishViewModel *)model;

+ (BOOL)shootTypeSupportWithReferString:(nullable NSString *)referString;

+ (NSError *)errorOfAIRecommend;

@end

NS_ASSUME_NONNULL_END
