//
//  LVModulesLaunchExport.h
//  Pods
//
//  Created by kevin gao on 11/3/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LVModulesLaunchDraft;

@protocol LVModulesLaunchExportDelegate <NSObject>

- (BOOL)exportDraft:(LVModulesLaunchDraft* _Nullable)draft confirm:(BOOL)writeToDisk;

@end

@interface LVModulesLaunchExport : NSObject <LVModulesLaunchExportDelegate>

@end

NS_ASSUME_NONNULL_END
