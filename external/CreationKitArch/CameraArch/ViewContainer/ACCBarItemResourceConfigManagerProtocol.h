//
//  ACCBarItemResourceConfigManagerProtocol.h
//  Pods
//
//  Created by liyingpeng on 2020/6/28.
//

#ifndef ACCBarItemResourceConfigManagerProtocol_h
#define ACCBarItemResourceConfigManagerProtocol_h

#import <CreativeKit/ACCBarItem.h>

@protocol ACCBarItemResourceConfigManagerProtocol <NSObject>

- (NSArray<ACCBarItem *> *)allowListInPureMode;

- (ACCBarItemResourceConfig *)configForIdentifier:(void *)itemId;

@end

#endif /* ACCBarItemResourceConfigManagerProtocol_h */
