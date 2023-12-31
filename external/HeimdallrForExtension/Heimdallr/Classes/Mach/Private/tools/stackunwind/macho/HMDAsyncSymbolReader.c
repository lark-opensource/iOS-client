//
//  HMDAsyncSymbolReader.c
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/3.
//

#include "HMDAsyncSymbolReader.h"

#include "hmd_logger.h"
/**
 * @internal
 * Common wrapper of nlist/nlist_64. We verify that this union is valid for our purposes in
 * hmd_async_macho_find_symtab_symbol().
 */
typedef union {
    struct nlist_64 n64;
    struct nlist n32;
} hmd_nlist_common;

/**
 * Initialize a new symbol table reader, mapping the LINKEDIT segment from @a image into the current process.
 *
 * @param reader The reader to be initialized.
 * @param image The image from which the symbol table will be mapped.
 *
 * @return On success, returns HMD_ESUCCESS. On failure, one of the hmd_error_t error values will be returned, and no
 * mapping will be performed.
 */
hmd_error_t hmd_async_macho_symtab_reader_init(hmd_async_macho_symtab_reader_t *reader, hmd_async_macho_t *image) {
    hmd_error_t retval;

    /* Fetch the symtab commands, if available. */
    struct symtab_command *symtab_cmd = hmd_async_macho_find_command(image, LC_SYMTAB);
    struct dysymtab_command *dysymtab_cmd = hmd_async_macho_find_command(image, LC_DYSYMTAB);

    /* The symtab command is required */
    if (symtab_cmd == NULL) {
        HMDLOG_ERROR("could not find LC_SYMTAB load command");
        return HMD_ENOTFOUND;
    }

    /* Map in the __LINKEDIT segment, which includes the symbol and string tables */
    hmd_error_t err = hmd_async_macho_find_segment(image, SEG_LINKEDIT, &reader->linkedit);
    if (err != HMD_ESUCCESS) {
        HMDLOG_ERROR("hmd_async_mobject_init() failure: %d in %s", err, image->name);
        return HMD_EINTERNAL;
    }

    /* Determine the string and symbol table sizes. */
    uint32_t nsyms = image->byteorder->swap32(symtab_cmd->nsyms);
    size_t nlist_struct_size = image->m64 ? sizeof(struct nlist_64) : sizeof(struct nlist);
    size_t nlist_table_size = nsyms * nlist_struct_size;

    size_t string_size = image->byteorder->swap32(symtab_cmd->strsize);

    /* Fetch pointers to the symbol and string tables, and verify their size values */
    void *nlist_table;
    char *string_table;

    nlist_table = hmd_async_mem_range_pointer(reader->linkedit.obj, (hmd_vm_off_t)(image->byteorder->swap32(symtab_cmd->symoff) - reader->linkedit.fileoff), nlist_table_size);
    if (nlist_table == NULL) {
        HMDLOG_ERROR("hmd_async_mobject_remap_address(mobj, %p, %p) returned NULL mapping __LINKEDIT.symoff in %s",
                     (uint64_t)reader->linkedit.obj.addr + image->byteorder->swap32(symtab_cmd->symoff),
                     (uint64_t)nlist_table_size, image->name);
        retval = HMD_EINTERNAL;
        goto cleanup;
    }

    string_table = hmd_async_mem_range_pointer(reader->linkedit.obj,
        (hmd_vm_off_t)(image->byteorder->swap32(symtab_cmd->stroff) - reader->linkedit.fileoff), string_size);
    if (string_table == NULL) {
        HMDLOG_ERROR("hmd_async_mobject_remap_address(mobj, %p, %p) returned NULL mapping __LINKEDIT.stroff in %s",
                     (uint64_t)reader->linkedit.obj.addr + image->byteorder->swap32(symtab_cmd->stroff),
                     (uint64_t)string_size, image->name);
        retval = HMD_EINTERNAL;
        goto cleanup;
    }

    /* Initialize common elements. */
    reader->image = image;
    reader->string_table = string_table;
    reader->string_table_size = string_size;
    reader->symtab = nlist_table;
    reader->nsyms = nsyms;

    /* Initialize the local/global table pointers, if available */
    if (dysymtab_cmd != NULL) {
        /* dysymtab is available; use it to constrain our symbol search to the global and local sections of the symbol
         * table. */

        uint32_t idx_syms_global = image->byteorder->swap32(dysymtab_cmd->iextdefsym);
        uint32_t idx_syms_local = image->byteorder->swap32(dysymtab_cmd->ilocalsym);

        uint32_t nsyms_global = image->byteorder->swap32(dysymtab_cmd->nextdefsym);
        uint32_t nsyms_local = image->byteorder->swap32(dysymtab_cmd->nlocalsym);

        /* Sanity check the symbol offsets to ensure they're within our known-valid ranges */
        if (idx_syms_global + nsyms_global > nsyms || idx_syms_local + nsyms_local > nsyms) {
            HMDLOG_ERROR("iextdefsym=%p, ilocalsym=%p out of range nsym=%p",
                         idx_syms_global + nsyms_global, idx_syms_local + nsyms_local, nsyms);
            retval = HMD_EINVAL;
            goto cleanup;
        }

        /* Initialize reader state */
        reader->nsyms_global = nsyms_global;
        reader->nsyms_local = nsyms_local;

        if (image->m64) {
            struct nlist_64 *n64 = nlist_table;
            reader->symtab_global = (hmd_nlist_common *)(n64 + idx_syms_global);
            reader->symtab_local = (hmd_nlist_common *)(n64 + idx_syms_local);
        } else {
            struct nlist *n32 = nlist_table;
            reader->symtab_global = (hmd_nlist_common *)(n32 + idx_syms_global);
            reader->symtab_local = (hmd_nlist_common *)(n32 + idx_syms_local);
        }
    }

    return HMD_ESUCCESS;

cleanup:
    return retval;
}

