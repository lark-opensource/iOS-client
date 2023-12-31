//
//  BDWebImageRequest+Monitor.h
//  BDWebImage
//
//  Created by fengyadong on 2017/12/6.
//

#import "BDWebImageRequest.h"

#define BDImageRequestTimestamp(request,record) [request recorder].record = CACurrentMediaTime() * 1000; 

@interface BDWebImageRequest ()

@property (nonatomic, strong, readwrite) BDImagePerformanceRecoder *recorder;
@property (nonatomic, strong, readwrite) BDImageLargeSizeMonitor *largeImageMonitor;

@end
