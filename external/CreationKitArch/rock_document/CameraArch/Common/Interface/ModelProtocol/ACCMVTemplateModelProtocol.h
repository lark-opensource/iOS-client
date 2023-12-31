//
//  ACCMVTemplateModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/12/31.
//

#ifndef ACCMVTemplateModelProtocol_h
#define ACCMVTemplateModelProtocol_h

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import "ACCCutSameTemplateModelProtocol.h"
#import "ACCUserModelProtocol.h"
#import "ACCMusicModelProtocol.h"
#import "ACCVideoModelProtocol.h"

typedef NS_ENUM(NSInteger, ACCMVTemplateType) {
    ACCMVTemplateTypeUnknow = -1,
    ACCMVTemplateTypeClassic,
    ACCMVTemplateTypeCutSame,
    ACCMVTemplateTypeUseOrigin
};

@class IESEffectModel;

@protocol ACCMVTemplateModelProtocol <NSObject>

@property (nonatomic, assign) NSUInteger templateID;
@property (nonatomic, strong) id<ACCUserModelProtocol> author;
@property (nonatomic, strong) id<ACCMusicModelProtocol> music;
@property (nonatomic, strong) id<ACCVideoModelProtocol> video;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *templateURL;
@property (nonatomic, assign) NSUInteger fragmentCount;
@property (nonatomic, assign) NSUInteger usageAmount;
@property (nonatomic, assign) BOOL isCollected;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *md5;
@property (nonatomic, strong) id<ACCCutSameTemplateModelProtocol> extraModel;
@property (nonatomic, copy) NSArray<NSString *> *challengeIDs;

// not from server
@property (nonatomic, strong) IESEffectModel *effectModel;
@property (nonatomic, assign, readonly) ACCMVTemplateType accTemplateType;
@property (nonatomic, copy) NSArray<NSString *> *templateCoverURL;
@property (nonatomic, copy) NSArray<NSString *> *templateDynamicCoverURL;
@property (nonatomic, copy) NSArray<NSString *> *templateVideoURL;
@property (nonatomic, copy) NSString *hintLabel;


@end

#endif /* ACCMVTemplateModelProtocol_h */
