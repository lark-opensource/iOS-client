// Copyright (c) 2013, Facebook, Inc.
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//   * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//   * Neither the name Facebook nor the names of its contributors may be used to
//     endorse or promote products derived from this software without specific
//     prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "BDFishhook.h"

#include <dlfcn.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach/vm_region.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <stdio.h>
#include <dispatch/dispatch.h>
#import <Foundation/Foundation.h>

#include "BDFishhookMacro.h"
#include "HMDPatchTable.h"

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

#ifndef SEG_DATA_CONST
#define SEG_DATA_CONST  "__DATA_CONST"
#endif

#ifndef SEG_AUTH_CONST
#define SEG_AUTH_CONST  "__AUTH_CONST"
#endif

#ifndef SECT_STUB_HELPER
#define SECT_STUB_HELPER  "__stub_helper"
#endif


static bool is_open_bdfishhook = false;
static bool is_open_bdfishhook_async_add_image_callback = false;
static bool is_open_bdfishhook_patch = false;

struct rebindings_entry {
    struct bd_rebinding *rebindings;
    size_t rebindings_nel;
    struct rebindings_entry *next;
};

struct fast_rebindings_entry {
    struct bd_rebinding_fast *rebindings;
    uint64_t rebindings_nel;
    struct fast_rebindings_entry *next;
};

struct stub_helper_adress_range {
    uintptr_t begin;
    uintptr_t end;
};

static struct rebindings_entry *_rebindings_head;

static struct fast_rebindings_entry *_fast_rebindings_head;

static dispatch_queue_t bd_fishhook_queue;

static int prepend_fast_rebindings(struct fast_rebindings_entry **rebindings_head,
                                   struct bd_rebinding_fast rebindings[],
                                   size_t  nel){
    struct fast_rebindings_entry *new_entry = (struct fast_rebindings_entry *) malloc(sizeof(struct fast_rebindings_entry));
    if (!new_entry) {
        return -1;
    }
    new_entry->rebindings = (struct bd_rebinding_fast *) malloc(sizeof(struct bd_rebinding_fast) * nel);
    if (!new_entry->rebindings) {
        free(new_entry);
        return -1;
    }
    memcpy(new_entry->rebindings, rebindings, sizeof(struct bd_rebinding_fast) * nel);
    new_entry->rebindings_nel = nel;
    new_entry->next = *rebindings_head;
    *rebindings_head = new_entry;
    return 0;
}

static int prepend_rebindings(struct rebindings_entry **rebindings_head,
        struct bd_rebinding rebindings[],
        size_t nel) {
    struct rebindings_entry *new_entry = (struct rebindings_entry *) malloc(sizeof(struct rebindings_entry));
    if (!new_entry) {
        return -1;
    }
    new_entry->rebindings = (struct bd_rebinding *) malloc(sizeof(struct bd_rebinding) * nel);
    if (!new_entry->rebindings) {
        free(new_entry);
        return -1;
    }
    memcpy(new_entry->rebindings, rebindings, sizeof(struct bd_rebinding) * nel);
    new_entry->rebindings_nel = nel;
    new_entry->next = *rebindings_head;
    *rebindings_head = new_entry;
    return 0;
}

