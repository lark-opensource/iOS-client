//
//  TMAAtDataBackedString.h
//  OPPluginBiz
//
//  Created by houjihu on 2018/9/5.
//

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const TMAAtDataBackedStringAttributeName;

@interface TMAAtDataBackedString : NSObject

@property (nonatomic, copy) NSString *string;
@property (nonatomic, copy) NSString *larkID;
@property (nonatomic, copy) NSString *openID;
@property (nonatomic, copy) NSString *userName;

+ (nullable instancetype)stringWithString:(nullable NSString *)string larkID:(nullable NSString *)larkID openID:(nullable NSString *)openID userName:(NSString *)userName;

@end
