//
//  Header.h
//  Pods
//
//  Created by moqianqian on 2020/4/28.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface UUIDKeychainHelper : NSObject

@property (nonatomic, copy)NSString *service;
@property (nonatomic, copy)NSString *account;

typedef void(^KeychainComletionBlock)(NSError *error, NSString *result);

typedef NS_ENUM(NSUInteger, otherErrors) {
    queryResultError = 0,
};


- (instancetype)initWithSevice:(NSString *)service account :(NSString *)account;

- (BOOL)saveItem:(NSString *)password;

- (BOOL)updateItem:(NSString *)newPassword;

- (BOOL)deleteItem;

- (NSString *)readItem;

- (void) readItemWithComletion: (KeychainComletionBlock)completion;

@end