static void perform_rebinding_with_section(struct rebindings_entry *rebindings,
        section_t *section,
        intptr_t slide,
        nlist_t *symtab,
        char *strtab,
        uint32_t *indirect_symtab,
        struct stub_helper_adress_range range) {
    uint32_t *indirect_symbol_indices = indirect_symtab + section->reserved1;

    void **indirect_symbol_bindings = (void **) ((uintptr_t) slide + section->addr);

    for (uint i = 0; i < section->size / sizeof(void *); i++) {
        uint32_t symtab_index = indirect_symbol_indices[i];
        if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL ||
                symtab_index == (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS)) {
            continue;
        }
        uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx;
        char *symbol_name = strtab + strtab_offset;
        bool symbol_name_longer_than_1 = symbol_name[0] && symbol_name[1];
        struct rebindings_entry *cur = rebindings;
        while (cur) {
            for (uint j = 0; j < cur->rebindings_nel; j++) {
                if (symbol_name_longer_than_1 && strcmp(&symbol_name[1], cur->rebindings[j].name) == 0) {
                    if (cur->rebindings[j].replaced != NULL &&
                        indirect_symbol_bindings[i] != cur->rebindings[j].replacement) {
                        if ((uintptr_t)indirect_symbol_bindings[i] >= range.begin &&
                            (uintptr_t)indirect_symbol_bindings[i] < range.end ) {
                            //should save original func to replaced for lazy symbol pointers
                            if (*(cur->rebindings[j].replaced) == NULL){
                                *(cur->rebindings[j].replaced) = indirect_symbol_bindings[i];
                            }
                        } else {
                            *(cur->rebindings[j].replaced) = indirect_symbol_bindings[i];
                        }
                    }
                    kern_return_t err = vm_protect (mach_task_self (), (uintptr_t)indirect_symbol_bindings, section->size, 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
                    if (err == KERN_SUCCESS) {
                        vm_size_t size = sizeof(cur->rebindings[j].replacement);
                        vm_address_t address = (vm_address_t)(indirect_symbol_bindings + i);
                        kern_return_t ret = vm_read_overwrite(mach_task_self(), (vm_address_t)(&cur->rebindings[j].replacement), size, (vm_address_t)(address), &size);
                        if (ret != KERN_SUCCESS) {
#ifdef DEBUG
                            DEBUG_LOG("[bd_fishhook]There is a mistake here when hook symbol %s, vm_read_overwrite err, overwrite address: %p, err code: %d\n", cur->rebindings[j].name, (void *)address, ret);
                            struct vm_region_basic_info_64 info;
                            mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
                            address = trunc_page(address);
                            size = round_page(size);
                            mach_port_t port;
                            kern_return_t kret = vm_region_64(mach_task_self(), &address, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_64_t)&info, &count, &port);
                            if (kret == KERN_SUCCESS){
                                printf("[bd_fishhook]vm_read_overwrite address: %p \n", (void *)address);
                                printf("[bd_fishhook]protection:");
                                if (info.protection & VM_PROT_READ) {
                                    printf("r");
                                }
                                if (info.protection & VM_PROT_WRITE) {
                                    printf("-w");
                                }
                                if (info.protection & VM_PROT_COPY) {
                                    printf("-c");
                                }
                                printf("\n[bd_fishhook]max protection:");
                                if (info.max_protection & VM_PROT_READ) {
                                    printf("r");
                                }
                                if (info.max_protection & VM_PROT_WRITE) {
                                    printf("-w");
                                }
                                if (info.max_protection & VM_PROT_COPY) {
                                    printf("-c");
                                }
                                printf("\n");
                            } else {
                                DEBUG_LOG("[bd_fishhook]There is a mistake here, vm_region_64 err, when vm_region_64 address: %p, err code: %d \n", (void *)address, kret);
                            }
#endif
                        }
                        //         indirect_symbol_bindings[i] = cur->rebindings[j].replacement;
                    }
                    goto symbol_loop;
                }
            }
            cur = cur->next;
        }
        symbol_loop:;
    }
}

