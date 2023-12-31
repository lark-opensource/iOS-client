//
//  HMDAsyncSymbolicator.c
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/7/23.
//

#include "HMDAsyncSymbolicator.h"
#include "HMDAsyncImageList.h"
#include "HMDAsyncSymbolReader.h"

extern hmd_async_image_list_t shared_image_list;

struct hmd_symbol_lookup_context {
    /** Buffer to which the symbol name should be written. */
    char name[512];
    
    /** If true, the symbol was found. If false, no symbol was found */
    bool found;
    
    /** Address of the discovered symbol, or 0x0 if not found. */
    uintptr_t symbol_address;
};

struct hmd_address_range_lookup_context {
    /** Buffer to which the symbol name should be written. */
    char name[512];
    
    /** If true, the symbol was found. If false, no symbol was found */
    bool found;
    
    /** Start address of the discovered symbol, or 0x0 if not found. */
    uintptr_t start_address;
    
    /** End address of the discovered symbol, or 0x0 if not found. */
    uintptr_t end_address;
};

static void macho_symbol_callback (uintptr_t address, const char *name, void *ctx) {
    struct hmd_symbol_lookup_context *lookup_ctx = ctx;
    
    /* Skip this match if a better match has already been found */
    if (lookup_ctx->found && address < lookup_ctx->symbol_address)
        return;
    
    /* Mark as found */
    lookup_ctx->symbol_address = address;
    lookup_ctx->found = true;
    
    snprintf(lookup_ctx->name, sizeof(lookup_ctx->name), "%s", name);
    lookup_ctx->name[sizeof(lookup_ctx->name)-1] = 0;
}

static void macho_range_callback (uintptr_t start_address, uintptr_t end_address, const char *name, void *ctx) {
    struct hmd_address_range_lookup_context *lookup_ctx = ctx;
    
    /* Skip this match if a better match has already been found */
    if (lookup_ctx->found && start_address < lookup_ctx->start_address )
        return;
    
    /* Mark as found */
    lookup_ctx->start_address = start_address;
    lookup_ctx->end_address = end_address;
    lookup_ctx->found = true;
    
    snprintf(lookup_ctx->name, sizeof(lookup_ctx->name), "%s", name);
    lookup_ctx->name[sizeof(lookup_ctx->name)-1] = 0;
}

bool hmd_async_find_symbol(const uintptr_t address, hmd_dl_info* const info, hmd_async_image_t * image)
{
    if (info == NULL || image == NULL) {
        return false;
    }
    struct hmd_symbol_lookup_context context;
    memset(&context, 0, sizeof(context));
    hmd_error_t err = hmd_async_macho_find_symbol_by_pc(&image->macho_image, address, macho_symbol_callback, &context);

    if (err == HMD_ESUCCESS) {
        info->dli_saddr = (void *)context.symbol_address;
        snprintf(info->dli_sname, sizeof(info->dli_sname), "%s", context.name);
        info->dli_sname[sizeof(info->dli_sname)-1] = 0;
        return true;
    }
    return false;
}

bool hmd_async_dladdr(const uintptr_t address, hmd_dl_info* const info, bool need_symbol)
{
    if (info == NULL) {
        return false;
    }

    bool result = false;
    
    hmd_async_image_list_set_reading(&shared_image_list, true);
    
    hmd_async_image_t * image = hmd_async_image_containing_address(&shared_image_list, address);
    
    if (image != NULL) {
        snprintf(info->dli_fname, sizeof(info->dli_fname), "%s", image->macho_image.name);
        info->dli_fname[sizeof(info->dli_fname)-1] = 0;
        info->dli_fbase = (void*)image->macho_image.header_addr;
        if (need_symbol) {
            result = hmd_async_find_symbol(address, info, image);
        } else {
            info->dli_saddr = info->dli_fbase;
            info->dli_sname[0] = 0;
            result = true;
        }
    }
    
    hmd_async_image_list_set_reading(&shared_image_list, false);
    
    return result;
}

void hmd_dl_info_init(hmd_dl_info *target, Dl_info *info)
{
    if (target == NULL || info == NULL) {
        return;
    }
    target->dli_fbase = info->dli_fbase;
    if (info->dli_fname) {
        snprintf(target->dli_fname, sizeof(target->dli_fname), "%s", info->dli_fname);
        target->dli_fname[sizeof(target->dli_fname) - 1] = 0;
    }

    target->dli_saddr = info->dli_saddr;
    if (info->dli_sname) {
        snprintf(target->dli_sname, sizeof(target->dli_sname), "%s", info->dli_sname);
        target->dli_sname[sizeof(target->dli_sname) - 1] = 0;
    }
}

bool hmd_async_find_symbol_range(const char *symbol, hmd_symbol_range* const range, hmd_async_image_t * image)
{
    if (range == NULL || image == NULL) {
        return false;
    }
    struct hmd_address_range_lookup_context context;
    memset(&context, 0, sizeof(context));
    hmd_error_t err = hmd_async_macho_find_range_by_symbol(&image->macho_image, symbol, macho_range_callback, &context);

    if (err == HMD_ESUCCESS) {
        range->dli_start_saddr = context.start_address;
        range->dli_end_saddr = context.end_address;
        return true;
    }
    return false;
}

bool hmd_symbol_address_range(const char *image_base_name,const char *symbol, hmd_symbol_range *range) {
    if (range == NULL) {
        return false;
    }

    bool result = false;
    
    hmd_async_image_list_set_reading(&shared_image_list, true);
    
    hmd_async_image_t * image = hmd_async_image_containing_name(&shared_image_list, image_base_name);
    
    if (image != NULL) {
        result = hmd_async_find_symbol_range(symbol, range, image);
    }
    
    hmd_async_image_list_set_reading(&shared_image_list, false);
    
    return result;
}
