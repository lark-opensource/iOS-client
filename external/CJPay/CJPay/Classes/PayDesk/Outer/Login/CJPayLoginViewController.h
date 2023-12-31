//
//  CJPayLoginViewController.h
//  Aweme
//
//  Created by 陈博成 on 2023/3/22.
//

#import "CJPayFullPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayAPIDelegate;

@interface CJPayLoginViewController : CJPayFullPageBaseViewController

@property (nonatomic, weak) id<CJPayAPIDelegate> delegate;
@property (nonatomic, copy) NSDictionary *schemaParams;

@end

NS_ASSUME_NONNULL_END
