//
//  ACCMVTemplateMergedInfo.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2020/6/1.
//

#import <Mantle/Mantle.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMVTemplateMergedInfo : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSUInteger templateID;
@property (nonatomic, assign) ACCMVTemplateType type;

@end

NS_ASSUME_NONNULL_END
