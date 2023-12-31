//
//  ACCRepoCutSameModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/23.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEAssetModel;

@interface ACCRepoCutSameModel : NSObject <NSCopying, ACCRepositoryContextProtocol>

@property (nonatomic, copy, nullable) NSArray<NSString *> *cutSameEditedTexts; // for audit
@property (nonatomic, assign) ACCMVTemplateType accTemplateType; // classical mv or cut same mv
@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> templateModel;
@property (nonatomic, copy) NSString *cutSameMusicID; /// Cut same template music id

- (BOOL)isClassicalMV;

@end

@interface AWEVideoPublishViewModel (RepoCutSame)
 
@property (nonatomic, strong, readonly) ACCRepoCutSameModel *repoCutSame;
 
@end

NS_ASSUME_NONNULL_END
