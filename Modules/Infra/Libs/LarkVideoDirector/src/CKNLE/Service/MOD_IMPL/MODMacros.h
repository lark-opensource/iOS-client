//
//  Header.h
//  Modeo
//
//  Created by yansong li on 2020/12/28.
//

#ifndef MODBLOCK_INVOKE
#define MODBLOCK_INVOKE(block, ...) (block ? block(__VA_ARGS__) : 0)
#endif
