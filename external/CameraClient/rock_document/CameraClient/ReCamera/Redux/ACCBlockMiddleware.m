//
//  ACCBlockMiddleware.m
//  CameraClient
//
//  Created by leo on 2019/12/19.
//

#import "ACCBlockMiddleware.h"
@implementation ACCBlockMiddleware
- (ACCAction *)handleAction:(ACCAction *)action next:(nonnull ACCActionHandler)next
{
    if (_handler) {
        return next(_handler(action));
    } else {
        return next(action);
    }
}
@end
