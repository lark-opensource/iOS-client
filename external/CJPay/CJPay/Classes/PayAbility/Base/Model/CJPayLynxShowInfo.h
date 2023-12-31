//
//  CJPayLynxShowInfo.h
//  Aweme
//
//  Created by youerwei on 2023/6/6.
//

#import <UIKit/UIKit.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayLynxShowInfo : JSONModel

@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) BOOL needJump;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSDictionary *exts;

@end

NS_ASSUME_NONNULL_END
