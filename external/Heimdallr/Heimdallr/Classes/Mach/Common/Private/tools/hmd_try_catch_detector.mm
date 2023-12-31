//
//  hmd_try_catch_detector.c
//  Pods-Heimdallr_Example
//
//  Created by 白昆仑 on 2020/3/9.
//

#import "hmd_try_catch_detector.h"
#import <string.h>
#import <unwind.h>
#import <objc/objc-exception.h>
#import <dlfcn.h>
#import "HMDTimeSepc.h"
#import "HMDMacro.h"
#import <libunwind.h>
#import "hmd_types.h"
#import "HMDCompactUnwind.hpp"
#import "HMDALogProtocol.h"
#import "hmd_crash_safe_tool.h"
#import "HeimdallrUtilities.h"

#ifdef __cplusplus
extern "C" {
#endif

// 自主解析unwinds数据
#ifdef __arm__
#else
OBJC_EXTERN _Unwind_Reason_Code
__objc_personality_v0(int version,
                      _Unwind_Action actions,
                      uint64_t exceptionClass,
                      struct _Unwind_Exception *exceptionObject,
                      struct _Unwind_Context *context);
#endif

#define HMD_DW_EH_PE_omit      0xff  // no data follows
#define HMD_DW_EH_PE_absptr    0x00
#define HMD_DW_EH_PE_uleb128   0x01
#define HMD_DW_EH_PE_udata2    0x02
#define HMD_DW_EH_PE_udata4    0x03
#define HMD_DW_EH_PE_udata8    0x04
#define HMD_DW_EH_PE_sleb128   0x09
#define HMD_DW_EH_PE_sdata2    0x0A
#define HMD_DW_EH_PE_sdata4    0x0B
#define HMD_DW_EH_PE_sdata8    0x0C
#define HMD_DW_EH_PE_pcrel     0x10
#define HMD_DW_EH_PE_textrel   0x20
#define HMD_DW_EH_PE_datarel   0x30
#define HMD_DW_EH_PE_funcrel   0x40
#define HMD_DW_EH_PE_aligned   0x50  // fixme
#define HMD_DW_EH_PE_indirect  0x80  // gcc extension

static uintptr_t hmd_read_uleb(uintptr_t *val)
{
    uintptr_t res = 0;
    uintptr_t bits = 0;
    unsigned char hmdbyte;
    do {
        hmdbyte = *(const unsigned char *)(*val)++;
        res |= (hmdbyte & 0x7f) << bits;
        bits += 7;
    } while (hmdbyte & 0x80);
    return res;
}

static intptr_t hmd_read_sleb(uintptr_t *val)
{
    uintptr_t res = 0;
    uintptr_t bits = 0;
    unsigned char hmdbyte;
    do {
        hmdbyte = *(const unsigned char *)(*val)++;
        res |= (hmdbyte & 0x7f) << bits;
        bits += 7;
    } while (hmdbyte & 0x80);
    if ((bits < 8*sizeof(intptr_t))  &&  (hmdbyte & 0x40)) {
        res |= ((intptr_t)-1) << bits;
    }
    return res;
}

static uintptr_t hmd_read_address(uintptr_t *val,
                              const struct dwarf_eh_bases * bases,
                              unsigned char encoding)
{
    uintptr_t res = 0;
    
    uintptr_t hmdoldp = *val;

#define HMDREAD(type) \
    res = *(type *)(*val); \
    *val += sizeof(type);

    if (encoding == HMD_DW_EH_PE_omit) return 0;

    switch (encoding & 0x0f) {
    case HMD_DW_EH_PE_absptr:
        HMDREAD(uintptr_t);
        break;
    case HMD_DW_EH_PE_uleb128:
        res = hmd_read_uleb(val);
        break;
    case HMD_DW_EH_PE_udata2:
        HMDREAD(uint16_t);
        break;
    case HMD_DW_EH_PE_udata4:
        HMDREAD(uint32_t);
        break;
#if __LP64__
    case HMD_DW_EH_PE_udata8:
        HMDREAD(uint64_t);
        break;
#endif
    case HMD_DW_EH_PE_sleb128:
        res = hmd_read_sleb(val);
        break;
    case HMD_DW_EH_PE_sdata2:
        HMDREAD(int16_t);
        break;
    case HMD_DW_EH_PE_sdata4:
        HMDREAD(int32_t);
        break;
#if __LP64__
    case HMD_DW_EH_PE_sdata8:
        HMDREAD(int64_t);
        break;
#endif
    default:
        break;
    }

#undef HMDREAD

    if (res) {
        switch (encoding & 0x70) {
        case HMD_DW_EH_PE_pcrel:
            // fixme correct?
            res += (uintptr_t)hmdoldp;
            break;
        case HMD_DW_EH_PE_textrel:
            res += bases->tbase;
            break;
        case HMD_DW_EH_PE_datarel:
            res += bases->dbase;
            break;
        case HMD_DW_EH_PE_funcrel:
            res += bases->func;
            break;
        case HMD_DW_EH_PE_aligned:
            break;
        default:
            // no adjustment
            break;
        }

        if (encoding & HMD_DW_EH_PE_indirect) {
            res = *(uintptr_t *)res;
        }
    }

    return (uintptr_t)res;
}

// This function does not distinguish C++/OC Catch
static bool hmdHasExceptionCatcher(uintptr_t lsda, uintptr_t ip, uintptr_t start_ip)
{
    struct dwarf_eh_bases bases;
    bases.tbase = 0;
    bases.dbase = 0;
    bases.func = start_ip;
    
    // http://itanium-cxx-abi.github.io/cxx-abi/exceptions.pdf
    // Read LSDA Header and do nothing
    unsigned char LPStart_enc = *(const unsigned char *)lsda++;

    if (LPStart_enc != HMD_DW_EH_PE_omit) {
        hmd_read_address(&lsda, &bases, LPStart_enc); // LPStart
    }

    unsigned char TType_enc = *(const unsigned char *)lsda++;
    if (TType_enc != HMD_DW_EH_PE_omit) {
        hmd_read_uleb(&lsda);  // TType
    }

    // Read Call Site Table
    // Call Site Table immediately follows the LSDA header.
    unsigned char call_site_enc = *(const unsigned char *)lsda++;
    uintptr_t length = hmd_read_uleb(&lsda); //call site table length
    uintptr_t call_site_table = lsda;
    uintptr_t call_site_table_end = call_site_table + length;
    uintptr_t p = call_site_table;
    
    // The action table follows the call-site table in the LSDA
    uintptr_t action_record_table = call_site_table_end;
    uintptr_t action_record = 0;
    
    // Read Call Site Table
    while (p < call_site_table_end) {
        
        // Each record indicates:
        // • The position of the call-site,
        // • The position of the landing-pad,
        // • The first action record for that call-site
        
        //The first call site is counted relative to the start of the procedure fragement.
        uintptr_t start   = bases.func + hmd_read_address(&p, &bases, call_site_enc);
        uintptr_t len     = hmd_read_address(&p, &bases, call_site_enc);
        uintptr_t pad     = hmd_read_address(&p, &bases, call_site_enc);
        uintptr_t action  = hmd_read_uleb(&p);

        if (ip < start) {
            return false;
        }
        
        if (ip < start + len) { // start <= ip < start + len
            if (pad == 0) return false;  // ...but it has no landing pad

            // action record: offset of the first associated action record,
            // relative to the start of the actions table.
            // This value is biased by 1
            // (1 indicates the start of the actions table), and 0 indicates that there are no actions.
            action_record = action ? action_record_table + (action - 1) : 0;
            break;
        }
    }
    
    if (action_record == 0) return false;  // 0 indicates that there are no actions

    // has handlers, destructors, and/or throws specifications
    // Use this frame if it has any handlers
    bool has_handler = false;
    p = action_record;
    intptr_t offset = 0;
    
    // Read Action Table
    do {
        // filter: Index in the types table of the __typeinfo for the catch-clause type.
        intptr_t filter = hmd_read_sleb(&p);
        uintptr_t temp = p;
        // offset: Signed offset, in bytes from the start of this field,
        // to the next chained action record, or zero if none
        offset = hmd_read_sleb(&temp);
        p += offset;
         
        // <0: throws specification - ignore
        // =0: destructor - ignore
        // >0: catch or finally
//        DEBUG_C_LOG("<%p> filter = %ld", (void*)ip, filter);
        if (filter > 0) {
            has_handler = true;
            break;
        }
    } while (offset);

    return has_handler;
}

bool HMD_NO_OPT_ATTRIBUTE hmdFindHandler(unsigned int ignore_depth)
{
#ifdef __arm__
    HMDPrint("armv7 not found [Try-Catch]");
    return false;
#else
    hmd_setup_shared_image_list(); // 首次调用耗时
    // walk stack looking for frame with objc catch handler
    unw_context_t uc;
    unw_getcontext(&uc);
    unw_cursor_t cursor;
    unw_init_local(&cursor, &uc);
    // 跳过顶层栈
    while (ignore_depth > 0) {
        if (unw_step(&cursor) > 0) {
            ignore_depth--;
        }
        else {
            return false;
        }
    }
    
    unw_proc_info_t info;
    while (unw_step(&cursor) > 0) {
        
        if (unw_get_proc_info(&cursor, &info) != UNW_ESUCCESS) {
            break;
        }
        
        if (info.handler != (uintptr_t)__objc_personality_v0) {
            continue;
        }
        
        if (info.lsda == 0) {
            continue;
        }
        
        unw_word_t ip = 0;
        unw_get_reg(&cursor, UNW_REG_IP, &ip);
        ip = HMD_POINTER_STRIP(ip);
        ip -= 1;
        if (hmdHasExceptionCatcher(info.lsda, ip, info.start_ip)) {
            // App自身Catch有效
            hmd_async_image_list_set_reading(&shared_app_image_list, true);
            bool isMyCatch = (hmd_async_image_containing_address(&shared_app_image_list, ip) != NULL);
            hmd_async_image_list_set_reading(&shared_app_image_list, false);
            if (isMyCatch) {
                HMDALOG_PROTOCOL_INFO(@"[Heimdallr][Try-Catch]In App Catch <%p>", (void *)ip);
#ifdef DEBUG
                Dl_info dl_info = {0};
                if(dladdr((void *)ip, &dl_info) != 0) {
                    HMDPrint("[YES][App]<%p>%s", (void *)ip, dl_info.dli_sname);
                }
#endif
                return true;
            }
            
            Dl_info dl_info = {0};
            if (dladdr((void *)ip, &dl_info) == 0 || dl_info.dli_sname == NULL) {
                // 符号化失败，忽略判断此调用栈try-catch
                HMDALOG_PROTOCOL_ERROR(@"[Heimdallr][Try-Catch]Symbol Failed <%p>", (void *)ip);
                HMDPrint("[Symbol Error]<%p>%s", (void *)ip, "dladdr failed");
                continue;
            }
            
            if (hmd_is_in_app_bundle(dl_info.dli_fname) && !hmd_reliable_has_suffix(dl_info.dli_fname, ".dylib")) {
                HMDALOG_PROTOCOL_INFO(@"[Heimdallr][Try-Catch]App Catch <%p> %s <%s>", (void *)ip, dl_info.dli_sname, dl_info.dli_fname);
                return true;
            }
            
            if (hmd_reliable_has_suffix(dl_info.dli_fname, "AccessibilityUtilities") ||
                hmd_reliable_has_suffix(dl_info.dli_fname, "WebKitLegacy")) {
                HMDALOG_PROTOCOL_WARN(@"[Heimdallr][Try-Catch]System Catch <%p> %s <%s>", (void *)ip, dl_info.dli_sname, dl_info.dli_fname);
                HMDPrint("[Catch]<%p>%s", (void *)ip, dl_info.dli_sname);
                return true;
            }
            
            // 不是CFRunLoopRunSpecific，则记录符号信息
            if (strcmp(dl_info.dli_sname, "CFRunLoopRunSpecific") != 0) {
                HMDALOG_PROTOCOL_WARN(@"[Heimdallr][Try-Catch]Ignore <%p> %s <%s>", (void *)ip, dl_info.dli_sname, dl_info.dli_fname);
            }
            
            HMDPrint("[Ignore]<%p>%s", (void *)ip, dl_info.dli_sname);
        }
    }
    
    HMDPrint("[NO]");
    return false;
#endif
}

#pragma mark - Public
    
bool HMD_NO_OPT_ATTRIBUTE hmd_check_in_try_catch(unsigned int ignore_depth) {
    return hmdFindHandler(ignore_depth+1);
}

#ifdef __cplusplus
}
#endif