static void perform_rebinding_with_section_fast(struct fast_rebindings_entry *rebindings,
        section_t *section,
        intptr_t slide) {

    void **indirect_symbol_bindings = (void **) ((uintptr_t) slide + section->addr);

    for (uint i = 0; i < section->size / sizeof(void *); i++) {
        struct fast_rebindings_entry *cur = rebindings;
        while (cur) {
            for (uint j = 0; j < cur->rebindings_nel; j++) {
                if (indirect_symbol_bindings[i] == cur->rebindings[j].original) {
                    if (cur->rebindings[j].replaced != NULL &&
                        indirect_symbol_bindings[i] != cur->rebindings[j].replacement){
                        *(cur->rebindings[j].replaced) = indirect_symbol_bindings[i];
                    }
                    kern_return_t err = vm_protect (mach_task_self (), (uintptr_t)indirect_symbol_bindings, section->size, 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
                    if (err == KERN_SUCCESS) {
                        vm_size_t size = sizeof(cur->rebindings[j].replacement);
                        vm_address_t address = (vm_address_t)(indirect_symbol_bindings + i);
                        kern_return_t ret = vm_read_overwrite(mach_task_self(), (vm_address_t)(&cur->rebindings[j].replacement), size, (vm_address_t)(address), &size);
                        if (ret != KERN_SUCCESS) {
#ifdef DEBUG
                            struct vm_region_basic_info_64 info;
                            mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
                            address = trunc_page(address);
                            size = round_page(size);
                            mach_port_t port;
                            kern_return_t kret = vm_region_64(mach_task_self(), &address, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_64_t)&info, &count, &port);
                            if (kret == KERN_SUCCESS){
                                printf("[bd_fishhook]vm_read_overwrite address: %p \n", (void *)address);
                                printf("[bd_fishhook]protection:");
                                if (info.protection & VM_PROT_READ) {
                                    printf("r");
                                }
                                if (info.protection & VM_PROT_WRITE) {
                                    printf("-w");
                                }
                                if (info.protection & VM_PROT_COPY) {
                                    printf("-c");
                                }
                                printf("\n[bd_fishhook]max protection:");
                                if (info.max_protection & VM_PROT_READ) {
                                    printf("r");
                                }
                                if (info.max_protection & VM_PROT_WRITE) {
                                    printf("-w");
                                }
                                if (info.max_protection & VM_PROT_COPY) {
                                    printf("-c");
                                }
                                printf("\n");
                            } else {
                                DEBUG_LOG("[bd_fishhook]There is a mistake here, vm_region_64 err, when vm_region_64 address: %p, err code: %d \n", (void *)address, kret);
                            }
#endif
                        }
                //         indirect_symbol_bindings[i] = cur->rebindings[j].replacement;
                    }
                    goto symbol_loop;
                }
            }
            cur = cur->next;
        }
        symbol_loop:;
    }
}

static void rebind_symbols_for_image_fast(struct fast_rebindings_entry *rebindings,
                                     const struct mach_header *header,
                                     intptr_t slide) {
    Dl_info info;
    if (dladdr(header, &info) == 0) {
        return;
    }
    segment_command_t *cur_seg_cmd;
    uintptr_t cur = (uintptr_t) header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *) cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_DATA) != 0 &&
                strcmp(cur_seg_cmd->segname, SEG_DATA_CONST) != 0 &&
                strcmp(cur_seg_cmd->segname, SEG_AUTH_CONST) != 0) {
                continue;
            }
            for (uint j = 0; j < cur_seg_cmd->nsects; j++) {
                section_t *sect =
                        (section_t *) (cur + sizeof(segment_command_t)) + j;
                if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
                    perform_rebinding_with_section_fast(rebindings, sect, slide);
                }
                if ((sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
                    perform_rebinding_with_section_fast(rebindings, sect, slide);
                }
            }
        }
    }
}



