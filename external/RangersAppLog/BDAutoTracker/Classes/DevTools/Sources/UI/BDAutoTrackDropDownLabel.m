//
//  BDAutoTrackDropDownLabel.m
//  RangersAppLog
//
//  Created by bytedance on 7/4/22.
//

#import "BDAutoTrackDropDownLabel.h"

@interface BDAutoTrackDropDownLabel ()

@property (nonatomic, strong) UIButton *dropDownButton;

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation BDAutoTrackDropDownLabel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"arrow-down" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"];
    
    self.dropDownButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.dropDownButton setImage:[UIImage imageWithContentsOfFile:path] forState:UIControlStateNormal];
    
    self.textLabel = [UILabel new];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightRegular];
    self.backgroundColor = [UIColor whiteColor];
    
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 4.0f;
    self.layer.borderColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.5].CGColor;
    
    [self addSubview:self.textLabel];
    [self addSubview:_dropDownButton];
    
    
    self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dropDownButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[label]-[button(20)]-|"
                                                                 options:0
                                                                 metrics:@{}
                                                                   views:@{@"label": self.textLabel,
                                                                           @"button": self.dropDownButton}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[label]-|"
                                                                 options:0
                                                                 metrics:@{}
                                                                   views:@{@"label": self.textLabel}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button(20)]"
                                                                 options:0
                                                                 metrics:@{}
                                                                   views:@{@"button": self.dropDownButton}]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dropDownButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.textLabel attribute:NSLayoutAttributeCenterY multiplier:1 constant:1]];
    
    [self.dropDownButton addTarget:self action:@selector(presentActionSheet) forControlEvents:UIControlEventTouchUpInside];
    
    
}

- (void)willMoveToSuperview:(nullable UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if ([self.textLabel.text length] == 0 &&  self.delegate && [self.delegate respondsToSelector:@selector(dropDownLabel:selectedIndex:)]) {
        self.textLabel.text = [self.delegate dropDownLabel:self selectedIndex:self.selectedIndex];
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (selectedIndex != _selectedIndex) {
        _selectedIndex = selectedIndex;
        if (self.delegate && [self.delegate respondsToSelector:@selector(dropDownLabel:selectedIndex:)]) {
            self.textLabel.text = [self.delegate dropDownLabel:self selectedIndex:selectedIndex];
            if (self.delegate && [self.delegate respondsToSelector:@selector(dropDownLabelDidUpdate:)]) {
                [self.delegate dropDownLabelDidUpdate:self];
            }
        }
    }
}

- (void)presentActionSheet
{
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"" message:@"make a selection" preferredStyle:UIAlertControllerStyleActionSheet];
    NSUInteger numberOfSections = [self.delegate numbersOfdropDownItems:self];
    for (int i = 0 ; i < numberOfSections; i ++) {
        NSString *title = [self.delegate dropDownLabel:self selectedIndex:i];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            if (self->_selectedIndex != i) {
                self.textLabel.text = title;
                self->_selectedIndex = i;
                if (self.delegate && [self.delegate respondsToSelector:@selector(dropDownLabelDidUpdate:)]) {
                    [self.delegate dropDownLabelDidUpdate:self];
                }
            }
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    
    
    UIViewController* contoller = nil;
    id nextResponder = [self nextResponder];
    while (nextResponder) {
        if ([nextResponder isKindOfClass:UIViewController.class]) {
            contoller = nextResponder;
            break;
        }
        nextResponder = [nextResponder nextResponder];
    }
    
    [contoller presentViewController:sheet animated:YES completion:nil];
    
}


@end
