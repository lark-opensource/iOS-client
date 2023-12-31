//
//  TSPKUploadEvent.m
//  Indexer
//
//  Created by admin on 2021/12/16.
//

#import "TSPKUploadEvent.h"

NSString * const TSPKEventTagBadcase = @"Badcase";

@implementation TSPKUploadEvent

- (NSString *)tag {
    return TSPKEventTagBadcase;
}

- (void)addExtraFilterParams:(NSArray *)array {
    if (self.filterParams == nil) {
        self.filterParams = [NSMutableDictionary dictionary];
    }
    [array enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] && self.params[key] != nil) {
            self.filterParams[key] = self.params[key];
        }
    }];
}

- (BOOL)uploadALogNeedDelay {
    // when events upload with delay, no need to delay alog upload
    return self.uploadDelay == 0;
}

@end
