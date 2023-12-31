//
//  HMDPatchTable.m
//  Heimdallr
//
//  Created by sunrunwang on 2023/1/4.
//

#if __LP64__

#include <dlfcn.h>
#include <stdbool.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/getsect.h>
#include <mach-o/dyld_images.h>
#import "HMDPatchTable.h"

#pragma mark - Extern Macro

#ifndef HMD_PATCH_TABLE_EXTERN
#    ifdef __cplusplus
#        define HMD_PATCH_TABLE_EXTERN extern "C"
#    else
#        define HMD_PATCH_TABLE_EXTERN extern
#    endif /* __cplusplus */
#endif /* HMD_PATCH_TABLE_EXTERN */

#pragma mark - Debug Macro

#ifndef COMPILE_ASSERT
#define COMPILE_ASSERT(condition) ((void)sizeof(char[1 - 2*!(condition)]))
#endif

#ifndef DEBUG_ASSERT
#ifdef DEBUG
#define DEBUG_ASSERT(x) if(!(x)) DEBUG_POINT
#else
#define DEBUG_ASSERT(x)
#endif
#endif

#ifndef DEBUG_ELSE
#ifdef DEBUG
#define DEBUG_ELSE else DEBUG_POINT;
#else
#define DEBUG_ELSE
#endif
#endif

#ifndef DEBUG_POINT
#ifdef DEBUG
#define DEBUG_POINT __builtin_trap();
#else
#define DEBUG_POINT
#endif
#endif

#ifndef DEBUG_RETURN
#ifdef DEBUG
#define DEBUG_RETURN(x) do { DEBUG_POINT; return (x); } while(0)
#else
#define DEBUG_RETURN(x) return (x)
#endif
#endif

#ifndef DEBUG_RETURN_NONE
#ifdef DEBUG
#define DEBUG_RETURN_NONE do { DEBUG_POINT; return; } while(0)
#else
#define DEBUG_RETURN_NONE return
#endif
#endif

#ifndef DEBUG_LOG
#ifdef DEBUG
    #define DEBUG_LOG(_format, ...) do {                                                                        \
        const char *_file_name_ = (strrchr)(__FILE__, '/') ? (strrchr)(__FILE__, '/') + 1 : __FILE__;           \
        fprintf(stderr, "[BDFishhook][PatchTable] %s:%d " _format "\n", _file_name_, __LINE__, ## __VA_ARGS__); \
    } while(0)
#else
    #define DEBUG_LOG(_format, ...)
#endif
#endif

#pragma mark - Develop Debug Macro

#ifndef DEVELOP_DEBUG_POINT
#ifdef DEBUG
#define DEVELOP_DEBUG_POINT do {                     \
    HMD_PATCH_TABLE_EXTERN                           \
    void HMDPatchTableDevelopDebugPoint(void);       \
    HMDPatchTableDevelopDebugPoint();                \
} while(0)
#else
#define DEVELOP_DEBUG_POINT
#endif
#endif

#ifndef DEVELOP_DEBUG_ASSERT
#ifdef DEBUG
#define DEVELOP_DEBUG_ASSERT(x) if(!(x)) DEVELOP_DEBUG_POINT
#else
#define DEVELOP_DEBUG_ASSERT(x)
#endif
#endif

#ifndef DEVELOP_DEBUG_RETURN
#ifdef DEBUG
#define DEVELOP_DEBUG_RETURN(x) do { DEVELOP_DEBUG_POINT; return (x); } while(0)
#else
#define DEVELOP_DEBUG_RETURN(x) return (x)
#endif
#endif

#ifndef DEVELOP_DEBUG_RETURN_NONE
#ifdef DEBUG
#define DEVELOP_DEBUG_RETURN_NONE do { DEVELOP_DEBUG_POINT; return; } while(0)
#else
#define DEVELOP_DEBUG_RETURN_NONE return
#endif
#endif

#pragma mark - typedef

#pragma mark shared cache

struct dyld_cache_header {
    char        magic[16];
    uint32_t    mappingOffset;
    uint32_t    mappingCount;
    uint32_t    imagesOffsetOld;
    uint32_t    imagesCountOld;
    uint64_t    dyldBaseAddress;
    uint64_t    codeSignatureOffset;
    uint64_t    codeSignatureSize;
    uint64_t    slideInfoOffsetUnused;
    uint64_t    slideInfoSizeUnused;
    uint64_t    localSymbolsOffset;
    uint64_t    localSymbolsSize;
    uint8_t     uuid[16];
    uint64_t    cacheType;
    uint32_t    branchPoolsOffset;
    uint32_t    branchPoolsCount;
    uint64_t    dyldInCacheMH;
    uint64_t    dyldInCacheEntry;
    uint64_t    imagesTextOffset;
    uint64_t    imagesTextCount;
    uint64_t    patchInfoAddr;
    uint64_t    patchInfoSize;
    uint64_t    otherImageGroupAddrUnused;
    uint64_t    otherImageGroupSizeUnused;
    uint64_t    progClosuresAddr;
    uint64_t    progClosuresSize;
    uint64_t    progClosuresTrieAddr;
    uint64_t    progClosuresTrieSize;
    uint32_t    platform;
    uint32_t    formatVersion          : 8,
                dylibsExpectedOnDisk   : 1,
                simulator              : 1,
                locallyBuiltCache      : 1,
                builtFromChainedFixups : 1,
                padding                : 20;
    uint64_t    sharedRegionStart;
    uint64_t    sharedRegionSize;
    uint64_t    maxSlide;
    uint64_t    dylibsImageArrayAddr;
    uint64_t    dylibsImageArraySize;
    uint64_t    dylibsTrieAddr;
    uint64_t    dylibsTrieSize;
    uint64_t    otherImageArrayAddr;
    uint64_t    otherImageArraySize;
    uint64_t    otherTrieAddr;
    uint64_t    otherTrieSize;
    uint32_t    mappingWithSlideOffset;
    uint32_t    mappingWithSlideCount;
    uint64_t    dylibsPBLStateArrayAddrUnused;
    uint64_t    dylibsPBLSetAddr;
    uint64_t    programsPBLSetPoolAddr;
    uint64_t    programsPBLSetPoolSize;
    uint64_t    programTrieAddr;
    uint32_t    programTrieSize;
    uint32_t    osVersion;
    uint32_t    altPlatform;
    uint32_t    altOsVersion;
    uint64_t    swiftOptsOffset;
    uint64_t    swiftOptsSize;
    uint32_t    subCacheArrayOffset;
    uint32_t    subCacheArrayCount;
    uint8_t     symbolFileUUID[16];
    uint64_t    rosettaReadOnlyAddr;
    uint64_t    rosettaReadOnlySize;
    uint64_t    rosettaReadWriteAddr;
    uint64_t    rosettaReadWriteSize;
    uint32_t    imagesOffset;
    uint32_t    imagesCount;
    uint32_t    cacheSubType;
    uint64_t    objcOptsOffset;
    uint64_t    objcOptsSize;
    uint64_t    cacheAtlasOffset;
    uint64_t    cacheAtlasSize;
    uint64_t    dynamicDataOffset;
    uint64_t    dynamicDataMaxSize;
};

