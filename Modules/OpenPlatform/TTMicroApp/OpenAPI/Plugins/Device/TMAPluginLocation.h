//
//  TTMicroAppLocation.h
//  Timor
//
//  Created by muhuai on 2017/11/29.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPPluginBase.h"

FOUNDATION_EXPORT NSString* const  kAccuracyAuthorzationFull;
FOUNDATION_EXPORT NSString* const  kAccuracyAuthorzationReduced;

@interface TMAPluginLocation : BDPPluginBase

BDP_HANDLER(getLocation)

@end
