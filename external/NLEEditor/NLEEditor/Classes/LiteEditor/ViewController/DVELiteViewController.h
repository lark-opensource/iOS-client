//
//  DVELiteViewController.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/4.
//

#import "DVEVCContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteViewController : UIViewController

@property (nonatomic, strong, nullable) DVEVCContext *vcContext;

#pragma mark - Init

- (instancetype)initWithBusinessConfiguration:(DVEBusinessConfiguration *)config;

@end

NS_ASSUME_NONNULL_END
