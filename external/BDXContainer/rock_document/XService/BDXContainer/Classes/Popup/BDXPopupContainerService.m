//
//  BDXPopupContainerService.m
//  BDXContainer
//
//  Created by xinwen tan on 2021/4/8.
//

#import "BDXPopupContainerService.h"
#import "BDXContainerUtil.h"
#import "BDXPopupSchemaParam.h"
#import "BDXPopupViewController+Private.h"
#import "BDXPopupViewController.h"
#import "BDXView.h"

#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXSchemaProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXServiceRegister.h>

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <objc/runtime.h>

@BDXSERVICE_REGISTER(BDXPopupContainerService);

@interface BDXPopupContainerService ()

@property(nonatomic, strong, readonly) NSMutableArray<BDXPopupViewController *> *stack;

@end

@implementation BDXPopupContainerService

+ (BDXServiceScope)serviceScope
{
    return BDXServiceScopeGlobalDefault;
}

+ (BDXServiceType)serviceType
{
    return BDXServiceTypeContainerPopUp;
}

+ (NSString *)serviceBizID
{
    return DEFAULT_SERVICE_BIZ_ID;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _stack = [[NSMutableArray alloc] init];
    }

    return self;
}

- (nullable BDXPopupViewController *)popupWithContainerID:(NSString *)containerID
{
    BDXPopupViewController *target;
    for (int i = 0; i < self.stack.count; ++i) {
        __auto_type item = self.stack[i];
        if ([item.containerID isEqualToString:containerID]) {
            target = item;
            break;
        }
    }
    return target;
}

- (nullable id<BDXPopupContainerProtocol>)open:(NSString *_Nonnull)urlString context:(nullable BDXContext *)context
{
    NSString *bid = [context getObjForKey:kBDXContextKeyBid];
    Class schemaClz = BDXSERVICE_CLASS_WITH_DEFAULT(BDXSchemaProtocol, bid);

    if (class_conformsToProtocol(schemaClz, @protocol(BDXSchemaProtocol))) {
        if (!context) {
            context = [[BDXContext alloc] init];
        }
        NSURL *url = [NSURL URLWithString:urlString];
        BDXPopupSchemaParam *config = (BDXPopupSchemaParam *)[schemaClz resolverWithSchema:url contextInfo:context paramClass:BDXPopupSchemaParam.class];

        __auto_type originPopup = [self popupWithContainerID:config.originContainerID];
        __auto_type behavior = config.behavior;
        if (originPopup && behavior != BDXPopupBehaviorNone) {
            originPopup.userInteractionEnabled = NO;
        }

        @weakify(self);
        __auto_type completion = ^(BDXPopupViewController *vc) {
            [UIView animateWithDuration:.3 animations:^{
                [vc show];
                if (originPopup && behavior != BDXPopupBehaviorNone) {
                    [originPopup hide];
                }
            } completion:^(BOOL finished) {
                @strongify(self);
                vc.animationCompleted = YES;
                if (originPopup && behavior == BDXPopupBehaviorClose) {
                    [originPopup destroy];
                    [self.stack btd_removeObject:originPopup];
                }
            }];
        };

        __auto_type top = [BDXContainerUtil topBDXViewController];
        if (top && top.hybridAppeared && !top.hybridInBackground) {
            [top handleViewDidDisappear];
        }

        BDXPopupViewController *vc = [BDXPopupViewController createWithConfiguration:config context:context completion:completion];
        [self.stack addObject:vc];
        return vc;
    }

    return nil;
}

- (BOOL)closePopup:(NSString *)containerID animated:(BOOL)animated params:(nullable NSDictionary *)params
{
    return [self closePopup:containerID animated:animated params:params completion:^{
    }];
}

- (BOOL)closePopup:(NSString *)containerID animated:(BOOL)animated params:(nullable NSDictionary *)params completion:(nullable dispatch_block_t)finalCompletion
{
    BDXPopupViewController *target = [self popupWithContainerID:containerID];
    if (!target) {
        return false;
    }

    [self.stack removeObject:target];
    BDXPopupViewController *origin = nil;
    if (target.config.behavior == BDXPopupBehaviorHide) {
        origin = [self popupWithContainerID:target.config.originContainerID];
    }

    __auto_type animation = ^{
        [target hide];
        if (origin) {
            [origin show];
        }
    };

    __auto_type completion = ^{
        if (origin) {
            origin.userInteractionEnabled = YES;
        }
        [target destroy];
        [target removeSelf:params];

        if (finalCompletion) {
            finalCompletion();
        }
    };
    if (target.viewContainer.window != nil && animated) {
        [UIView animateWithDuration:.3 animations:animation completion:^(BOOL finished) {
            completion();
        }];
    } else {
        animation();
        completion();
    }

    return true;
}

@end
