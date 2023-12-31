//
//  HMDAsyncSymbolReader.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/3.
//

#ifndef HMDAsyncSymbolReader_h
#define HMDAsyncSymbolReader_h

#include <stdio.h>
#include "hmd_types.h"
#include "HMDAsyncMachOImage.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @internal
 *
 * A 32-bit/64-bit neutral symbol table entry. The values will be returned in host byte order.
 */
typedef struct hmd_async_macho_symtab_entry {
    /* Index into the string table */
    uint32_t n_strx;

    /** Symbol type. */
    uint8_t n_type;

    /** Section number. */
    uint8_t n_sect;

    /** Description (see <mach-o/stab.h>). */
    uint16_t n_desc;

    /** Symbol value */
    hmd_vm_address_t n_value;

    /**
     * The normalized symbol address. This will include any required bit flags -- such as the ARM thumb high-order
     * bit -- which are not included in the symbol table by default.
     */
    hmd_vm_address_t normalized_value;
} hmd_async_macho_symtab_entry_t;

/**
 * @internal
 *
 * A Mach-O symtab reader. Provides support for iterating the contents of a Mach-O symbol table.
 */
typedef struct hmd_async_macho_symtab_reader {
    /** The image from which the symbol table has been mapped. */
    hmd_async_macho_t *image;

    /** The mapped LINKEDIT segment. */
    hmd_async_macho_segment_t linkedit;

    /** Pointer to the symtab table within the mapped linkedit segment. The validity of this pointer (and the length of
     * data available) is gauranteed. */
    void *symtab;

    /** Total number of elements in the symtab. */
    uint32_t nsyms;

    /** Pointer to the global symbol table, if available. May be NULL. The validity of this pointer (and the length of
     * data available) is gauranteed. If non-NULL, symtab_local must also be non-NULL. */
    void *symtab_global;

    /** Total number of elements in the global symtab. */
    uint32_t nsyms_global;

    /** Pointer to the local symbol table, if available. May be NULL. The validity of this pointer (and the length of
     * data available) is gauranteed. If non-NULL, symtab_global must also be non-NULL. */
    void *symtab_local;

    /** Total number of elements in the local symtab. */
    uint32_t nsyms_local;

    /** The mapped string table. The validity of this pointer (and the length of
     * data available) is gauranteed. */
    char *string_table;

    /** The string table's size, in bytes. */
    size_t string_table_size;
} hmd_async_macho_symtab_reader_t;


typedef void (*hmd_async_macho_found_symbol_cb)(hmd_vm_address_t address, const char *name, void *ctx);

typedef void (*hmd_async_macho_found_range_cb)(hmd_vm_address_t start_address, hmd_vm_address_t end_address, const char *name, void *ctx);

hmd_error_t hmd_async_macho_find_symbol_by_pc(hmd_async_macho_t *image, hmd_vm_address_t pc,
                                              hmd_async_macho_found_symbol_cb symbol_cb, void *context);

hmd_error_t hmd_async_macho_find_range_by_symbol(hmd_async_macho_t *image,const char *symbol,
                                                 hmd_async_macho_found_range_cb range_cb, void *context);

hmd_error_t hmd_async_macho_symtab_reader_init(hmd_async_macho_symtab_reader_t *reader, hmd_async_macho_t *image);
hmd_async_macho_symtab_entry_t hmd_async_macho_symtab_reader_read(hmd_async_macho_symtab_reader_t *reader, void *symtab,
                                                                  uint32_t index);
const char *hmd_async_macho_symtab_reader_symbol_name(hmd_async_macho_symtab_reader_t *reader, uint32_t n_strx);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDAsyncSymbolReader_h */
