//
//  TTVideoEngineEventOneAVRenderCheckProtocol.h
//  TTVideoEngine
//
//  Created by bytedance on 2021/7/5.
//

#ifndef TTVideoEngineEventOneAVRenderCheckProtocol_h
#define TTVideoEngineEventOneAVRenderCheckProtocol_h

#import "TTVideoEngineEventBase.h"
#import "TTVideoEngineEventLoggerProtocol.h"

static NSInteger const VIDEO_AVRENDERCHECK_KEY_CROSSTALK_COUNT = 1;

@protocol TTVideoEngineEventOneAVRenderCheckProtocol <NSObject>

@required
@property (nonatomic, weak) id<TTVideoEngineEventLoggerDelegate> delegate;
- (instancetype)initWithEventBase:(TTVideoEngineEventBase*)base;
- (void)noVARenderStart:(NSInteger)pts noRenderType:(int)noRenderType;
- (void)noVARenderStart:(NSInteger)pts noRenderType:(int)noRenderType extraInfo:(NSDictionary *)extraInfo;
- (NSDictionary *)noVARenderEnd:(NSInteger)pts endType:(NSString *)endType noRenderType:(int *)pNORenderType;
- (void)setEnableMDL:(NSInteger)enable;
- (void)onAVBadInterlaced;
- (void)setValue:(id) value WithKey:(NSInteger) key;

@end

#endif /* TTVideoEngineEventOneAVRenderCheckProtocol_h */
