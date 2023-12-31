//
//  BDPMapCircleModel.h
//  OPPluginBiz
//
//  Created by 武嘉晟 on 2020/2/5.
//

#import <OPFoundation/BDPBaseJSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPMapCircleModel : BDPBaseJSONModel

@property (nonatomic, assign) CGFloat longitude;
@property (nonatomic, assign) CGFloat latitude;
@property (nonatomic, copy, nullable) NSString *color;
@property (nonatomic, copy, nullable) NSString *fillColor;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat strokeWidth;

@end

NS_ASSUME_NONNULL_END
