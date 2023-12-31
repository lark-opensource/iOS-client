//
//  BDPAppLoadPublicHeader.h
//  Timor
//
//  Created by 傅翔 on 2019/7/1.
//

#ifndef BDPAppLoadPublicHeader_h
#define BDPAppLoadPublicHeader_h

/** 小程序下载优先级 */
typedef NS_ENUM(NSInteger, BDPPkgLoadPriority) {
    /** 正常: 默认的下载优先级. 队列最多20个, 无"更"高级的下载任务时, (high+normal)并发最多2个 */
    BDPAppLoadPriorityNormal = 0,
    /** 高级: 比正常优先级更高的下载任务. 无"最"高级的下载任务时, 会打断之前的高级或正常级别的下载, (high+normal)并发最多2个 */
    BDPAppLoadPriorityHigh,
    /** 最高级: 会打断"非前台小程序下载任务"外的所有下载任务, 包括之前的最高级. 独占下载带宽, 并发最多1个 */
    BDPAppLoadPriorityHighest
};

#endif /* BDPAppLoadPublicHeader_h */
