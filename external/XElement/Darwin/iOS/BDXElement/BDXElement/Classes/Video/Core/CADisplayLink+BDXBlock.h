//
//  CADisplayLink+BDXBlock.h
//  BDXElement
//
//  Created by bill on 2020/3/24.
//

#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CADisplayLink (BDXBlock)

+ (CADisplayLink *)isBDX_displayLinkWithBlock:(void (^)(CADisplayLink *dispLink))block;

@end
