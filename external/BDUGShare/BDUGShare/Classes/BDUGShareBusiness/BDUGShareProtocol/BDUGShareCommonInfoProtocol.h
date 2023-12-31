//
//  BDUGCommonInfoProtocol.h
//  Pods
//
//  Created by 杨阳 on 2019/3/28.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDUGShareCommonInfoProtocol <NSObject>

- (void)activityWillSharedWith:(id<BDUGActivityProtocol>)activity;

- (void)activityHasSharedWith:(id<BDUGActivityProtocol>)activity error:(NSError * _Nullable)error desc:(NSString * _Nullable)desc;

@end

NS_ASSUME_NONNULL_END
