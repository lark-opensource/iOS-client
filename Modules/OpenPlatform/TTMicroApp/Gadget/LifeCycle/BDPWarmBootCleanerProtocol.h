//
//  BDPWarmBootCleanerProtocol.h
//  Timor
//
//  Created by 傅翔 on 2019/4/18.
//

@protocol BDPWarmBootCleanerProtocol;
typedef id<BDPWarmBootCleanerProtocol> BDPWarmBootCleaner;

@protocol BDPWarmBootCleanerProtocol <NSObject>

///热启应用将被销毁, 可在该方法内做一些响应的操作, 如停止TTHelium等
- (void)warmBootManagerWillEvictCache;

@end



