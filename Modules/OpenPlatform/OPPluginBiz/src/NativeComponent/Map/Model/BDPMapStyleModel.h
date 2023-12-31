//
//  BDPMapStyleModel.h
//  OPPluginBiz
//
//  Created by 武嘉晟 on 2019/12/25.
//

#import <OPFoundation/BDPBaseJSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPMapStyleModel : BDPBaseJSONModel

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat top;

@end

NS_ASSUME_NONNULL_END
