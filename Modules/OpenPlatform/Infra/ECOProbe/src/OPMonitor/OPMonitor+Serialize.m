//
//  OPMonitor+Serialize.m
//  ECOProbe
//
//  Created by qsc on 2021/3/31.
//

#import "OPMonitor+Serialize.h"
#import <ECOProbe/ECOProbe-Swift.h>

@implementation OPMonitorEvent(Serialize)

- ( NSString * _Nullable ) serialize {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:self.name forKey:OPMonitorSerializeKeys.key_event_name];
    [dict setValue:self.categories forKey:OPMonitorSerializeKeys.key_categories];
    [dict setValue:self.metrics forKey:OPMonitorSerializeKeys.key_metrics];

    if ([NSJSONSerialization isValidJSONObject:dict]) {
        NSError *serializeError;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&serializeError];
        if(serializeError) {
            OPLogError(@"serialize monitor error! %@", serializeError);
        }
        
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        NSAssert(NO, @"monitor serialize error! not a valid json!");
        OPLogError(@"serialize monitor error! not a valid json");
    }
    return nil;
}

@end
