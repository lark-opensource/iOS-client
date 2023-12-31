//
//  BDUGShareActivityActionManager.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/15.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGShareDataModel.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareBaseContentItem.h"

@protocol BDUGShareActivityActionProtocol <NSObject>

@required

+ (BOOL)canShareWithContentItem:(BDUGShareBaseContentItem *)contentItem
                      itemModel:(BDUGShareDataItemModel *)itemModel;

+ (void)shareWithActivity:(id <BDUGActivityProtocol>)activity
                itemModel:(BDUGShareDataItemModel *)itemModel
   openThirdPlatformBlock:(BDUGShareOpenThirPlatform)openThirdPlatformBlock
               completion:(BDUGActivityCompletionHandler)completion;

@optional

+ (void)setLastToken:(NSString *)token;

@end


@interface BDUGShareActivityActionManager : NSObject

#pragma mark - activity action

+ (BOOL)performShareWithActivity:(id <BDUGActivityProtocol>)activity
                       itemModel:(BDUGShareDataItemModel *)itemModel
          openThirdPlatformBlock:(BDUGShareOpenThirPlatform)openThirdPlatformBlock
              activityTypeString:(NSString *)activityTypeString
                      completion:(BDUGActivityCompletionHandler)completion;

+ (void)convertInfo:(BDUGVideoImageShareInfo *)info contentItem:(BDUGShareBaseContentItem *)contentItem;

#pragma mark - config delegate

+ (void)setImageShareDelegate:(Class <BDUGShareActivityActionProtocol>)delegate;

+ (void)setTokenShareDelegate:(Class <BDUGShareActivityActionProtocol>)delegate;

#pragma mark - adapter

+ (void)setLastToken:(NSString *)token;

@end