typedef struct dyld_cache_header dyld_cache_header;

struct dyld_cache_mapping_info {
    uint64_t    address;
    uint64_t    size;
    uint64_t    fileOffset;
    uint32_t    maxProt;
    uint32_t    initProt;
};

typedef struct dyld_cache_mapping_info dyld_cache_mapping_info;

struct dyld_cache_image_info {
    uint64_t    address;
    uint64_t    modTime;
    uint64_t    inode;
    uint32_t    pathFileOffset;
    uint32_t    pad;
};

typedef struct dyld_cache_image_info dyld_cache_image_info;

struct dyld_cache_patch_info_v2 {
    uint32_t    patchTableVersion;
    uint32_t    patchLocationVersion;
    uint64_t    patchTableArrayAddr;
    uint64_t    patchTableArrayCount;
    uint64_t    patchImageExportsArrayAddr;
    uint64_t    patchImageExportsArrayCount;
    uint64_t    patchClientsArrayAddr;
    uint64_t    patchClientsArrayCount;
    uint64_t    patchClientExportsArrayAddr;
    uint64_t    patchClientExportsArrayCount;
    uint64_t    patchLocationArrayAddr;
    uint64_t    patchLocationArrayCount;
    uint64_t    patchExportNamesAddr;
    uint64_t    patchExportNamesSize;
};

typedef struct dyld_cache_patch_info_v2 dyld_cache_patch_info_v2;

struct dyld_cache_patch_info_v3 {
    uint32_t    patchTableVersion;
    uint32_t    patchLocationVersion;
    uint64_t    patchTableArrayAddr;
    uint64_t    patchTableArrayCount;
    uint64_t    patchImageExportsArrayAddr;
    uint64_t    patchImageExportsArrayCount;
    uint64_t    patchClientsArrayAddr;
    uint64_t    patchClientsArrayCount;
    uint64_t    patchClientExportsArrayAddr;
    uint64_t    patchClientExportsArrayCount;
    uint64_t    patchLocationArrayAddr;
    uint64_t    patchLocationArrayCount;
    uint64_t    patchExportNamesAddr;
    uint64_t    patchExportNamesSize;
    uint64_t    gotClientsArrayAddr;
    uint64_t    gotClientsArrayCount;
    uint64_t    gotClientExportsArrayAddr;
    uint64_t    gotClientExportsArrayCount;
    uint64_t    gotLocationArrayAddr;
    uint64_t    gotLocationArrayCount;
};

typedef struct dyld_cache_patch_info_v3 dyld_cache_patch_info_v3;

struct dyld_cache_image_got_clients_v3 {
    uint32_t    patchExportsStartIndex;
    uint32_t    patchExportsCount;
};

typedef struct dyld_cache_image_got_clients_v3 dyld_cache_image_got_clients_v3;

struct dyld_cache_patchable_export_v3 {
    uint32_t    imageExportIndex;
    uint32_t    patchLocationsStartIndex;
    uint32_t    patchLocationsCount;
};

typedef struct dyld_cache_patchable_export_v3 dyld_cache_patchable_export_v3;

struct dyld_cache_patchable_location_v3 {
    uint64_t    cacheOffsetOfUse;
    uint32_t    high7                   : 7,
                addend                  : 5,
                authenticated           : 1,
                usesAddressDiversity    : 1,
                key                     : 2,
                discriminator           : 16;
};

typedef struct dyld_cache_patchable_location_v3 dyld_cache_patchable_location_v3;

struct dyld_cache_image_text_info {
    uuid_t      uuid;
    uint64_t    loadAddress;
    uint32_t    textSegmentSize;
    uint32_t    pathOffset;
};

typedef struct dyld_cache_image_text_info dyld_cache_image_text_info;

struct dyld_cache_image_patches_v2 {
    uint32_t    patchClientsStartIndex;
    uint32_t    patchClientsCount;
    uint32_t    patchExportsStartIndex;
    uint32_t    patchExportsCount;
};

typedef struct dyld_cache_image_patches_v2 dyld_cache_image_patches_v2;

struct dyld_cache_image_clients_v2 {
    uint32_t    clientDylibIndex;
    uint32_t    patchExportsStartIndex;
    uint32_t    patchExportsCount;
};

typedef struct dyld_cache_image_clients_v2 dyld_cache_image_clients_v2;

struct dyld_cache_image_export_v2 {
    uint32_t    dylibOffsetOfImpl;
    uint32_t    exportNameOffset : 28;
    uint32_t    patchKind        : 4;
};

typedef struct dyld_cache_image_export_v2 dyld_cache_image_export_v2;

struct dyld_cache_patchable_export_v2 {
    uint32_t    imageExportIndex;
    uint32_t    patchLocationsStartIndex;
    uint32_t    patchLocationsCount;
};

typedef struct dyld_cache_patchable_export_v2 dyld_cache_patchable_export_v2;

