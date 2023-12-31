//
//  CJPayIDCardProfileOCRViewController.h
//  Pods
//
//  Created by xutianxi on 2022/08/03.
//

#import "CJPayCardOCRViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIDCardProfileOCRViewController : CJPayCardOCRViewController

@property (nonatomic, assign) NSInteger minLength;
@property (nonatomic, assign) NSInteger maxLength;
@property (nonatomic, copy) NSString *fromPage;
@property (nonatomic, copy) NSDictionary *extParams;

@end

NS_ASSUME_NONNULL_END
