//
//  ACCSegmentUIControl.h
//  Aweme
//
//  Created by Shichen Peng on 2021/11/1.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ACCSegmentUIControl : UIControl

@property (nonatomic, strong, nonnull) UIColor *backgroundColor; // defaults to gray
@property (nonatomic, strong, nonnull) UIColor *sliderColor; // defaults to white
@property (nonatomic, strong, nonnull) UIColor *labelTextColorInsideSlider; // defaults to black
@property (nonatomic, strong, nonnull) UIColor *labelTextColorOutsideSlider; // defaults to white
@property (nonatomic, strong, nullable) UIFont *font; // default is nil
@property (nonatomic, assign) CGFloat sliderOffset; // slider offset from background, top, bottom, left, right
@property (nonatomic, assign) BOOL continuousSlidingMode; // NO: discrete mode YES: continued mode

+ (instancetype)switchWithStringsArray:(NSArray *)strings;
- (instancetype)initWithStringsArray:(NSArray *)strings;

- (void)forceSelectedIndex:(NSInteger)index animated:(BOOL)animated; // sets the index, also calls handler block

// This method sets handler block that is getting called after the switcher is done animating the transition

- (void)setPressedHandler:(void (^)(NSUInteger index))handler;

// This method sets handler block that is getting called right before the switcher starts animating the transition

- (void)setWillBePressedHandler:(void (^)(NSUInteger index))handler;

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated; // sets the index without calling the handler block


@end