struct dyld_cache_patchable_location_v2 {
    uint32_t    dylibOffsetOfUse;
    uint32_t    high7                   : 7,
                addend                  : 5,
                authenticated           : 1,
                usesAddressDiversity    : 1,
                key                     : 2,
                discriminator           : 16;
};

typedef struct dyld_cache_patchable_location_v2 dyld_cache_patchable_location_v2;

enum PatchKind : uint32_t {
    regular     = 0x0,
    cfObj2      = 0x1,
    objcClass   = 0x8
};

typedef enum PatchKind PatchKind;

struct PointerMetaData {
    uint32_t    diversity         : 16,
                high8             :  8,
                authenticated     :  1,
                key               :  2,
                usesAddrDiversity :  1;
};

typedef struct PointerMetaData PointerMetaData;

typedef struct dyld_cache_patch_info_v3 dyld_cache_patch_info_v4;

struct dyld_cache_patchable_location_v4 {
    uint32_t    dylibOffsetOfUse;
    uint32_t    auth_or_regular;
};

typedef struct dyld_cache_patchable_location_v4 dyld_cache_patchable_location_v4;

struct dyld_cache_patchable_location_v4_got {
    uint64_t    cacheOffsetOfUse;
    uint32_t    auth_or_regular;
    uint32_t    unusedPadding;
};

typedef struct dyld_cache_patchable_location_v4_got dyld_cache_patchable_location_v4_got;

struct hmd_auth_or_regular {
    union {
        uint32_t value;
        struct {
            uint32_t authenticated           : 1,
                     high7                   : 7,
                     isWeakImport            : 1,
                     addend                  : 5,
                     usesAddressDiversity    : 1,
                     keyIsD                  : 1,
                     discriminator           : 16;
        } auth;
        struct {
            uint32_t authenticated           : 1,
                     high7                   : 7,
                     isWeakImport            : 1,
                     addend                  : 23;
        } regular;
    };
};

typedef struct hmd_auth_or_regular hmd_auth_or_regular;

#if __LP64__

typedef struct mach_header_64 mach_header_t;
#define MH_MAGIC_VALUE MH_MAGIC_64
typedef struct segment_command_64 segment_command_t;
#define LC_SEGMENT_VALUE LC_SEGMENT_64
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;

#else

typedef struct mach_header mach_header_t;
#define MH_MAGIC_VALUE MH_MAGIC
typedef struct segment_command segment_command_t;
#define LC_SEGMENT_VALUE LC_SEGMENT
typedef struct section section_t;
typedef struct nlist nlist_t;

#endif

#pragma mark custom

typedef struct {
    struct dyld_all_image_infos *address;
    size_t size;
} HMDPatchTableTaskDyldInfoResult;

static const HMDPatchTableTaskDyldInfoResult HMDPatchTableTaskDyldInfoResultZero = {
    .address = NULL,
    .size = 0,
};

typedef enum : uint64_t {
    HMDPatchTableAtomicStatus_notDecided = 0,
    HMDPatchTableAtomicStatus_success,
    HMDPatchTableAtomicStatus_failed,
} HMDPatchTableAtomicStatus;

typedef bool (^HMDPatchTableAtomicAction)(void);

@implementation HMDPatchLocation

@dynamic diversity, high8, authenticated, key, useAddrDiversity;

- (uint32_t)diversity {
    COMPILE_ASSERT(sizeof(PointerMetaData) == sizeof(_metaData));
    PointerMetaData *metaData = (PointerMetaData *)&_metaData;
    return metaData->diversity;
}

- (uint32_t)high8 {
    COMPILE_ASSERT(sizeof(PointerMetaData) == sizeof(_metaData));
    PointerMetaData *metaData = (PointerMetaData *)&_metaData;
    return metaData->high8;
}

- (uint32_t)authenticated {
    COMPILE_ASSERT(sizeof(PointerMetaData) == sizeof(_metaData));
    PointerMetaData *metaData = (PointerMetaData *)&_metaData;
    return metaData->authenticated;
}

- (uint32_t)key {
    COMPILE_ASSERT(sizeof(PointerMetaData) == sizeof(_metaData));
    PointerMetaData *metaData = (PointerMetaData *)&_metaData;
    return metaData->key;
}

- (uint32_t)useAddrDiversity {
    COMPILE_ASSERT(sizeof(PointerMetaData) == sizeof(_metaData));
    PointerMetaData *metaData = (PointerMetaData *)&_metaData;
    return metaData->usesAddrDiversity;
}
- (instancetype _Nullable)initWithLocation:(void * _Nonnull)location
                                    addend:(uint64_t)addend
                                  metaData:(uint32_t)metaData
                                weakImport:(BOOL)weakImport {
    if(location == NULL) DEBUG_RETURN(nil);
    if(self = [super init]) {
        _location = location;
        _addend = addend;
        _metaData = metaData;
        _weakImport = weakImport;
    }
    return self;
}

