//
//  BDTNetworkTagManager+Implementation.m
//  BDTuring
//
//  Created by bob on 2021/8/4.
//

#import "BDTNetworkManager+Tag.h"
#import <BDNetworkTag/BDNetworkTagManager.h>

@implementation BDTNetworkManager (Tag)

- (NSDictionary *)createTaggedHeaderFieldWith:(NSDictionary *)headerField type:(BDTNetworkTagType)type{
    
    NSMutableDictionary *finalHeaderField = [NSMutableDictionary dictionary];
    NSDictionary *taggedInfo = nil;
    switch (type) {
        case BDTNetworkTagTypeAuto:
            taggedInfo = [BDNetworkTagManager autoTriggerTagInfo];
            break;
        case BDTNetworkTagTypeManual:
            taggedInfo = [BDNetworkTagManager manualTriggerTagInfo];
            break;
    }
    [finalHeaderField addEntriesFromDictionary:headerField];
    if (taggedInfo != nil) {
        [finalHeaderField addEntriesFromDictionary:taggedInfo];
    }

    return [finalHeaderField copy];
}


@end
