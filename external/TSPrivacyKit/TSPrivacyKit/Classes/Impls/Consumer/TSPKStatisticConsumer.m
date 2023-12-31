//
//  TSPKStatisticConsumer.m
//  Indexer
//
//  Created by admin on 2022/2/14.
//

#import "TSPKStatisticConsumer.h"
#import "TSPKStatisticEvent.h"
#import "TSPKLogger.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSMonitorProtocol.h>

@implementation TSPKStatisticConsumer

- (NSString *)tag {
    return TSPKEventTagStatistic;
}

- (void)consume:(TSPKBaseEvent *)event {
    if (![event isKindOfClass:[TSPKStatisticEvent class]]) return;
    TSPKStatisticEvent *statisticEvent = (TSPKStatisticEvent *)event;
    
    [PNS_GET_INSTANCE(PNSMonitorProtocol) trackService:statisticEvent.serviceName
                                                metric:statisticEvent.metric
                                              category:statisticEvent.category
                                            attributes:statisticEvent.attributes];
}

@end