static void rebind_symbols_for_image(struct rebindings_entry *rebindings,
        const struct mach_header *header,
        intptr_t slide) {
    Dl_info info;
    if (dladdr(header, &info) == 0) {
        return;
    }

    segment_command_t *cur_seg_cmd;
    segment_command_t *linkedit_segment = NULL;
    struct symtab_command *symtab_cmd = NULL;
    struct dysymtab_command *dysymtab_cmd = NULL;
    section_t *sect_sub_helper = NULL;

    uintptr_t cur = (uintptr_t) header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *) cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit_segment = cur_seg_cmd;
            }
            for (uint j = 0; j < cur_seg_cmd->nsects; j++) {
                section_t *sect = (section_t *) (cur + sizeof(segment_command_t)) + j;
                if (strcmp(sect->sectname, SECT_STUB_HELPER) == 0) {
                    sect_sub_helper = sect;
                    break;
                }
            }
        } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
            symtab_cmd = (struct symtab_command *) cur_seg_cmd;
        } else if (cur_seg_cmd->cmd == LC_DYSYMTAB) {
            dysymtab_cmd = (struct dysymtab_command *) cur_seg_cmd;
        }
    }

    if (!symtab_cmd || !dysymtab_cmd || !linkedit_segment ||
            !dysymtab_cmd->nindirectsyms) {
        return;
    }

    // Find base symbol/string table addresses
    uintptr_t linkedit_base = (uintptr_t) slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
    nlist_t *symtab = (nlist_t *) (linkedit_base + symtab_cmd->symoff);
    char *strtab = (char *) (linkedit_base + symtab_cmd->stroff);
    struct stub_helper_adress_range stub_helper_range = {};
    if (sect_sub_helper) {
        stub_helper_range.begin = slide + sect_sub_helper->addr;
        stub_helper_range.end = slide + sect_sub_helper->addr + sect_sub_helper->size;
    }

    // Get indirect symbol table (array of uint32_t indices into symbol table)
    uint32_t *indirect_symtab = (uint32_t * )(linkedit_base + dysymtab_cmd->indirectsymoff);

    cur = (uintptr_t) header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *) cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_DATA) != 0 &&
                    strcmp(cur_seg_cmd->segname, SEG_DATA_CONST) != 0 &&
                    strcmp(cur_seg_cmd->segname, SEG_AUTH_CONST) != 0) {
                continue;
            }
            for (uint j = 0; j < cur_seg_cmd->nsects; j++) {
                section_t *sect =
                        (section_t *) (cur + sizeof(segment_command_t)) + j;
                if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
                    perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab, indirect_symtab, stub_helper_range);
                }
                if ((sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
                    perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab, indirect_symtab, stub_helper_range);
                }
//                else if (strcmp(sect->sectname, "__got") == 0) {
//                    perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab, indirect_symtab, stub_helper_range);
//                } else if (strcmp(sect->sectname, "__auth_got") == 0) {
//                    perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab, indirect_symtab, stub_helper_range);
//                }
            }
        }
    }
}

static void _rebind_symbols_for_image(const struct mach_header *header,
        intptr_t slide) {
    if (is_open_bdfishhook_async_add_image_callback) {
        dispatch_async(bd_fishhook_queue, ^{
            rebind_symbols_for_image(_rebindings_head, header, slide);
        });
    } else {
        rebind_symbols_for_image(_rebindings_head, header, slide);
    }
}

int bd_rebind_symbols_image(void *header,
        intptr_t slide,
        struct bd_rebinding rebindings[],
        size_t rebindings_nel) {
    if (!is_open_bdfishhook) {
        return -1;
    }
    struct rebindings_entry *rebindings_head = NULL;
    int retval = prepend_rebindings(&rebindings_head, rebindings, rebindings_nel);
    rebind_symbols_for_image(rebindings_head, (const struct mach_header *) header, slide);
    if (rebindings_head) {
        free(rebindings_head->rebindings);
    }
    free(rebindings_head);
    return retval;
}

int bd_rebind_symbols(struct bd_rebinding rebindings[], size_t rebindings_nel) {
    if (!is_open_bdfishhook) {
        return -1;
    }
    int retval = prepend_rebindings(&_rebindings_head, rebindings, rebindings_nel);
    if (retval < 0) {
        return retval;
    }
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        bd_fishhook_queue = dispatch_queue_create("com.bd_fishhook.rebind_symbols_image", DISPATCH_QUEUE_SERIAL);
    });
    // If this was the first call, register callback for image additions (which is also invoked for
    // existing images, otherwise, just run on existing images
    if (!_rebindings_head->next) {
        _dyld_register_func_for_add_image(_rebind_symbols_for_image);
    } else {
        uint32_t c = _dyld_image_count();
        for (uint32_t i = 0; i < c; i++) {
            rebind_symbols_for_image(_rebindings_head,_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i));
        }
    }
    return retval;
}

