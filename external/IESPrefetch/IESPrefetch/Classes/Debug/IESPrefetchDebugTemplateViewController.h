//
//  IESPrefetchDebugTemplateViewController.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/19.
//

#import <UIKit/UIKit.h>
@protocol IESPrefetchConfigTemplate;

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchDebugTemplateViewController : UIViewController

@property(nonatomic, strong) id<IESPrefetchConfigTemplate> configTemplate;
@property(nonatomic, assign) BOOL editable;

- (instancetype)initWithBusiness:(NSString *)business;

@end

NS_ASSUME_NONNULL_END
