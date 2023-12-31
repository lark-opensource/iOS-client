//
//   DVECoreExportServiceProtocol.h
//   NLEEditor
//
//   Created  by bytedance on 2021/5/23.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVECoreProtocol.h"
#import <DVEFoundationKit/DVECommonDefine.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVECoreExportServiceProtocol <DVECoreProtocol>

@property (nonatomic, assign) DVEExportFPS expotFps;

@property (nonatomic, assign) DVEExportResolution exportResolution;

@property (nonatomic, copy, nullable) dispatch_block_t beforeExportBlock;

@property (nonatomic, copy, nullable) dispatch_block_t afterExportBlock;

-(void)setExportFPSSelectIndex:(NSInteger)index;

-(void)setExportPresentSelectIndex:(NSInteger)index;

-(void)exportVideoWithProgress:(void (^_Nullable )(CGFloat progress))progressBlock resultBlock:(void (^)(NSError *error,id result))exportBlock;

-(void)cancelExport;

- (NSArray *)exportPresentTitleArr;

- (NSArray *)exportFPSTitleArr;

/// 当前视频合成后的预估导出码率
- (NSInteger)exportBitRate;

- (CGSize)exportVideoSize;

@end

NS_ASSUME_NONNULL_END
