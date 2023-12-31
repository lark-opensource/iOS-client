//
//  Heimdallr+ManualControl.h
//  Heimdallr
//
//  Created by zhouyang11 on 2023/2/6.
//

#import "Heimdallr.h"

@interface Heimdallr (ManualControl)

/// Once mark a module as manual control before SDK setup, it won't be controlled by slardar platform, neither start nor stop. Be Careful!!!
/// If this method is called after SDK setup, the module may be started by the platform's configuration before calling this method. You can still control it manually.
/// - Parameter moduleName: sync module can not be marked as manual control,  more details contact HMD
- (void)markAsManualControl:(NSArray<NSString*>* _Nullable)moduleNames;

/// Must be invoked after SDK setup
- (void)manualStart:(NSString* _Nullable)moduleName;

/// Some module can not be stoped, more details contact HMD
- (void)manualStop:(NSString* _Nullable)moduleName;

@end

