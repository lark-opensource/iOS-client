//
//  HTSMessageHash.h
//  HTSServiceKit
//

#import <Foundation/Foundation.h>

@interface HTSMessageHash : NSObject

- (void)registerMessage:(id)oObserver forKey:(id)nsKey;
- (void)unregisterMessage:(id)oObserver forKey:(id)nsKey;
- (void)unregisterKeyMessage:(id)oObserver;
- (NSArray *)getKeyMessageList:(id)nsKey;

@end
