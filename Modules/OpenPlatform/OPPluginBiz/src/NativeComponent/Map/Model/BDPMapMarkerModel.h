//
//  BDPMapMarkerModel.h
//  OPPluginBiz
//
//  Created by 武嘉晟 on 2019/12/20.
//

#import <OPFoundation/BDPBaseJSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPMapMarkerModel : BDPBaseJSONModel

@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) CGFloat longitude;
@property (nonatomic, assign) CGFloat latitude;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *iconPath;

@end

NS_ASSUME_NONNULL_END
