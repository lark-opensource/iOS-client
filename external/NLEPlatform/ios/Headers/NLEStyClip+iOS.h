//
//  NLEStyClip+iOS.h
//  NLEPlatform
//
//  Created by pengzhenhuan on 2021/12/5.
//
#import <Foundation/Foundation.h>
#import "NLENode+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEStyClip_OC : NLENode_OC

@property (nonatomic, assign) CGPoint leftUpper;
@property (nonatomic, assign) CGPoint rightUpper;
@property (nonatomic, assign) CGPoint leftLower;
@property (nonatomic, assign) CGPoint rightLower;

@end

NS_ASSUME_NONNULL_END
