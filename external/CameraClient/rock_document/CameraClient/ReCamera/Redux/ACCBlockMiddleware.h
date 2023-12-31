//
//  ACCBlockMiddleware.h
//  CameraClient
//
//  Created by leo on 2019/12/19.
//

#import <Foundation/Foundation.h>

#import "ACCMiddleware.h"



NS_ASSUME_NONNULL_BEGIN

@interface ACCBlockMiddleware : ACCMiddleware
@property (nonatomic, copy) ACCActionHandler handler;
@end

NS_ASSUME_NONNULL_END
