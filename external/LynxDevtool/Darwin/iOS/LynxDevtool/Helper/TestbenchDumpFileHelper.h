// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestbenchDumpFileHelper : NSObject
+ (NSString*)getViewTree:(nonnull UIView*)rootView;
+ (NSString*)getUITree:(nonnull LynxUI*)rootUI;
@end

NS_ASSUME_NONNULL_END
