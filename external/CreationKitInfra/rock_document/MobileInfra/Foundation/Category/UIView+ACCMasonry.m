//
//  UIView+ACCMasonry.m
//  CameraClient-Pods-Aweme
//
//  Created by xiubin on 2020/8/25.
//

#import "UIView+ACCMasonry.h"

#import <Masonry/MASConstraintMaker.h>

@implementation UIView (ACCMasonry)

- (MASConstraintMaker *)acc_makeConstraint
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    return constraintMaker;
}

- (MASConstraintMaker *)acc_updateConstraint
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    constraintMaker.updateExisting = YES;
    return constraintMaker;
}

- (MASConstraintMaker *)acc_remakeConstraint
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    constraintMaker.removeExisting = YES;
    return constraintMaker;
}

@end
