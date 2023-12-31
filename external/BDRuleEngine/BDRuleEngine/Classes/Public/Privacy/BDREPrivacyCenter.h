//
//  BDRuleEnginePrivacyCenter.h
//  BDAlogProtocol
//
//  Created by Chengmin Zhang on 2022/6/27.
//

#import <Foundation/Foundation.h>

@interface BDREPrivacyCenter : NSObject

+ (void)registerExtensions;

+ (void)appWillEnterForeground;

+ (void)appDidEnterBackground;

@end
