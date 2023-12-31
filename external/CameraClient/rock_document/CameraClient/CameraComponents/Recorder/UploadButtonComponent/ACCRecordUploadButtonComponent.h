//
//  ACCRecordUploadButtonComponent.h
//  Pods
//
//  Created by songxiangwu on 2019/7/30.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>


NS_ASSUME_NONNULL_BEGIN

@class ACCGroupedPredicate;

@interface ACCRecordUploadButtonComponent : ACCFeatureComponent

@property (nonatomic, strong, nonnull) ACCGroupedPredicate *hideUploadButtonPredicate;

@end

NS_ASSUME_NONNULL_END
