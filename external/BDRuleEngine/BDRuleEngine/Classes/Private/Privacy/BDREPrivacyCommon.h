//
//  BDREPrivacyCommon.h
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/6/27.
//

#import <Foundation/Foundation.h>

@interface BDREPrivacyCommon : NSObject

+ (void)registerExtension;

+ (void)appWillEnterForeground;

+ (void)appDidEnterBackground;

@end
