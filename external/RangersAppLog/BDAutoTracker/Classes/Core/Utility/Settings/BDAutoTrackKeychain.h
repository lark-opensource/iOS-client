//
//  BDAutoTrackKeychain.h
//  Applog
//
//  Created by bob on 2019/1/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN BOOL bd_keychain_save(NSString *key, NSString *_Nullable value);
FOUNDATION_EXTERN BOOL bd_keychain_delete(NSString *key);
FOUNDATION_EXTERN NSString *_Nullable bd_keychain_load(NSString *key);

NS_ASSUME_NONNULL_END
