//
//  BDPMapViewModel.h
//  OPPluginBiz
//
//  Created by 武嘉晟 on 2019/12/20.
//

#import <OPFoundation/BDPBaseJSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class BDPMapMarkerModel, BDPMapStyleModel, BDPMapCircleModel;
@protocol BDPMapMarkerModel, BDPMapCircleModel;

@interface BDPMapViewModel : BDPBaseJSONModel

@property (nonatomic, strong) BDPMapStyleModel *style;
@property (nonatomic, assign) CGFloat longitude;
@property (nonatomic, assign) CGFloat latitude;
@property (nonatomic, assign) NSInteger scale;
@property (nonatomic, copy, nullable) NSArray <BDPMapMarkerModel *> <BDPMapMarkerModel> *markers;
@property (nonatomic, copy, nullable) NSArray <BDPMapCircleModel *> <BDPMapCircleModel> *circles;
@property (nonatomic, assign) BOOL showLocation;

/// 验证一个参数是否为空
- (BOOL)isEmptyParam:(NSString *)paramKey;

/// 获取组件的frame
- (CGRect)frame;

@end

NS_ASSUME_NONNULL_END
