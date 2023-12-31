//
//  TSPKStore.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/22.
//

#import <Foundation/Foundation.h>



@class TSPKEventData;

@protocol TSPKStore <NSObject>

- (void)saveEventData:(TSPKEventData *_Nonnull)eventData completion:(void (^ __nullable)(NSError *_Nullable))completion;

- (void)getStoreDataWithCompletion:(void (^ __nullable)(NSDictionary *_Nonnull))completion;

- (void)getStoreDataWithInstanceAddress:(nullable NSString *)instanceAddress completion:(void (^ __nullable)(NSDictionary *_Nonnull))completion;

@end


