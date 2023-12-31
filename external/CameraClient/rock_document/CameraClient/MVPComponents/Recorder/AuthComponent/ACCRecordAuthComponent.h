//
//  ACCRecordAuthComponent.h
//  Pods
//
//  Created by songxiangwu on 2019/8/1.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordAuthComponent : ACCFeatureComponent

@property (nonatomic, copy, nullable) dispatch_block_t closeActionBlock;

- (void)checkAuthority;
- (void)hideAuthorityView;

@end

NS_ASSUME_NONNULL_END