/**
 * Fetch the entry corresponding to @a index.
 *
 * @param reader The reader from which @a table was mapped.
 * @param symtab The symbol table to read.
 * @param index The index of the entry to return.
 *
 * @warning The implementation implements no bounds checking on @a index, and it is the caller's responsibility to
 * ensure that they do not read an invalid entry.
 */
hmd_async_macho_symtab_entry_t hmd_async_macho_symtab_reader_read(hmd_async_macho_symtab_reader_t *reader, void *symtab,
                                                                  uint32_t index) {
    const hmd_async_byteorder_t *byteorder = reader->image->byteorder;

    /* nlist_64 and nlist are identical other than the trailing address field, so we use
     * a union to share a common implementation of symbol lookup. The following asserts
     * provide a sanity-check of that assumption, in the case where this code is moved
     * to a new platform ABI. */
    {
#define hmd_m_sizeof(type, field) sizeof(((type *)NULL)->field)

        HMDCF_ASSERT(__offsetof(struct nlist_64, n_type) == __offsetof(struct nlist, n_type));
        HMDCF_ASSERT(hmd_m_sizeof(struct nlist_64, n_type) == hmd_m_sizeof(struct nlist, n_type));

        HMDCF_ASSERT(__offsetof(struct nlist_64, n_un.n_strx) == __offsetof(struct nlist, n_un.n_strx));
        HMDCF_ASSERT(hmd_m_sizeof(struct nlist_64, n_un.n_strx) == hmd_m_sizeof(struct nlist, n_un.n_strx));

        HMDCF_ASSERT(__offsetof(struct nlist_64, n_value) == __offsetof(struct nlist, n_value));

#undef hmd_m_sizeof
    }

#define hmd_sym_value(image, nl) \
    (image->m64 ? image->byteorder->swap64((nl)->n64.n_value) : image->byteorder->swap32((nl)->n32.n_value))

    /* Perform 32-bit/64-bit dependent aliased pointer math. */
    hmd_nlist_common *symbol;
    if (reader->image->m64) {
        symbol = (hmd_nlist_common *)&(((struct nlist_64 *)symtab)[index]);
    } else {
        symbol = (hmd_nlist_common *)&(((struct nlist *)symtab)[index]);
    }

    hmd_async_macho_symtab_entry_t entry = {.n_strx = byteorder->swap32(symbol->n32.n_un.n_strx),
                                            .n_type = symbol->n32.n_type,
                                            .n_sect = symbol->n32.n_sect,
                                            .n_desc = byteorder->swap16(symbol->n32.n_desc),
                                            .n_value = (hmd_vm_address_t)hmd_sym_value(reader->image, symbol)};

    entry.normalized_value = entry.n_value;

    /* Normalize the symbol address. We have to set the low-order bit ourselves for ARM THUMB functions. */
    if (entry.n_desc & N_ARM_THUMB_DEF)
        entry.normalized_value = (entry.n_value | 1);
    else
        entry.normalized_value = entry.n_value;

#undef hmd_sym_value

    return entry;
}

/**
 * Given a string table offset for @a reader, returns the pointer to the validated NULL terminated string, or returns
 * NULL if the string does not fall within the reader's mapped string table.
 *
 * @param reader The reader containing a mapped string table.
 * @param n_strx The index within the @a reader string table to a symbol name.
 */
