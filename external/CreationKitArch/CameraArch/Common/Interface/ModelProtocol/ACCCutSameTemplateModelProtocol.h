//
//  ACCCutSameTemplateModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/1/2.
//

#ifndef ACCCutSameTemplateModelProtocol_h
#define ACCCutSameTemplateModelProtocol_h

#import "ACCCutSameFragmentModelProtocol.h"

@protocol ACCCutSameTemplateModelProtocol <NSObject>

@property (nonatomic, copy) NSArray<id<ACCCutSameFragmentModelProtocol>> *fragments;

@property (nonatomic, copy) NSString *alignMode;

@end

#endif /* ACCCutSameTemplateModelProtocol_h */
