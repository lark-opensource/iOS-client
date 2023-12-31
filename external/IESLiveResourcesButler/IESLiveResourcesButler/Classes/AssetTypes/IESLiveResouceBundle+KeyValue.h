//
//  IESLiveResouceBundle+KeyValue.h
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle.h"

@interface IESLiveResouceBundle (KeyValue)

- (id (^)(NSString *key))value;
- (id (^)(NSString *key))config;
- (BOOL (^)(NSString *key))is;

@end
