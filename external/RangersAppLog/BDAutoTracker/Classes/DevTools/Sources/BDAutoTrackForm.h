//
//  BDAutoTrackForm.h
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/29/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrackFormElement;

@interface BDAutoTrackFormGroup : NSObject

@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) NSArray<BDAutoTrackFormElement *> *elements;

+ (instancetype)groupWithTitle:(NSString *)title
                      elements:(NSArray<BDAutoTrackFormElement *> *)elements;


@end

@interface BDAutoTrackFormElement : NSObject

@property (nonatomic, assign) BOOL copyEnabled;
@property (nonatomic, assign) BOOL valType;
@property (nullable, nonatomic, copy) void (^stateUpdate)(BDAutoTrackFormElement *);
@property (nullable, nonatomic, copy) void (^action)(BDAutoTrackFormElement *);

@property (nonatomic, copy) NSString *title;

@property (nonatomic) id val;

+ (instancetype)elementUsingBlock:(void (^ __nullable)(BDAutoTrackFormElement *))action
                      stateUpdate:(void (^ __nullable)(BDAutoTrackFormElement *))update
                     defaultTitle:(NSString *)defTitle
                     defualtValue:(id __nullable)defVal;

- (instancetype)displayValType;

- (instancetype)enableCopy;


- (id)cellForTable:(UITableView *)table;

+ (NSArray<BDAutoTrackFormElement *> *)transform:(id)collection;


@end

@interface BDAutoTrackForm : NSObject

@property (nonatomic, weak) UIViewController *container;

@property (nonatomic, readonly) UITableView *tableView;

@property (nonatomic, strong) NSArray<BDAutoTrackFormGroup *> *groups;

- (void)embedIn:(UIViewController *)container;

- (void)reload;

@end

NS_ASSUME_NONNULL_END
