//
//  BDPBadgeLabel.h
//  Timor
//
//  Created by tujinqiu on 2020/2/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPBadgeLabel : UILabel

@property (nonatomic, assign) NSUInteger maxNum;

- (void)setBadge:(NSString *)badge;
- (void)setNum:(NSUInteger)num;
- (CGSize)suitableSize;

@end

NS_ASSUME_NONNULL_END
