//
//  HTSVideoSpeedControl.h
//  Pods
//
//  Created by 何海 on 16/8/11.
//
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/HTSVideoDefines.h>

@class HTSVideoSpeedControl;
@protocol HTSVideoSpeedControlDelegate <NSObject>

@optional
/**
 *
 *  @return Default : YES
 */
- (BOOL)speedControl:(HTSVideoSpeedControl *)speedControl shouldSelectSpeed:(HTSVideoSpeed)speed;
- (void)speedControl:(HTSVideoSpeedControl *)speedControl didSelectedIndex:(NSInteger)newIndex oldIndex:(NSInteger)oldIndex;

@end

@interface HTSVideoSpeedControl : UIView

@property (nonatomic, weak) id<HTSVideoSpeedControlDelegate> delegate;
/**
 *  KVOable
 */
@property (nonatomic, readonly) HTSVideoSpeed selectedSpeed;

@property (nonatomic, strong) NSString *sourcePage;
@property (nonatomic, strong) NSDictionary *referExtra;

- (void)selectSpeedByCode:(HTSVideoSpeed)speed;

+ (HTSVideoSpeed)defaultSelectedSpeed;

@end
