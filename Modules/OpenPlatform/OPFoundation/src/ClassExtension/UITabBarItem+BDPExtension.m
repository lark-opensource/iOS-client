//
//  UITabBarItem+BDPExtension.m
//  Timor
//
//  Created by yinyuan on 2021/1/10.
//

#import "UITabBarItem+BDPExtension.h"
#import <objc/runtime.h>
#import "BDPDeviceHelper.h"
#import <ECOInfra/EMAFeatureGating.h>

static NSString *const kEllipsisText = @"...";

@implementation UITabBarItem (BDPExtension)

- (void)bdp_applyTitleMaxWidth:(CGFloat)maxWidth attributes:(NSDictionary<NSAttributedStringKey,id> *)attributes {
    
    // 适配文本超长
    NSString *itemTitle = self.title;
    if (itemTitle.length <= 0) {
        // 文字长度为0，什么也不用做
        return;
    }
    // 测试当前的title长度
    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:itemTitle attributes:attributes];
    CGRect titleFrame = [titleString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                                  options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                  context:nil];
    if (titleFrame.size.width < maxWidth) {
        // 当前未超出长度
        if([BDPDeviceHelper isPadDevice] && self.originalTitle.length > 0 && ![EMAFeatureGating boolValueForKey:@"openplatform.gadget.ipad.fix_title_scale"]){
            //加这个的逻辑是因为 Infra iPad三栏需求合入后，self.tabBar的width可能会中间态取到一次0，导致标题被压缩；因此增加一个缓存标题的逻辑，如果被压缩过一次，但下次计算width 并没有超过，则重置一次title，保证能恢复。
            self.title = self.originalTitle;
        }
        return;
    }
    if([BDPDeviceHelper isPadDevice] && self.originalTitle.length <= 0 && ![EMAFeatureGating boolValueForKey:@"openplatform.gadget.ipad.fix_title_scale"]){
        self.originalTitle = itemTitle;
    }
    // 最坏的情况: 仅使用第一个字符
    NSString *targetTitle = [itemTitle substringToIndex:1];
    
    // 从第一个字符开始，添加"..."，messure是否超出长度，找到最合适的长度
    for (NSInteger index = 1; index < itemTitle.length; index++) {
        NSString *titlePrefix = [itemTitle substringToIndex:index];
        NSString *messureText = [NSString stringWithFormat:@"%@%@", titlePrefix, kEllipsisText];
        NSAttributedString *messureAttributedString = [[NSAttributedString alloc] initWithString:messureText attributes:attributes];
        CGRect messureFrame = [messureAttributedString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                    context:nil];
        if (messureFrame.size.width > maxWidth) {
            // 超出长度，停止messure
            break;
        }
        // 找到更合适的长度
        targetTitle = messureText;
    }
    self.title = targetTitle;
}

- (BOOL)bdp_hasSetImageByAPI {
    NSNumber *number = objc_getAssociatedObject(self, @selector(bdp_hasSetImageByAPI));
    return number.boolValue;
}

- (void)setBdp_hasSetImageByAPI:(BOOL)hasSetImageByAPI {
    objc_setAssociatedObject(self, @selector(bdp_hasSetImageByAPI), @(hasSetImageByAPI), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdp_hasSetSelectedImageByAPI {
    NSNumber *number = objc_getAssociatedObject(self, @selector(bdp_hasSetSelectedImageByAPI));
    return number.boolValue;
}

- (void)setBdp_hasSetSelectedImageByAPI:(BOOL)hasSetSelectedImageByAPI {
    objc_setAssociatedObject(self, @selector(bdp_hasSetSelectedImageByAPI), @(hasSetSelectedImageByAPI), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdp_itemAddedByAPI {
    NSNumber *number = objc_getAssociatedObject(self, @selector(bdp_itemAddedByAPI));
    return number.boolValue;
}

- (void)setBdp_itemAddedByAPI:(BOOL)itemAddedByAPI {
    objc_setAssociatedObject(self, @selector(bdp_itemAddedByAPI), @(itemAddedByAPI), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString *)originalTitle{
    return objc_getAssociatedObject(self, @selector(originalTitle));
}

-(void)setOriginalTitle:(NSString *)originalTitle{
    objc_setAssociatedObject(self, @selector(originalTitle), originalTitle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
