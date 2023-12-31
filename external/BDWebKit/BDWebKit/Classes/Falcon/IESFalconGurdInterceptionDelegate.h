//
//  IESFalconGurdInterceptionDelegate.h
//  IESWebKit
//
//  Created by 陈煜钏 on 2019/12/31.
//

#ifndef IESFalconGurdInterceptionDelegate_h
#define IESFalconGurdInterceptionDelegate_h

@class IESFalconStatModel;
@protocol IESFalconGurdInterceptionDelegate <NSObject>

@optional
- (void)falconInterceptedRequest:(NSURLRequest *)request
               willLoadFromCache:(BOOL)fromCache
                       statModel:(IESFalconStatModel *)statModel;

@end

#endif /* IESFalconGurdInterceptionDelegate_h */
