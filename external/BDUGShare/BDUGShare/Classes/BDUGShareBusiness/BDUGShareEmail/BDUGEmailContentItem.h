//
//  BDUGEmailContentItem.h
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import <Foundation/Foundation.h>
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeEmail;

@interface BDUGEmailContentItem : BDUGShareBaseContentItem

@property (nonatomic, copy, nullable) NSArray<NSString *> *toRecipients;
@property (nonatomic, copy, nullable) NSArray<NSString *> *ccRecipients;
@property (nonatomic, copy, nullable) NSArray<NSString *> *bcRecipients;
@property (nonatomic, assign) BOOL isHTML;
@property (nonatomic, strong, nullable) NSData *attachment;
@property (nonatomic, copy, nullable) NSString *mimeType;
@property (nonatomic, copy, nullable) NSString *fileName;

@property (nonatomic, copy, nullable) NSDictionary *callbackUserInfo;

- (instancetype)initWithTitle:(NSString *)title desc:(NSString *)desc;

@end

NS_ASSUME_NONNULL_END