const char *hmd_async_macho_symtab_reader_symbol_name(hmd_async_macho_symtab_reader_t *reader, uint32_t n_strx) {
    /*
     * It's possible, though unlikely, that the n_strx index value is invalid. To handle this,
     * we walk the string until \0 is hit, verifying that it can be found in its entirety within
     *
     * TODO: Evaluate effeciency of per-byte calling of hmd_async_mobject_verify_local_pointer(). We should
     * probably validate whole pages at a time instead.
     */
    const char *sym_name = reader->string_table + n_strx;
    const char *p = sym_name;
    do {
        if (!hmd_async_mem_range_verify(reader->linkedit.obj, (hmd_vm_address_t)p, 1)) {
            HMDLOG_ERROR("End of mobject reached while walking string\n");
            return NULL;
        }
        p++;
    } while (*p != '\0');

    return sym_name;
}

/*
 * Locate a symtab entry for @a slide_pc within @a symbtab. This is performed using best-guess heuristics, and may
 * be incorrect.
 *
 * @param reader The Mach-O symbol table reader to search for @a pc
 * @param slide_pc The PC value within the target process for which symbol information should be found. The VM slide
 * address should have already been applied to this value.
 * @param symtab The symtab to search.
 * @param nsyms The number of nlist entries available via @a symtab.
 * @param found_symbol On success, will be set to the discovered symbol value.
 * @param prev_symbol A reference to the previous best match symbol.
 * @param did_find_symbol On success, will be set to true. This value must be passed to
 * the next call in which @a found_symbol is used.
 *
 * @return Returns true if a symbol was found, false otherwise.
 */
static void hmd_async_macho_find_best_symbol(hmd_async_macho_symtab_reader_t *reader, hmd_vm_address_t slide_pc,
                                             hmd_nlist_common *symtab, uint32_t nsyms,
                                             hmd_async_macho_symtab_entry_t *found_symbol,
                                             hmd_async_macho_symtab_entry_t *prev_symbol, bool *did_find_symbol) {
    hmd_async_macho_symtab_entry_t new_entry;

    /* Set did_find_symbol to false by default */
    if (prev_symbol == NULL) *did_find_symbol = false;

    /* Walk the symbol table. We know that symbols[i] is valid, since we fetched a pointer+len based on the value using
     * hmd_async_mobject_remap_address() above. */
    for (uint32_t i = 0; i < nsyms; i++) {
        new_entry = hmd_async_macho_symtab_reader_read(reader, symtab, i);

        /* Symbol must be within a section, and must not be a debugging entry. */
        if ((new_entry.n_type & N_TYPE) != N_SECT || ((new_entry.n_type & N_STAB) != 0)) continue;

        /* Search for the best match. We're looking for the closest symbol occuring before PC. */
        if (new_entry.n_value <= slide_pc && (!*did_find_symbol || prev_symbol->n_value < new_entry.n_value)) {
            *found_symbol = new_entry;

            /* The newly found symbol is now the symbol to be matched against */
            prev_symbol = found_symbol;
            *did_find_symbol = true;
        }
    }
}

static void hmd_async_macho_find_symbol_range(hmd_async_macho_symtab_reader_t *reader,const char *symbol,
                                             hmd_nlist_common *symtab, uint32_t nsyms,
                                             hmd_async_macho_symtab_entry_t *found_symbol,
                                             hmd_async_macho_symtab_entry_t *prev_symbol, bool *did_find_symbol) {
    hmd_async_macho_symtab_entry_t new_entry;

    /* prev_symbol found_symbol con't be NULL */
    if (prev_symbol == NULL || found_symbol == NULL) {
        *did_find_symbol = false;
        return;
    }

    /* Walk the symbol table. We know that symbols[i] is valid, since we fetched a pointer+len based on the value using
     * hmd_async_mobject_remap_address() above. */
    for (uint32_t i = 0; i < nsyms; i++) {
        new_entry = hmd_async_macho_symtab_reader_read(reader, symtab, i);

        /* Symbol must be within a section, and must not be a debugging entry. */
        if ((new_entry.n_type & N_TYPE) != N_SECT || ((new_entry.n_type & N_STAB) != 0)) continue;

        const char *sym_name = hmd_async_macho_symtab_reader_symbol_name(reader, new_entry.n_strx);
        if (sym_name != NULL && strcmp(sym_name, symbol) == 0){
            *found_symbol = new_entry;
            *did_find_symbol = true;
            break;
        }
    }
    if (!*did_find_symbol){
        return;
    }
    bool did_find_end_adress = false;
    for (uint32_t i = 0; i < nsyms; i++) {
        new_entry = hmd_async_macho_symtab_reader_read(reader, symtab, i);

        /* Symbol must be within a section, and must not be a debugging entry. */
        if ((new_entry.n_type & N_TYPE) != N_SECT || ((new_entry.n_type & N_STAB) != 0)) continue;
        
        if (new_entry.n_value > found_symbol->n_value && (!did_find_end_adress || new_entry.n_value < prev_symbol->n_value)) {
            *prev_symbol = new_entry;
            did_find_end_adress = true;
        }
    }
}

