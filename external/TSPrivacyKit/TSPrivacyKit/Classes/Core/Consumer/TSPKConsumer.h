//
//  TSPKConsumer.h
//  MT-Test
//
//  Created by admin on 2021/12/7.
//

#import <Foundation/Foundation.h>
#import "TSPKBaseEvent.h"

@protocol TSPKConsumer <NSObject>

- (NSString *_Nonnull)tag;

- (void)consume:(TSPKBaseEvent *_Nullable)event;

@end
