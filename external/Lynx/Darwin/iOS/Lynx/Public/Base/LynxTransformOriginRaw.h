// Copyright 2021 The Lynx Authors. All rights reserved.
//
//  TransformOriginRaw.h
//  Lynx
//
//  Created by lybvinci on 2021/1/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxTransformOriginRaw : NSObject
@property(nonatomic, assign) float p0;
@property(nonatomic, assign) float p1;

- (bool)isValid;
- (bool)isP0Valid;
- (bool)isP1Valid;
- (bool)isP0Percent;
- (bool)isP1Percent;
- (bool)hasPercent;
- (bool)isDefault;

+ (LynxTransformOriginRaw*)convertToLynxTransformOriginRaw:(id)arr;
@end

NS_ASSUME_NONNULL_END
