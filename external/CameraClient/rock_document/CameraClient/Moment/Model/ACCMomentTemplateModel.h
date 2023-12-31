//
//  ACCMomentTemplateModel.h
//  Pods
//
//  Created by Pinka on 2020/6/1.
//

#import <Mantle/Mantle.h>
#import "ACCMomentMaterialSegInfo.h"

typedef NS_ENUM(NSInteger, ACCMomentTemplateType) {
    ACCMomentTemplateType_Classic,
    ACCMomentTemplateType_CutSame
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentTemplateModel : MTLModel

@property (nonatomic, assign) NSUInteger templateId;

@property (nonatomic, assign) ACCMomentTemplateType templateType;

@property (nonatomic, copy  ) NSArray<ACCMomentMaterialSegInfo *> *segInfos;

@end

NS_ASSUME_NONNULL_END
