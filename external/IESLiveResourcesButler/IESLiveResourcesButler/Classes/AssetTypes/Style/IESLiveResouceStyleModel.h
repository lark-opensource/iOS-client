//
//  IESLiveResouceStyleModel.h
//  Pods
//
//  Created by Zeus on 17/1/10.
//
//

#import <Foundation/Foundation.h>

@class IESLiveResouceBundle;
@interface IESLiveResouceStyleModel : NSObject

@property (nonatomic, strong) NSNumber *clipsToBounds;
@property (nonatomic, strong) UIColor *backgroudColor;
@property (nonatomic, strong) NSNumber *alpha;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) NSNumber *borderWidth;
@property (nonatomic, strong) NSNumber *cornerRadius;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;

- (instancetype)initWithDictionary:(NSDictionary *)style assetBundle:(IESLiveResouceBundle *)bundle;

@end
