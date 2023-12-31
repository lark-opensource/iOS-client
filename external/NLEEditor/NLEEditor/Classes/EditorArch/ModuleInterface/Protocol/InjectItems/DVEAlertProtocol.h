//
//  DVEAlertProtocol.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^DVEActionBlock)(UIView *view);

@protocol DVEAlertProtocol <NSObject>

- (void)showAlertWithTitle:(NSString *)title
               description:(NSString *)description
                 leftTitle:(NSString *)leftTitle
                rightTitle:(NSString *)rightTitle
                 leftBlock:(DVEActionBlock _Nullable)leftBlock
                rightBlock:(DVEActionBlock _Nullable)rightBlock;

@end

NS_ASSUME_NONNULL_END
