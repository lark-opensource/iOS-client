//
//  BDPChooseImageDefine.h
//  OPPluginBiz
//
//  Created by baojianjun on 2023/4/23.
//

#ifndef BDPChooseImageDefine_h
#define BDPChooseImageDefine_h

/*
 * 图片的系统授权结果，目前只有通过和拒绝，不区分类型
 */
typedef NS_ENUM(NSInteger, BDPImageAuthResult) {
    BDPImageAuthPass = 0,
    BDPImageAuthDeny = 1
};

#endif /* BDPChooseImageDefine_h */
