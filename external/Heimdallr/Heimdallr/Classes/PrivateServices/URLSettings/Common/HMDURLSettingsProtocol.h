//
//  HMDURLSettingsProtocol.h
//  Pods
//
//  Created by Nickyo on 2023/8/1.
//

#ifndef HMDURLSettingsProtocol_h
#define HMDURLSettingsProtocol_h

#import <Foundation/Foundation.h>

@protocol HMDURLHostSettings <NSObject>

@required

+ (NSArray<NSString *> * _Nullable)defaultHosts;

+ (NSArray<NSString *> * _Nullable)configFetchDefaultHosts;

@end

#endif /* HMDURLSettingsProtocol_h */