static void _rebind_symbols_for_image_fast(const struct mach_header *header,
                                      intptr_t slide) {
    rebind_symbols_for_image_fast(_fast_rebindings_head, header, slide);
}

int bd_rebind_symbols_image_fast(void *header, intptr_t slide, struct bd_rebinding_fast rebindings[], size_t rebindings_nel) {
    if (!is_open_bdfishhook) {
        return -1;
    }
    struct fast_rebindings_entry *rebindings_head = NULL;
    int retval = prepend_fast_rebindings(&rebindings_head, rebindings, rebindings_nel);
    rebind_symbols_for_image_fast(rebindings_head, (const struct mach_header *) header, slide);
    if (rebindings_head) {
        free(rebindings_head->rebindings);
    }
    free(rebindings_head);
    return retval;
}

int bd_rebind_fast(struct bd_rebinding_fast rebindings[] , size_t rebindings_nel) {
    if (!is_open_bdfishhook) {
        return -1;
    }
    int retval = prepend_fast_rebindings(&_fast_rebindings_head, rebindings, rebindings_nel);
    if (retval < 0) {
        return retval;
    }
    // If this was the first call, register callback for image additions (which is also invoked for
    // existing images, otherwise, just run on existing images
    if (!_fast_rebindings_head->next) {
        _dyld_register_func_for_add_image(_rebind_symbols_for_image_fast);
    } else {
        uint32_t c = _dyld_image_count();
        for (uint32_t i = 0; i < c; i++) {
            rebind_symbols_for_image_fast(_fast_rebindings_head,_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i));
        }
    }
    return retval;

}

int bd_rebind_symbols_patch(struct bd_rebinding rebindings[], size_t rebindings_nel) {
#if __arm64__ && __LP64__
    if (!is_open_bdfishhook) {
        return -1;
    }
    if (!is_open_bdfishhook_patch) {
        return -1;
    }
    static dispatch_once_t once_token;
    static bool is_available_ios16 = false;
    dispatch_once(&once_token, ^{
        if (@available(iOS 16.0, *)) {
            is_available_ios16 = true;
        }
    });
    if (!is_available_ios16) {
        return -1;
    }
    for(size_t i=0; i<rebindings_nel; i++) {
        NSString *symbol = [NSString stringWithUTF8String:rebindings[i].name];
        void* replaced = [HMDPatchTable searchSystemFunctionForName:symbol];
        if (replaced) {
            if (rebindings[i].replaced) {
                *(rebindings[i].replaced) = replaced;
            }
            NSArray<HMDPatchLocation *> *patchs = [HMDPatchTable patchLocationsForSystemFunction:replaced];
            if (patchs) {
                [patchs enumerateObjectsUsingBlock:^(HMDPatchLocation * _Nonnull patch, NSUInteger idx, BOOL * _Nonnull stop) {
                    [patch patchReplacement:rebindings[i].replacement];
                }];
            }
        }
    }
    return 1;
#else
    return -1;
#endif
}

void open_bdfishhook(void) {
    is_open_bdfishhook = true;
}

void close_bdfishhook(void) {
    is_open_bdfishhook = false;
}

void open_bdfishhook_async_add_image_callback(void) {
    is_open_bdfishhook_async_add_image_callback = true;
}

void close_bdfishhook_async_add_image_callback(void) {
    is_open_bdfishhook_async_add_image_callback = false;
}

void open_bdfishhook_patch(void) {
    is_open_bdfishhook_patch = true;
}

void close_bdfishhook_patch(void) {
    is_open_bdfishhook_patch = false;
}
