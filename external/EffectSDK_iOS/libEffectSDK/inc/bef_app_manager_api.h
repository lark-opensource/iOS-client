//
//  bef_app_manager_api_h
//
//  Created by lixu.albert on 11/28/2018.
//

#ifndef bef_app_manager_api_h
#define bef_app_manager_api_h


/**************************** application manager ********************************/


BEF_SDK_API void bef_effect_will_resign_active();

BEF_SDK_API void bef_effect_did_become_active();

BEF_SDK_API void bef_effect_did_enter_back_ground();

BEF_SDK_API void bef_effect_will_enter_foreground();

BEF_SDK_API void bef_effect_will_terminate();

BEF_SDK_API void bef_effect_receive_memory_warning();


#endif /* bef_app_manager_api_h */
