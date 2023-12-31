//
//  NSObject+TSDeallocAssociate.m
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/13.
//

#import <objc/runtime.h>

#import "NSObject+TSDeallocAssociate.h"

const void *TS_DeallocAssociateKey = &TS_DeallocAssociateKey;
const void *TS_HashTagKey = &TS_HashTagKey;

@implementation NSObject (TSDeallocAssociate)

- (NSString *)ts_hashTag
{
    NSString *tag = objc_getAssociatedObject(self, TS_HashTagKey);
    if (!tag) {
        tag = [NSString stringWithFormat:@"%p", self];
        objc_setAssociatedObject(self, TS_HashTagKey, tag, OBJC_ASSOCIATION_RETAIN);
    }
    return tag;
}

- (NSMutableDictionary *)ts_deallocExecutors
{
    NSMutableDictionary *table = objc_getAssociatedObject(self, TS_DeallocAssociateKey);

    if (!table) {
        table = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, TS_DeallocAssociateKey, table, OBJC_ASSOCIATION_RETAIN);
    }

    return table;
}

- (void)ts_addDeallocAction:(TSDeallocBlock)block withKey:(NSString *)key
{
    if (block) {
        @synchronized (self) {
            NSMutableDictionary *table = [self ts_deallocExecutors];
            if (table[key] == nil) {
                table[key] = [[TSDeallocAssociate alloc] initWithBlock:block];
            }
        }
    }
}

@end