- (BOOL)patchReplacement:(void *)replacement {
    if(_location == NULL) DEBUG_RETURN(NO);
    if(replacement == NULL) DEBUG_RETURN(NO);
    
    uintptr_t newValue = (uintptr_t)replacement + (uintptr_t)_addend;
    
    if(self.authenticated) {
        if([self supportSignPointer]) {
            newValue = [self signPointer:newValue
                                location:_location
                            useDiversity:self.useAddrDiversity
                               diversity:self.diversity
                                     key:self.key];
        }
    }
    
    kern_return_t protectReturn = vm_protect(mach_task_self(),
                                             mach_vm_trunc_page(_location),
                                             vm_page_size,
                                             false,
                                             VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if(protectReturn != KERN_SUCCESS) return NO;
    
    vm_size_t storage_size = sizeof(uintptr_t);
    if(vm_read_overwrite(mach_task_self(), (vm_address_t)&newValue, sizeof(uintptr_t), (vm_address_t)_location, &storage_size) == KERN_SUCCESS)
         return YES;
    else return NO;
}

- (BOOL)supportSignPointer {
#if __has_feature(ptrauth_calls)
    return YES;
#else
    return NO;
#endif
}

- (uintptr_t)signPointer:(uint64_t)unsignedAddr
                location:(void *)location
            useDiversity:(bool)usesAddrDiversity
               diversity:(uint16_t)diversity
                     key:(uint8_t)key {
    if(unsignedAddr == 0)  return 0;
    
#if __has_feature(ptrauth_calls)
    uint64_t extendedDiscriminator = diversity;
    if(usesAddrDiversity) extendedDiscriminator = __builtin_ptrauth_blend_discriminator(location, extendedDiscriminator);
    switch (key) {
        case 0: return (uintptr_t)__builtin_ptrauth_sign_unauthenticated((void*)unsignedAddr, 0, extendedDiscriminator);
        case 1: return (uintptr_t)__builtin_ptrauth_sign_unauthenticated((void*)unsignedAddr, 1, extendedDiscriminator);
        case 2: return (uintptr_t)__builtin_ptrauth_sign_unauthenticated((void*)unsignedAddr, 2, extendedDiscriminator);
        case 3: return (uintptr_t)__builtin_ptrauth_sign_unauthenticated((void*)unsignedAddr, 3, extendedDiscriminator);
    }
#endif
    DEBUG_RETURN(unsignedAddr);
}

@end

@implementation HMDPatchTable

+ (NSArray *)patchLocationsForSystemFunction:(void * _Nonnull)systemFunction {
    DEBUG_LOG("starting patch for system function %p", systemFunction);
    
    if(systemFunction == NULL) DEBUG_RETURN(nil);
    
    // header must exit
    dyld_cache_header * _Nullable header = [HMDPatchTable sharedCacheBaseSlided];
    if(header == NULL) DEBUG_RETURN(nil);
    
    // assume sub-cache exist
    if(header->mappingOffset < offsetof(dyld_cache_header, subCacheArrayCount)) DEBUG_RETURN(nil);
    
    // obtain shared range size
    size_t sharedCacheSize = header->sharedRegionSize;
    if(sharedCacheSize == 0) DEBUG_RETURN(nil);
    
    // function not within shared cache
    uintptr_t functionAddressRaw = (uintptr_t)systemFunction;
    if(functionAddressRaw < (uintptr_t)header || functionAddressRaw >= (uintptr_t)header + sharedCacheSize)
        DEBUG_RETURN(nil);
    
    uintptr_t sharedCacheOffsetOfReplacee = (uintptr_t)systemFunction - (uintptr_t)header;
    
    const dyld_cache_mapping_info *mappings = (dyld_cache_mapping_info *)((char *)header + header->mappingOffset);
    
    uint64_t slide = (uint64_t)header - mappings[0].address;
    
    uint64_t replaceeAddr_unslided = mappings[0].address + sharedCacheOffsetOfReplacee;
    
    const dyld_cache_image_text_info *imagesText = (dyld_cache_image_text_info *)((char *)header + header->imagesTextOffset);
    
    const dyld_cache_image_text_info *imagesTextEnd = &imagesText[header->imagesTextCount];
    
    uint32_t imageIndex = 0;
    bool found_imageIndex = false;
    for(const dyld_cache_image_text_info * p = imagesText; p < imagesTextEnd; ++p) {
        if((p->loadAddress <= replaceeAddr_unslided) && (replaceeAddr_unslided < p->loadAddress + p->textSegmentSize)) {
            imageIndex = (uint32_t)(p - imagesText);
            found_imageIndex = true;
            break;
        }
    }
    
    if(!found_imageIndex) DEBUG_RETURN(nil);
    
    DEBUG_LOG("systemFunction %p exist at image index %" PRIu32 "", systemFunction, imageIndex);
    
    dyld_cache_image_info * dylibs = NULL;
    
    uint32_t imagesCount;
    if (header->mappingOffset >= offsetof(dyld_cache_header, imagesCount)) {
        dylibs = (dyld_cache_image_info *)((char *)header + header->imagesOffset);
        imagesCount = header->imagesCount;
    } else {
        dylibs = (dyld_cache_image_info *)((char *)header + header->imagesOffsetOld);
        imagesCount = header->imagesCountOld;
    }
    
    if(imageIndex >= imagesCount) DEBUG_RETURN(nil);
    
    mach_header_t *macho_header = (mach_header_t *)(dylibs[imageIndex].address + slide);
    
    DEBUG_LOG("image index %" PRIu32 " path is %s", imageIndex,
              ((const char *)((uintptr_t)header + dylibs[imageIndex].pathFileOffset)));
    
    uint64_t textUnslidedLoadAddress = 0;
    bool is_textUnslidedAddress_found = false;
    
    segment_command_t *segmentCommand = (segment_command_t *)((char *)macho_header + sizeof(mach_header_t));
    for(size_t i = 0; i < macho_header->ncmds; i++){
        if(segmentCommand->cmd == LC_SEGMENT_VALUE){
            if(strcmp(segmentCommand->segname, SEG_TEXT) == 0){
                textUnslidedLoadAddress = segmentCommand->vmaddr;
                is_textUnslidedAddress_found = true;
                break;
            }
        }
        segmentCommand = (segment_command_t *)((char *)segmentCommand + segmentCommand->cmdsize);
    }
    
    if(!is_textUnslidedAddress_found) DEBUG_RETURN(nil);
    
    uint32_t dylibOffsetOfReplacee = (uint32_t)((mappings[0].address + sharedCacheOffsetOfReplacee) - textUnslidedLoadAddress);
    
    if(header->patchInfoAddr == 0) DEBUG_RETURN(nil);
    
    uint32_t patchInfoVersion;
    if (header->mappingOffset <= offsetof(dyld_cache_header, swiftOptsSize)) {
        patchInfoVersion = 1;
    } else {
        const dyld_cache_patch_info_v2 * patchInfo = (const dyld_cache_patch_info_v2 *)(header->patchInfoAddr + slide);
        patchInfoVersion = patchInfo->patchTableVersion;
    }
    
    if(patchInfoVersion != 3 && patchInfoVersion != 4)
        DEVELOP_DEBUG_RETURN(nil);
    
    uint64_t patchInfoAddrSlided = header->patchInfoAddr + slide;
    // uint64_t patchInfoAddr_unslided = header->patchInfoAddr;
    
    const dyld_cache_patch_info_v4 *patch_info = (const dyld_cache_patch_info_v4 *)patchInfoAddrSlided;
    
    const dyld_cache_image_patches_v2 *patch_images = (const dyld_cache_image_patches_v2 *)(patch_info->patchTableArrayAddr + slide);
    size_t patch_images_count = patch_info->patchTableArrayCount;
    
    if(imageIndex >= patch_images_count) DEBUG_RETURN(nil);
    
    const dyld_cache_image_patches_v2 * patch_image = patch_images + imageIndex;
    
    
    const dyld_cache_image_export_v2 *patch_export_images = (const dyld_cache_image_export_v2 *)(patch_info->patchImageExportsArrayAddr + slide);
    size_t patch_export_images_count = patch_info->patchImageExportsArrayCount;
    
    if(patch_image->patchExportsStartIndex + patch_image->patchExportsCount > patch_export_images_count)
        DEBUG_RETURN(nil);
    
    const dyld_cache_image_export_v2 *patch_export_images_subset = patch_export_images + patch_image->patchExportsStartIndex;
    size_t patch_export_images_subset_count = patch_image->patchExportsCount;
    
    /// TODO: validate range
    
    // const char *exported_string_names = (const char *)(patch_info->patchExportNamesAddr) + slide;
    // size_t exported_string_names_size = patch_info->patchExportNamesSize;
    
    bool found_match_symbols_in_dylib = false;
    
    for(size_t index = 0; index < patch_export_images_subset_count; index++) {
        const dyld_cache_image_export_v2 *patch_export_image = patch_export_images_subset + index;
        
        // const char *exportName = exported_string_names + patch_export_image->exportNameOffset;
        uint64_t dylibVMOffsetOfImpl = patch_export_image->dylibOffsetOfImpl;
//        PatchKind patchKind = patch_export_image->patchKind;
        
        if(dylibVMOffsetOfImpl != dylibOffsetOfReplacee) continue;
        
        DEBUG_ASSERT(!found_match_symbols_in_dylib);
        
        DEBUG_LOG("replace function %p name is %s", systemFunction,
                  (((const char *)(patch_info->patchExportNamesAddr) + slide) + patch_export_image->exportNameOffset));
        
        found_match_symbols_in_dylib = true;
    }
    
    if(!found_match_symbols_in_dylib) DEBUG_RETURN(nil);
    
    NSMutableArray<HMDPatchLocation *> *patchLocationArray = NSMutableArray.array;
    
#pragma mark got patch
    
    // DEBUG_LOG("starting GOT patch for function %p", systemFunction);
    
    const dyld_cache_image_got_clients_v3 *got_clients = (const dyld_cache_image_got_clients_v3 *)(patch_info->gotClientsArrayAddr + slide);
//    size_t got_clients_count = info->gotClientsArrayCount;
    
    const dyld_cache_image_got_clients_v3 *got_client = got_clients + imageIndex;
    
    const dyld_cache_patchable_export_v3 *got_client_exports = (const dyld_cache_patchable_export_v3 *)(patch_info->gotClientExportsArrayAddr + slide);
//    size_t got_client_exports_count = info->gotClientExportsArrayCount;
    
    const dyld_cache_patchable_export_v3 *got_client_exports_subset = got_client_exports + got_client->patchExportsStartIndex;
    size_t got_client_exports_subset_count = got_client->patchExportsCount;

    const void *got_patchable_locations_noVersion = (const void *)(patch_info->gotLocationArrayAddr + slide);
//    size_t got_patchable_locations_count = info->gotLocationArrayCount;
    
    if(got_client_exports_subset_count == 0)
        goto Label_exit_GOT_patch;
    
    const dyld_cache_patchable_export_v3 *foundClientExport = NULL;
    
    int64_t start = 0;
    int64_t end = (int64_t)got_client_exports_subset_count - 1;
    
    uint32_t dylibVMOffsetOfImpl = dylibOffsetOfReplacee;
    
    while ( start <= end ) {
        int64_t i = (start + end) / 2;

        const dyld_cache_patchable_export_v3 *clientExport = got_client_exports_subset + (uint32_t)i;
        const dyld_cache_image_export_v2 *imageExport = patch_export_images + clientExport->imageExportIndex;

        if ( imageExport->dylibOffsetOfImpl == dylibVMOffsetOfImpl ) {
            foundClientExport = clientExport;
            break;
        }

        if ( dylibVMOffsetOfImpl < imageExport->dylibOffsetOfImpl ) {
            end = i - 1;
        } else {
            start = i + 1;
        }
    }
    
    if(foundClientExport == NULL)
        goto Label_exit_GOT_patch;
    
    if(patchInfoVersion == 3) {
        const dyld_cache_patchable_location_v3 *got_patchable_locations = got_patchable_locations_noVersion;
        const dyld_cache_patchable_location_v3 *got_patchable_locations_subset = got_patchable_locations + foundClientExport->patchLocationsStartIndex;
        size_t got_patchable_locations_subset_count = foundClientExport->patchLocationsCount;
        
        for(size_t index = 0; index < got_patchable_locations_subset_count; index++) {
            const dyld_cache_patchable_location_v3 *got_patchable_location = got_patchable_locations_subset + index;
            
            PointerMetaData pmd = {
                .diversity         = got_patchable_location->discriminator,
                .high8             = got_patchable_location->high7 << 1,
                .authenticated     = got_patchable_location->authenticated,
                .key               = got_patchable_location->key,
                .usesAddrDiversity = got_patchable_location->usesAddressDiversity,
            };
            
            uint64_t unsignedAddend = got_patchable_location->addend;
            
            uint64_t cacheOffset = got_patchable_location -> cacheOffsetOfUse;
            
            uintptr_t *replacement_location = (uintptr_t *)((uintptr_t)header + cacheOffset);
            
            COMPILE_ASSERT(sizeof(PointerMetaData) == sizeof(uint32_t));
            COMPILE_ASSERT(_Alignof(PointerMetaData) == _Alignof(uint32_t));
            
            uint32_t metaData = ((uint32_t *)&pmd)[0];
            
            HMDPatchLocation *patchLocation = [[HMDPatchLocation alloc] initWithLocation:replacement_location
                                                                                  addend:unsignedAddend
                                                                                metaData:metaData
                                                                              weakImport:NO];
            
            if(patchLocation != nil) [patchLocationArray addObject:patchLocation];
        }
    } else if(patchInfoVersion == 4) {
        const dyld_cache_patchable_location_v4_got *got_patchable_locations = got_patchable_locations_noVersion;
        const dyld_cache_patchable_location_v4_got *got_patchable_locations_subset = got_patchable_locations + foundClientExport->patchLocationsStartIndex;
        size_t got_patchable_locations_subset_count = foundClientExport->patchLocationsCount;
        
        for(size_t index = 0; index < got_patchable_locations_subset_count; index++) {
            const dyld_cache_patchable_location_v4_got *got_patchable_location = got_patchable_locations_subset + index;
            
            COMPILE_ASSERT(sizeof(hmd_auth_or_regular) == sizeof(uint32_t));
            
            hmd_auth_or_regular auth_or_regular = {
                .value = got_patchable_location->auth_or_regular
            };
            
            DEBUG_ASSERT(auth_or_regular.value == got_patchable_location->auth_or_regular);
            
            PointerMetaData pmd;
            
            if(auth_or_regular.auth.authenticated) {
                pmd.diversity         = auth_or_regular.auth.discriminator;
                pmd.high8             = auth_or_regular.auth.high7 << 1;
                pmd.authenticated     = auth_or_regular.auth.authenticated;
                pmd.key               = auth_or_regular.auth.keyIsD ? 2 : 0;
                pmd.usesAddrDiversity = auth_or_regular.auth.usesAddressDiversity;
            } else {
                DEBUG_ASSERT(!auth_or_regular.regular.authenticated);
                pmd.diversity         = 0;
                pmd.high8             = auth_or_regular.regular.high7 << 1;
                pmd.authenticated     = 0;
                pmd.key               = 0;
                pmd.usesAddrDiversity = 0;
            }
            
            BOOL isWeakImport;
            if(auth_or_regular.auth.authenticated) {
                isWeakImport = auth_or_regular.auth.isWeakImport;
            } else {
                DEBUG_ASSERT(!auth_or_regular.regular.authenticated);
                isWeakImport = auth_or_regular.regular.isWeakImport;
            }
            
            uint64_t unsignedAddend;
            if(auth_or_regular.auth.authenticated) {
                unsignedAddend = auth_or_regular.auth.addend;
            } else {
                DEBUG_ASSERT(!auth_or_regular.regular.authenticated);
                unsignedAddend = auth_or_regular.regular.addend;
            }

            uint64_t cacheOffset = got_patchable_location -> cacheOffsetOfUse;

            uintptr_t *replacement_location = (uintptr_t *)((uintptr_t)header + cacheOffset);

            COMPILE_ASSERT(sizeof(PointerMetaData) == sizeof(uint32_t));
            COMPILE_ASSERT(_Alignof(PointerMetaData) == _Alignof(uint32_t));

            uint32_t metaData = ((uint32_t *)&pmd)[0];

            HMDPatchLocation *patchLocation = [[HMDPatchLocation alloc] initWithLocation:replacement_location
                                                                                  addend:unsignedAddend
                                                                                metaData:metaData
                                                                              weakImport:isWeakImport];

            if(patchLocation != nil) [patchLocationArray addObject:patchLocation];
        }
    }

Label_exit_GOT_patch:;

#pragma mark basic patch

    // DEBUG_LOG("starting basic patch for function %p", systemFunction);

    const dyld_cache_image_clients_v2 *clients = (const dyld_cache_image_clients_v2 *)(patch_info->patchClientsArrayAddr + slide);
//    size_t clients_count = info->patchClientsArrayCount;

    const dyld_cache_image_clients_v2 *clients_subset = clients + patch_image->patchClientsStartIndex;
    size_t clients_subset_count = patch_image->patchClientsCount;

    const dyld_cache_patchable_export_v2 *client_exports = (const dyld_cache_patchable_export_v2 *)(patch_info->patchClientExportsArrayAddr + slide);
//    size_t client_exports_count = info->patchClientExportsArrayCount;

    const void *patchable_locations_noVersion = (const void *)(patch_info->patchLocationArrayAddr + slide);
//    size_t patchable_locations_count = info->patchLocationArrayCount;

    for(size_t index = 0; index < clients_subset_count; index++) {
        const dyld_cache_image_clients_v2 *client = clients_subset + index;
        uint32_t clientDylibIndex = client->clientDylibIndex;

        mach_header_t *client_macho_header = (mach_header_t *)(dylibs[clientDylibIndex].address + slide);

//        char *client_macho_header_path = (char *)header + dylibs[clientDylibIndex].pathFileOffset;

        /// TODO: fix up ( I can't remember to fix up what?
        uint64_t clientUnslidedAddress = 0;
        segment_command_t *segmentPointer = (segment_command_t *)((char *)client_macho_header + sizeof(mach_header_t));
        for(size_t i = 0; i < client_macho_header->ncmds; i++){
            if(segmentPointer->cmd == LC_SEGMENT_VALUE){
                if(strcmp(segmentPointer->segname, SEG_TEXT) == 0){
                    clientUnslidedAddress = segmentPointer->vmaddr;
                    break;
                }
            }
            segmentPointer = (segment_command_t *)((char *)segmentPointer + segmentPointer->cmdsize);
        }

        if(clientUnslidedAddress == 0) DEBUG_RETURN(nil);

        const dyld_cache_patchable_export_v2 * client_exports_subset = client_exports + client->patchExportsStartIndex;
        size_t client_exports_subset_count = client->patchExportsCount;

        for(size_t index = 0; index < client_exports_subset_count; index++) {

            const dyld_cache_patchable_export_v2 * client_export = client_exports_subset + index;

            const dyld_cache_image_export_v2 *image_export = patch_export_images + client_export->imageExportIndex;

            uint32_t dylibVMOffsetOfImpl = dylibOffsetOfReplacee;

            if(image_export->dylibOffsetOfImpl != dylibVMOffsetOfImpl) continue;

            if(patchInfoVersion == 3) {
                const dyld_cache_patchable_location_v2 *patchable_locations = patchable_locations_noVersion;
                const dyld_cache_patchable_location_v2 *patchable_locations_subset = patchable_locations + client_export->patchLocationsStartIndex;
                size_t patchable_locations_subset_count = client_export->patchLocationsCount;

                for(size_t index = 0; index < patchable_locations_subset_count; index++) {
                    const dyld_cache_patchable_location_v2 *patchable_location = patchable_locations_subset + index;

                    // mappings[0].address
                    uint64_t cacheOffset = (clientUnslidedAddress + patchable_location->dylibOffsetOfUse) - mappings[0].address;

                    PointerMetaData pmd = {
                        .diversity         = patchable_location->discriminator,
                        .high8             = patchable_location->high7 << 1,
                        .authenticated     = patchable_location->authenticated,
                        .key               = patchable_location->key,
                        .usesAddrDiversity = patchable_location->usesAddressDiversity,
                    };

                    uint64_t unsignedAddend = patchable_location->addend;

                    uintptr_t *replacement_location = (uintptr_t *)((uintptr_t)header + cacheOffset);

                    COMPILE_ASSERT(sizeof(PointerMetaData) == sizeof(uint32_t));
                    COMPILE_ASSERT(_Alignof(PointerMetaData) == _Alignof(uint32_t));

                    uint32_t metaData = ((uint32_t *)&pmd)[0];

                    HMDPatchLocation *patchLocation = [[HMDPatchLocation alloc] initWithLocation:replacement_location
                                                                                          addend:unsignedAddend
                                                                                        metaData:metaData
                                                                                      weakImport:NO];

                    if(patchLocation != nil) [patchLocationArray addObject:patchLocation];
                }
            } else if(patchInfoVersion == 4) {
                const dyld_cache_patchable_location_v4 *patchable_locations = patchable_locations_noVersion;
                const dyld_cache_patchable_location_v4 *patchable_locations_subset = patchable_locations + client_export->patchLocationsStartIndex;
                size_t patchable_locations_subset_count = client_export->patchLocationsCount;

                for(size_t index = 0; index < patchable_locations_subset_count; index++) {
                    const dyld_cache_patchable_location_v4 *patchable_location = patchable_locations_subset + index;

                    COMPILE_ASSERT(sizeof(hmd_auth_or_regular) == sizeof(uint32_t));

                    hmd_auth_or_regular auth_or_regular = {
                        .value = patchable_location->auth_or_regular
                    };

                    DEBUG_ASSERT(auth_or_regular.value == patchable_location->auth_or_regular);

                    PointerMetaData pmd;

                    if(auth_or_regular.auth.authenticated) {
                        pmd.diversity         = auth_or_regular.auth.discriminator;
                        pmd.high8             = auth_or_regular.auth.high7 << 1;
                        pmd.authenticated     = auth_or_regular.auth.authenticated;
                        pmd.key               = auth_or_regular.auth.keyIsD ? 2 : 0;
                        pmd.usesAddrDiversity = auth_or_regular.auth.usesAddressDiversity;
                    } else {
                        DEBUG_ASSERT(!auth_or_regular.regular.authenticated);
                        pmd.diversity         = 0;
                        pmd.high8             = auth_or_regular.regular.high7 << 1;
                        pmd.authenticated     = 0;
                        pmd.key               = 0;
                        pmd.usesAddrDiversity = 0;
                    }

                    BOOL isWeakImport;
                    if(auth_or_regular.auth.authenticated) {
                        isWeakImport = auth_or_regular.auth.isWeakImport;
                    } else {
                        DEBUG_ASSERT(!auth_or_regular.regular.authenticated);
                        isWeakImport = auth_or_regular.regular.isWeakImport;
                    }

                    uint64_t unsignedAddend;
                    if(auth_or_regular.auth.authenticated) {
                        unsignedAddend = auth_or_regular.auth.addend;
                    } else {
                        DEBUG_ASSERT(!auth_or_regular.regular.authenticated);
                        unsignedAddend = auth_or_regular.regular.addend;
                    }
                    
                    // mappings[0].address
                    uint64_t cacheOffset = (clientUnslidedAddress + patchable_location->dylibOffsetOfUse) - mappings[0].address;
                    
                    uintptr_t *replacement_location = (uintptr_t *)((uintptr_t)header + cacheOffset);
                    
                    COMPILE_ASSERT(sizeof(PointerMetaData) == sizeof(uint32_t));
                    COMPILE_ASSERT(_Alignof(PointerMetaData) == _Alignof(uint32_t));
                    
                    uint32_t metaData = ((uint32_t *)&pmd)[0];
                    
                    HMDPatchLocation *patchLocation = [[HMDPatchLocation alloc] initWithLocation:replacement_location
                                                                                          addend:unsignedAddend
                                                                                        metaData:metaData
                                                                                      weakImport:isWeakImport];
                    
                    if(patchLocation != nil) [patchLocationArray addObject:patchLocation];
                }
            }
        }
    }
    
    return patchLocationArray;
}

#pragma mark - Supporting method

+ (dyld_cache_header * _Nullable)sharedCacheBaseSlided {
    
    static HMDPatchTableAtomicStatus atomicStatus = HMDPatchTableAtomicStatus_notDecided;
    static dyld_cache_header * _Nullable sharedResult = NULL;
    
    bool decidedResult = [HMDPatchTable atomicStatus:&atomicStatus action:^bool{
        
        HMDPatchTableTaskDyldInfoResult taskInfo = [HMDPatchTable taskDyldInfo];
        if(taskInfo.address != NULL && taskInfo.size >= offsetof(struct dyld_all_image_infos, sharedCacheBaseAddress)) {
            
            void * _Nullable sharedCacheBase;
            if((sharedCacheBase = (void *)taskInfo.address->sharedCacheBaseAddress) != NULL) {
                
                sharedResult = sharedCacheBase;
                return true;
                
            }
        }
        return false;
    }];
    
    // DEBUG_ASSERT(!decidedResult || sharedResult != NULL);
    
    if(decidedResult)
         return sharedResult;
    else return NULL;
}

+ (HMDPatchTableTaskDyldInfoResult)taskDyldInfo {
    
    static HMDPatchTableAtomicStatus atomicStatus = HMDPatchTableAtomicStatus_notDecided;
    static HMDPatchTableTaskDyldInfoResult sharedResult = {
        .address = NULL,
        .size = 0,
    };
    
    bool decidedResult = [HMDPatchTable atomicStatus:&atomicStatus action:^bool{
        task_flavor_t flavor = TASK_DYLD_INFO;
        struct task_dyld_info dyldInfo = {0};
        mach_msg_type_number_t dyldInfoCount = TASK_DYLD_INFO_COUNT;
        kern_return_t kr = 0;
        kr = task_info(mach_task_self(), flavor, (task_info_t)&dyldInfo, &dyldInfoCount);
        if(kr == KERN_SUCCESS) {
            if (dyldInfo.all_image_info_format == TASK_DYLD_ALL_IMAGE_INFO_32
             || dyldInfo.all_image_info_format == TASK_DYLD_ALL_IMAGE_INFO_64) {
                
                sharedResult.address = (struct dyld_all_image_infos *)dyldInfo.all_image_info_addr;
                sharedResult.size = dyldInfo.all_image_info_size;
                
                return true;
            }
        }
        DEBUG_RETURN(false);
    }];
    
    DEBUG_ASSERT(!decidedResult ||
                (sharedResult.address != NULL && sharedResult.size != 0));
    
    if(decidedResult)
         return sharedResult;
    else return HMDPatchTableTaskDyldInfoResultZero;
}

+ (bool)atomicStatus:(HMDPatchTableAtomicStatus * _Nonnull)atomicStatus
              action:(HMDPatchTableAtomicAction _Nonnull)action {
    
    if(atomicStatus == NULL || action == nil)
        DEBUG_RETURN(false);
    
    HMDPatchTableAtomicStatus status =
        __atomic_load_n(atomicStatus, __ATOMIC_ACQUIRE);
    
    switch(status) {
        case HMDPatchTableAtomicStatus_notDecided: {
            bool result = action();
            HMDPatchTableAtomicStatus newStatus = result ?
                HMDPatchTableAtomicStatus_success :
                HMDPatchTableAtomicStatus_failed;
            
            __atomic_store_n(atomicStatus, newStatus, __ATOMIC_RELEASE);
            return result;
        }
        case HMDPatchTableAtomicStatus_success:
            return true;
        case HMDPatchTableAtomicStatus_failed: default:
            return false;
    }
}

+ (void * _Nullable)searchSystemFunctionForName:(NSString * _Nonnull)name {
    if(name == nil) DEBUG_RETURN(NULL);
    
    // header must exit
    dyld_cache_header * _Nullable header = [HMDPatchTable sharedCacheBaseSlided];
    if(header == NULL) return NULL;
    
    // assume sub-cache exist
    if(header->mappingOffset < offsetof(dyld_cache_header, subCacheArrayCount)) DEBUG_RETURN(NULL);
    
    // obtain shared range size
    size_t sharedCacheSize = header->sharedRegionSize;
    if(sharedCacheSize == 0) DEBUG_RETURN(NULL);
    
    void * _Nullable function_ptr = dlsym(RTLD_DEFAULT, name.UTF8String);
    if(function_ptr == NULL) return NULL;
    
    // function not within shared cache
    uintptr_t functionAddressRaw = (uintptr_t)function_ptr;
    if(functionAddressRaw < (uintptr_t)header || functionAddressRaw >= (uintptr_t)header + sharedCacheSize)
        return NULL;
    
    return function_ptr;
}

@end

#ifdef DEBUG

#include <signal.h>

#if __arm64__ && __LP64__

asm(
".text\n"
".globl _HMDPatchTableDevelopDebugPoint\n"
".p2align 2\n"
"_HMDPatchTableDevelopDebugPoint:\n"
"    stp    x29, x30, [sp, #-16]!\n"
"    mov    x29, sp\n"
"    bl    _HMDPatchTable_isBeingTraced\n"
"    cbz    w0, Label_exit\n"
"    mov    w0, #2\n"
"    ldp    x29, x30, [sp], #16\n"
"    b    _raise\n"
"Label_exit:\n"
"    ldp    x29, x30, [sp], #16\n"
"    ret\n"
);

#elif __x86_64__

asm(
".text\n"
".globl _HMDPatchTableDevelopDebugPoint\n"
"_HMDPatchTableDevelopDebugPoint:\n"
"    pushq    %rbp\n"
"    movq    %rsp, %rbp\n"
"    callq    _HMDPatchTable_isBeingTraced\n"
"    testb    %al, %al\n"
"    je    Label_exit\n"
"    pushq    $2\n"
"    popq    %rdi\n"
"    popq    %rbp\n"
"    jmp    _raise\n"
"Label_exit:\n"
"    popq    %rbp\n"
"    retq\n"
);

#else

bool HMDPatchTable_isBeingTraced(void);

void HMDPatchTableDevelopDebugPoint(void) {
    if(!HMDPatchTable_isBeingTraced()) return;
    raise(SIGINT);
}

#endif

#import <sys/sysctl.h>

bool HMDPatchTable_isBeingTraced(void) {
    struct kinfo_proc procInfo;
    size_t structSize = sizeof(procInfo);
    int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};

    if (sysctl(mib, sizeof(mib) / sizeof(*mib), &procInfo, &structSize, NULL, 0) != 0) {
        return false;
    }

    return (procInfo.kp_proc.p_flag & P_TRACED) != 0;
}

#endif /* DEBUG */

#endif /* __LP64__ */
