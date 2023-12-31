//
//  ACCFilterEffectItem.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/9/11.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCFilterEffectItem : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) float maxPercent;
@property (nonatomic, assign) float minPercent;
@property (nonatomic, assign) float defaultPercent;
@property (nonatomic, assign, readonly) float defaultIntensity;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
