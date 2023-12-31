//
//  BytedCertMacros.h
//  Pods
//
//  Created by jiangying.it@bytedance.com on 2022/7/13.
//

#ifndef BytedCertMacros_h
#define BytedCertMacros_h

#define BDCT_BLOCK_INVOKE(block, ...) (block ? block(__VA_ARGS__) : 0)

#endif /* BytedCertMacros_h */
