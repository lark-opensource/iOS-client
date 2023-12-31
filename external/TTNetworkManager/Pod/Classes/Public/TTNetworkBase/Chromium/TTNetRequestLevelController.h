//
//  TTNetRequestLevelController.h
//  TTNetworkManager
//
//  Created by liuzhe on 2021/9/2.
//

#import <Foundation/Foundation.h>

@class TTHttpTask;

NS_ASSUME_NONNULL_BEGIN

@interface TTNetRequestLevelController : NSObject

#ifndef DISABLE_REQ_LEVEL_CTRL

/*! @brief TTNetRequestLevelController singleton */
+(instancetype)shareInstance;

/*! @brief TTNetRequestLevelController start working */
-(void)start;

/*! @brief stop TTNetRequestLevelController working */
-(void)stop;

#endif

@end

NS_ASSUME_NONNULL_END