/**
 * Attempt to locate a symbol address and name for @a pc within @a image. This is performed using best-guess heuristics,
 * and may be incorrect.
 *
 * @param image The Mach-O image to search for @a pc
 * @param pc The PC value within the target process for which symbol information should be found.
 * @param symbol_cb A callback to be called if the symbol is found.
 * @param context Context to be passed to @a found_symbol.
 *
 * @return Returns HMD_ESUCCESS if the symbol is found. If the symbol is not found, @a found_symbol will not be called.
 *
 * @todo Migrate this API to use the new non-callback based hmd_async_macho_symtab_reader support for symbol (and symbol
 * name) reading.
 */
hmd_error_t hmd_async_macho_find_symbol_by_pc(hmd_async_macho_t *image, hmd_vm_address_t pc,
                                              hmd_async_macho_found_symbol_cb symbol_cb, void *context) {
    hmd_error_t retval;

    /* Initialize a symbol table reader */
    hmd_async_macho_symtab_reader_t reader;
    retval = hmd_async_macho_symtab_reader_init(&reader, image);
    if (retval != HMD_ESUCCESS) return retval;

    /* Compute the on-disk PC. */
    hmd_vm_address_t slide_pc = pc - image->vmaddr_slide;

    /* Walk the symbol table. */
    hmd_async_macho_symtab_entry_t found_symbol;
    bool did_find_symbol;

    if (reader.symtab_global != NULL && reader.symtab_local != NULL) {
        /* dysymtab is available; use it to constrain our symbol search to the global and local sections of the symbol
         * table. */
        hmd_async_macho_find_best_symbol(&reader, slide_pc, reader.symtab_global, reader.nsyms_global, &found_symbol,
                                         NULL, &did_find_symbol);
        hmd_async_macho_find_best_symbol(&reader, slide_pc, reader.symtab_local, reader.nsyms_local, &found_symbol,
                                         &found_symbol, &did_find_symbol);
    } else {
        /* If dysymtab is not available, search all symbols */
        hmd_async_macho_find_best_symbol(&reader, slide_pc, reader.symtab, reader.nsyms, &found_symbol, NULL,
                                         &did_find_symbol);
    }

    /* No symbol found. */
    if (!did_find_symbol) {
        retval = HMD_ENOTFOUND;
        goto cleanup;
    }

    /* Symbol found! */
    const char *sym_name = hmd_async_macho_symtab_reader_symbol_name(&reader, found_symbol.n_strx);
    if (sym_name == NULL) {
        HMDLOG_ERROR("Failed to read symbol name\n");
        retval = HMD_EINVAL;
        goto cleanup;
    }

    /* Inform our caller */
    symbol_cb(found_symbol.normalized_value + image->vmaddr_slide, sym_name, context);

    // fall through to cleanup
    retval = HMD_ESUCCESS;

cleanup:
    return retval;
}

hmd_error_t hmd_async_macho_find_range_by_symbol(hmd_async_macho_t *image,const char *symbol,
                                                 hmd_async_macho_found_range_cb range_cb, void *context) {
    hmd_error_t retval;

    /* Initialize a symbol table reader */
    hmd_async_macho_symtab_reader_t reader;
    retval = hmd_async_macho_symtab_reader_init(&reader, image);
    if (retval != HMD_ESUCCESS) return retval;

    /* Walk the symbol table. */
    hmd_async_macho_symtab_entry_t found_symbol;
    hmd_async_macho_symtab_entry_t prev_symbol;
    bool did_find_symbol;

    if (reader.symtab_global != NULL) {
        /* dysymtab is available; use it to constrain our symbol search to the global and local sections of the symbol
         * table. */
        hmd_async_macho_find_symbol_range(&reader, symbol, reader.symtab_global, reader.nsyms_global, &found_symbol,
                                          &prev_symbol, &did_find_symbol);
        if (!did_find_symbol && reader.symtab_local != NULL){
            hmd_async_macho_find_symbol_range(&reader, symbol, reader.symtab_local, reader.nsyms_local, &found_symbol,
                                              &prev_symbol, &did_find_symbol);
        }
    } else {
        /* If dysymtab is not available, search all symbols */
        hmd_async_macho_find_symbol_range(&reader, symbol, reader.symtab, reader.nsyms, &found_symbol, &prev_symbol,
                                         &did_find_symbol);
    }

    /* No symbol found. */
    if (!did_find_symbol) {
        retval = HMD_ENOTFOUND;
        goto cleanup;
    }

    /* Inform our caller */
    range_cb(found_symbol.normalized_value + image->vmaddr_slide, prev_symbol.normalized_value + image->vmaddr_slide, symbol, context);

    // fall through to cleanup
    retval = HMD_ESUCCESS;

cleanup:
    return retval;
}
