//
//  ACCGradientView.m
//  Aweme
//
//  Created by Liu Bing on 3/24/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "ACCGradientView.h"

@implementation ACCGradientView

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (CAGradientLayer *)gradientLayer
{
    return (CAGradientLayer *)self.layer;
}

@end
