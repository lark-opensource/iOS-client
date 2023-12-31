//
//  CJPayHybridView.h
//  CJPaySandBox
//
//  Created by 高航 on 2023/2/13.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HybridEngineType);

@class HybridContext;
@class CJPayHybridBaseConfig;
@protocol HybridKitViewProtocol;
@interface CJPayHybridView : UIView

@property (nonatomic, strong) UIView<HybridKitViewProtocol> *kitView;

@property (nonatomic, strong) HybridContext* context;

@property (nonatomic, strong) CJPayHybridBaseConfig *config;

- (instancetype)initWithConfig:(CJPayHybridBaseConfig *)config;

- (HybridEngineType)engineType;

- (void)sendEvent:(NSString *)event params:(nullable NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
