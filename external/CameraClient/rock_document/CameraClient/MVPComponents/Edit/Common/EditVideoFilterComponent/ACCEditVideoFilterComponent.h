//
//  ACCEditVideoFilterComponent.h
//  AWEStudio-Pods-Aweme
//
//  Created by 郝一鹏 on 2019/10/20.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>
#import "ACCDraftResourceRecoverProtocol.h"
#import "ACCEditVideoFilterService.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditVideoFilterComponent : ACCFeatureComponent<ACCDraftResourceRecoverProtocol>

@property (nonatomic, strong, readonly) ACCEditVideoFilterServiceImpl *filterService;

@end

NS_ASSUME_NONNULL_END
