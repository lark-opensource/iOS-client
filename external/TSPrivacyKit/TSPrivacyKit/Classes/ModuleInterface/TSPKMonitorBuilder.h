//
//  TSPKMonitorBuilder.h
//  Musically
//
//  Created by ByteDance on 2022/11/18.
//

typedef void(^TSPKSubscriberSetup)(void);

#import <Foundation/Foundation.h>

@interface TSPKMonitorBuilder : NSObject

/// Allow host to setup subscribers as demand.
@property (nonatomic, copy, nullable) TSPKSubscriberSetup setupSubscribers;

@end
