//
//  BDUGSystemContentItem.h
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeSystem;

@interface BDUGSystemContentItem : BDUGShareBaseContentItem

/// 可选设置，默认 CGRectMake(topVC.view.frame.size.width/2, topVC.view.frame.size.height * 3.f/4.f, 0, 0)
@property (nonatomic, assign) CGRect popoverRect;

/// 可选配置，优先级高于默认数据（title+url+image）
@property (nonatomic, strong, nullable) NSArray *systemActivityItems;

/// 可选配置，默认为nil。
@property (nonatomic, strong, nullable) NSArray<__kindof UIActivity *> *applicationActivities;

/// 可选配置，默认为nil。
@property (nonatomic, strong, nullable) NSArray<UIActivityType> *excludedActivityTypes; // default is nil. activity types listed will not be displayed

@property (nonatomic, assign) BOOL shareFile;
/**
 shareFile = YES 下为required属性。 要分享的文件URL，可以是本地文件路径fileURL，也可以是下载链接。
 */
@property (nonatomic, strong, nullable) NSURL *fileURL;

/**
 shareFile = YES 为required属性。 要分享的文件名，且必须有后缀名(例如：pdf)
 */
@property (nonatomic, copy, nullable) NSString *fileName;

- (instancetype)initWithDesc:(NSString * _Nullable)desc
                  webPageUrl:(NSString * _Nullable)webPageUrl
                       image:(UIImage * _Nullable)image;
@end

NS_ASSUME_NONNULL_END
