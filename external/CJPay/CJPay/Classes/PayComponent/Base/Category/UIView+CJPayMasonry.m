//
//  UIView+CJPayMasonry.m
//  Pods
//
//  Created by xiuyuanLee on 2021/2/25.
//

#import "UIView+CJPayMasonry.h"

#import <Masonry/Masonry.h>

@implementation UIView (CJPayMasonry)

- (MASConstraintMaker *)cj_makeConstraint {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    return constraintMaker;
}

- (MASConstraintMaker *)cj_updateConstraint {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    constraintMaker.updateExisting = YES;
    return constraintMaker;
}

- (MASConstraintMaker *)cj_remakeConstraint {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    constraintMaker.removeExisting = YES;
    return constraintMaker;
}

@end
