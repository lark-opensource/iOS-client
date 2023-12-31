//
//  HTSAppPlugin.h
//  HTSServiceKit
//
//  Created by Huangwenchen on 2020/3/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,HTSPluginPosition){
    HTSPluginPositionBegin,
    HTSPluginPositionEnd
};

@protocol HTSAppEventPlugin <NSObject>

@optional

- (void)applicationLifeCycleTask:(NSString*)taskIdentifier pluginPosition:(HTSPluginPosition)position;

//May invoke on background thread
- (void)applicationExecuteBootTask:(NSString*)taskName pluginPosition:(HTSPluginPosition)position;

@end


NS_ASSUME_NONNULL_END
