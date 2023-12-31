//
//  AWEComposerEffectProtocol.h
//  Pods
//
// Created by Lai Xiaobing on August 15, 2019
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectResourceResponseModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEComposerEffectProtocol <NSObject>

@property (nonatomic, readonly, copy) NSArray<NSString *> *filePaths;
@property (nonatomic, readonly, copy) NSArray<NSString *> *iconURLs;
@property (nonatomic, readonly, copy) NSString *idMap;
@property (nonatomic, readonly, copy) NSString *effectId;
@property (nonatomic, readonly, strong) IESEffectResourceResponseModel *response;

@end

NS_ASSUME_NONNULL_END
