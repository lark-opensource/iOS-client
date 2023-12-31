//
//  ACCMonitorToolMsgProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/8/16.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMonitorToolMsgProtocol <NSObject>

@property (nonatomic, strong, readonly) NSArray *messageList;
- (void)showAlertIfNeeded;
- (void)removeAllMessages;

@end

FOUNDATION_STATIC_INLINE id<ACCMonitorToolMsgProtocol> ACCMonitorMsgTool() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCMonitorToolMsgProtocol)];
}

NS_ASSUME_NONNULL_END
