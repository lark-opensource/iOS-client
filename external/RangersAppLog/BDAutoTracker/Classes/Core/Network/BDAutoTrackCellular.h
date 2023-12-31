//
//  BDAutoTrackCellular.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/26.
//

#if TARGET_OS_IOS

#import <Foundation/Foundation.h>
#import "BDAutoTrackEnviroment.h"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const BDAutoTrackRadioAccessTechnologyDidChangeNotification;

@interface BDAutoTrackCellular : NSObject

+ (instancetype)sharedInstance;

- (id)carrier;

- (BDAutoTrackConnectionType)connectionType;

@end


NS_ASSUME_NONNULL_END

#endif
