//
//  HMDAsyncCompactUnwindEncoding.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#include "HMDAsyncCompactUnwindEncoding.h"

#if HMD_USE_COMPACT_UNWIND

#include "HMDCompatConstants.h"
#define HMDLogger_LocalLevel INFO
#include <inttypes.h>
#include "hmd_logger.h"
#include "HMDAsyncDwarfUnwind.h"
/**
 * @internal
 * @ingroup hmd_async
 * @defgroup hmd_async_cfe Compact Frame Encoding
 *
 * Implements async-safe parsing of compact frame unwind encodings.
 * @{
 */

/**
 * @internal
 * A CFE reader instance. Performs CFE data parsing from a backing memory object.
 */
typedef struct hmd_async_cfe_reader {
    /** A memory object containing the CFE data at the starting address. */
    hmd_async_mem_range unwind_info;

    /** The target CPU type. */
    cpu_type_t cpu_type;

    /** The unwind info header. Note that the header values may require byte-swapping for the local process' use. */
    struct unwind_info_section_header header;

    /** The byte order of the encoded data (including the header). */
    const hmd_async_byteorder_t *byteorder;
} hmd_async_cfe_reader_t;

/**
 * Supported CFE entry formats.
 */
typedef enum {
    /**
     * The frame pointer (fp) is valid. To walk the stack, the previous frame pointer may be popped from
     * the current frame pointer, followed by the return address.
     *
     * All non-volatile registers that need to be restored will be saved on the stack, ranging from fp±regsize through
     * fp±1020. The actual direction depends on the stack growth direction of the target platform.
     */
    HMD_ASYNC_CFE_ENTRY_TYPE_FRAME_PTR = 1,

    /**
     * The frame pointer (eg, ebp/rbp) is invalid, but the stack size is constant and is small enough (<= 1024) that it
     * may be encoded in the CFE entry itself.
     *
     * The return address may be found at the provided ± offset from the stack pointer, followed all non-volatile
     * registers that need to be restored. The actual direction of the offset depends on the stack growth direction of
     * the target platform.
     */
    HMD_ASYNC_CFE_ENTRY_TYPE_FRAMELESS = 2,

    /**
     * The unwinding information for the target address could not be encoded using the CFE format. Instead, DWARF
     * frame information must be used.
     *
     * An offset to the DWARF FDE in the __eh_frame section is be provided.
     */
    HMD_ASYNC_CFE_ENTRY_TYPE_DWARF = 3,

    /**
     * No unwind information is available for the target address. This value is only returned in the case where an
     * unwind table entry exists for the given address, but the entry is empty.
     */
    HMD_ASYNC_CFE_ENTRY_TYPE_NONE = 4
} hmd_async_cfe_entry_type_t;

/**
 * @internal
 *
 * A decoded CFE entry. The entry represents the data necessary to unwind the stack frame at a given PC, including
 * restoration of saved registers.
 */
typedef struct hmd_async_cfe_entry {
    /** The CFE entry type. */
    hmd_async_cfe_entry_type_t type;
    uint32_t encoding;
} hmd_async_cfe_entry_t;

/* Extract @a mask bits from @a value. */
#define EXTRACT_BITS(value, mask) ((value >> __builtin_ctz(mask)) & (((1 << __builtin_popcount(mask))) - 1))

#pragma mark CFE Reader

/**
 * Initialize a new CFE reader using the provided memory object. Any resources held by a successfully initialized
 * instance must be freed via hmd_async_cfe_reader_free();
 *
 * @param reader The reader instance to initialize.
 * @param cputype The target architecture of the CFE data, encoded as a Mach-O CPU type. Interpreting CFE data is
 * architecture-specific, and Apple has not defined encodings for all supported architectures.
 */
hmd_error_t hmd_async_cfe_reader_init(hmd_async_cfe_reader_t *reader, hmd_async_mem_range unwind_info, cpu_type_t cputype) {
    reader->unwind_info = unwind_info;
    reader->cpu_type = cputype;

    /* Determine the expected encoding */
    switch (cputype) {
        case CPU_TYPE_X86:
        case CPU_TYPE_X86_64:
        case CPU_TYPE_ARM64:
            reader->byteorder = hmd_async_byteorder_little_endian();
            break;

        default:
            HMDLOG_ERROR("Unsupported CPU type: %" PRIu32, cputype);
            return HMD_ENOTSUP;
    }

    /* Fetch and verify the header */
    hmd_vm_address_t addr = unwind_info.addr;
    struct unwind_info_section_header header = {0};
        
    hmd_error_t ret = hmd_async_read_memory(addr, &header, sizeof(header));
    
    if (ret != HMD_ESUCCESS) {
        HMDLOG_ERROR("unwind info read error");
        return ret;
    }
    
    /* Verify the format version */
    uint32_t version = reader->byteorder->swap32(header.version);
    if (version != 1) {
        HMDLOG_ERROR("Unsupported CFE version: %" PRIu32, version);
        return HMD_ENOTSUP;
    }

    reader->header = header;
    return HMD_ESUCCESS;
}

/**
 * @internal
 *
 * Binary search in macro form. Pass the table, count, and result
 * pointers.
 *
 * CFE_FUN_BINARY_SEARCH_ENTVAL must also be defined, and it must
 * return the integer value to be compared.
 */
#define CFE_FUN_BINARY_SEARCH(_pc, _table, _count, _result)                                       \
    do {                                                                                          \
        uint32_t min = 0;                                                                         \
        uint32_t mid = 0;                                                                         \
        uint32_t max = _count - 1;                                                                \
                                                                                                  \
        /* Search while _table[min:max] is not empty */                                           \
        while (max >= min) {                                                                      \
            /* Calculate midpoint */                                                              \
            mid = (min + max) / 2;                                                                \
                                                                                                  \
            /* Determine which half of the array to search */                                     \
            uint32_t mid_fun_offset = CFE_FUN_BINARY_SEARCH_ENTVAL(_table[mid]);                  \
            if (mid_fun_offset < _pc) {                                                           \
                /* Check for inclusive equality */                                                \
                if (mid == max || CFE_FUN_BINARY_SEARCH_ENTVAL(_table[mid + 1]) > _pc) {          \
                    _result = &_table[mid];                                                       \
                    break;                                                                        \
                }                                                                                 \
                                                                                                  \
                /* Base our search on the upper array */                                          \
                min = mid + 1;                                                                    \
            } else if (mid_fun_offset > _pc) {                                                    \
                /* Check for range exclusion; if we hit 0, then the range starts after our PC. */ \
                if (mid == 0) {                                                                   \
                    break;                                                                        \
                }                                                                                 \
                                                                                                  \
                /* Base our search on the lower array */                                          \
                max = mid - 1;                                                                    \
            } else if (mid_fun_offset == _pc) {                                                   \
                /* Direct match found */                                                          \
                _result = &_table[mid];                                                           \
                break;                                                                            \
            }                                                                                     \
        }                                                                                         \
    } while (0)

/* Evaluates to true if the length of @a _ecount * @a sizof(_etype) can not be represented
 * by size_t. */
#define VERIFY_SIZE_T(_etype, _ecount) (SIZE_MAX / sizeof(_etype) < (size_t)_ecount)

/**
 * Return the compact frame encoding entry for @a pc via @a encoding, if available.
 *
 * @param reader The initialized CFE reader which will be searched for the entry.
 * @param pc The PC value to search for within the CFE data. Note that this value must be relative to
 * the target Mach-O image's __TEXT vmaddr.
 * @param function_base On success, will be populated with the base address of the function. This value is relative to
 * the image's load address, rather than the in-memory address of the loaded image.
 * @param encoding On success, will be populated with the compact frame encoding entry.
 *
 * @return Returns HMDFRAME_ESUCCCESS on success, or one of the remaining error codes if a CFE parsing error occurs. If
 * the entry can not be found, HMDFRAME_ENOTFOUND will be returned.
 */
hmd_error_t hmd_async_cfe_reader_find_pc(hmd_async_cfe_reader_t *reader, hmd_vm_address_t pc,
                                         hmd_vm_address_t *function_base, uint32_t *encoding) {
    const hmd_async_byteorder_t *byteorder = reader->byteorder;
    const hmd_async_mem_range unwind_info = reader->unwind_info;

    /* Find and map the common encodings table */
    uint32_t common_enc_count = byteorder->swap32(reader->header.commonEncodingsArrayCount);
    uint32_t *common_enc;
    {
        if (VERIFY_SIZE_T(uint32_t, common_enc_count)) {
            HMDLOG_ERROR("CFE common encoding count extends beyond the range of size_t");
            return HMD_EINVAL;
        }

        size_t common_enc_len = common_enc_count * sizeof(uint32_t);
        uint32_t common_enc_off = byteorder->swap32(reader->header.commonEncodingsArraySectionOffset);
        common_enc = hmd_async_mem_range_pointer(unwind_info, common_enc_off, common_enc_len);
        if (common_enc == NULL) {
            HMDLOG_ERROR("The declared common table lies outside the mapped CFE range");
            return HMD_EINVAL;
        }
    }

    /* Find and load the first level entry */
    struct unwind_info_section_header_index_entry *first_level_entry = NULL;
    {
        /* Find and map the index */
        uint32_t index_off = byteorder->swap32(reader->header.indexSectionOffset);
        uint32_t index_count = byteorder->swap32(reader->header.indexCount);

        if (VERIFY_SIZE_T(sizeof(struct unwind_info_section_header_index_entry), index_count)) {
            HMDLOG_ERROR("CFE index count extends beyond the range of size_t");
            return HMD_EINVAL;
        }

        if (index_count == 0) {
            HMDLOG_ERROR("CFE index contains no entries");
            return HMD_ENOTFOUND;
        }

        /*
         * NOTE: CFE includes an extra entry in the total count of second-level pages, ie, from ld64:
         * const uint32_t indexCount = secondLevelPageCount+1;
         *
         * There's no explanation as to why, and tools appear to explicitly ignore the entry entirely. We do the same
         * here.
         */
        HMDCF_ASSERT(index_count != 0);
        index_count--;

        /* Load the index entries */
        size_t index_len = index_count * sizeof(struct unwind_info_section_header_index_entry);
        struct unwind_info_section_header_index_entry *index_entries =
            hmd_async_mem_range_pointer(unwind_info, index_off, index_len);
        if (index_entries == NULL) {
            HMDLOG_ERROR("The declared entries table lies outside the mapped CFE range");
            return HMD_EINVAL;
        }

        /* Binary search for the first-level entry */
#define CFE_FUN_BINARY_SEARCH_ENTVAL(_tval) (byteorder->swap32(_tval.functionOffset))
        CFE_FUN_BINARY_SEARCH(pc, index_entries, index_count, first_level_entry);
#undef CFE_FUN_BINARY_SEARCH_ENTVAL

        if (first_level_entry == NULL) {
            HMDLOG_ERROR("Could not find a first level CFE entry for pc=%" PRIx64, (uint64_t)pc);
            return HMD_ENOTFOUND;
        }
    }

    /* Locate and decode the second-level entry */
    uint32_t second_level_offset = byteorder->swap32(first_level_entry->secondLevelPagesSectionOffset);
    uint32_t *second_level_kind = hmd_async_mem_range_pointer(unwind_info, second_level_offset, sizeof(uint32_t));
    if (second_level_kind == NULL) {
        return HMD_ENOTFOUND;
    }
    switch (byteorder->swap32(*second_level_kind)) {
        case UNWIND_SECOND_LEVEL_REGULAR: {
            struct unwind_info_regular_second_level_page_header *header;
            header = hmd_async_mem_range_pointer(unwind_info, second_level_offset, sizeof(*header));
            if (header == NULL) {
                HMDLOG_ERROR("The second-level page header lies outside the mapped CFE range");
                return HMD_EINVAL;
            }

            /* Find the entries array */
            uint32_t entries_offset = byteorder->swap16(header->entryPageOffset);
            uint32_t entries_count = byteorder->swap16(header->entryCount);

            if (VERIFY_SIZE_T(sizeof(struct unwind_info_regular_second_level_entry), entries_count)) {
                HMDLOG_ERROR("CFE second level entry count extends beyond the range of size_t");
                return HMD_EINVAL;
            }

            if (!hmd_async_mem_range_verify_offset(unwind_info, (hmd_vm_address_t)header, entries_offset, entries_count * sizeof(struct unwind_info_regular_second_level_entry))) {
                HMDLOG_ERROR("CFE entries table lies outside the mapped CFE range");
                return HMD_EINVAL;
            }

            /* Binary search for the target entry */
            struct unwind_info_regular_second_level_entry *entries =
                (struct unwind_info_regular_second_level_entry *)(((uintptr_t)header) + entries_offset);
            struct unwind_info_regular_second_level_entry *entry = NULL;

#define CFE_FUN_BINARY_SEARCH_ENTVAL(_tval) (byteorder->swap32(_tval.functionOffset))
            CFE_FUN_BINARY_SEARCH(pc, entries, entries_count, entry);
#undef CFE_FUN_BINARY_SEARCH_ENTVAL

            if (entry == NULL) {
                HMDLOG_ERROR("Could not find a second level regular CFE entry for pc=%" PRIx64, (uint64_t)pc);
                return HMD_ENOTFOUND;
            }

            *encoding = byteorder->swap32(entry->encoding);
            *function_base = byteorder->swap32(entry->functionOffset);
            return HMD_ESUCCESS;
        }

        case UNWIND_SECOND_LEVEL_COMPRESSED: {
            struct unwind_info_compressed_second_level_page_header *header;
            header = hmd_async_mem_range_pointer(unwind_info, second_level_offset, sizeof(*header));
            if (header == NULL) {
                HMDLOG_ERROR("The second-level page header lies outside the mapped CFE range");
                return HMD_EINVAL;
            }

            /* Record the base offset */
            uint32_t base_foffset = byteorder->swap32(first_level_entry->functionOffset);

            /* Find the entries array */
            uint32_t entries_offset = byteorder->swap16(header->entryPageOffset);
            uint32_t entries_count = byteorder->swap16(header->entryCount);

            if (VERIFY_SIZE_T(sizeof(uint32_t), entries_count)) {
                HMDLOG_ERROR("CFE second level entry count extends beyond the range of size_t");
                return HMD_EINVAL;
            }

            if (!hmd_async_mem_range_verify_offset(unwind_info, (hmd_vm_address_t)header, entries_offset,
                                                        entries_count * sizeof(uint32_t))) {
                HMDLOG_ERROR("CFE entries table lies outside the mapped CFE range");
                return HMD_EINVAL;
            }

            /* Binary search for the target entry */
            uint32_t *compressed_entries = (uint32_t *)(((uintptr_t)header) + entries_offset);
            uint32_t *c_entry_ptr = NULL;

#define CFE_FUN_BINARY_SEARCH_ENTVAL(_tval) \
    (base_foffset + UNWIND_INFO_COMPRESSED_ENTRY_FUNC_OFFSET(byteorder->swap32(_tval)))
            CFE_FUN_BINARY_SEARCH(pc, compressed_entries, entries_count, c_entry_ptr);
#undef CFE_FUN_BINARY_SEARCH_ENTVAL

            if (c_entry_ptr == NULL) {
                HMDLOG_ERROR("Could not find a second level compressed CFE entry for pc=%" PRIx64, (uint64_t)pc);
                return HMD_ENOTFOUND;
            }

            /* Find the actual encoding */
            uint32_t c_entry = byteorder->swap32(*c_entry_ptr);
            uint8_t c_encoding_idx = UNWIND_INFO_COMPRESSED_ENTRY_ENCODING_INDEX(c_entry);

            /* Save the function base */
            *function_base = base_foffset + UNWIND_INFO_COMPRESSED_ENTRY_FUNC_OFFSET(byteorder->swap32(c_entry));

            /* Handle common table entries */
            if (c_encoding_idx < common_enc_count) {
                /* Found in the common table. The offset is verified as being within the mapped memory range by
                 * the < common_enc_count check above. */
                *encoding = byteorder->swap32(common_enc[c_encoding_idx]);
                return HMD_ESUCCESS;
            }

            /* Map in the encodings table */
            uint32_t encodings_offset = byteorder->swap16(header->encodingsPageOffset);
            uint32_t encodings_count = byteorder->swap16(header->encodingsCount);

            if (VERIFY_SIZE_T(sizeof(uint32_t), encodings_count)) {
                HMDLOG_ERROR("CFE second level entry count extends beyond the range of size_t");
                return HMD_EINVAL;
            }

            if (!hmd_async_mem_range_verify_offset(unwind_info, (hmd_vm_address_t)header, encodings_offset,
                                                        encodings_count * sizeof(uint32_t))) {
                HMDLOG_ERROR("CFE compressed encodings table lies outside the mapped CFE range");
                return HMD_EINVAL;
            }

            uint32_t *encodings = (uint32_t *)(((uintptr_t)header) + encodings_offset);

            /* Verify that the entry is within range */
            c_encoding_idx -= common_enc_count;
            if (c_encoding_idx >= encodings_count) {
                HMDLOG_ERROR("Encoding index lies outside the second level encoding table");
                return HMD_EINVAL;
            }

            /* Save the results */
            *encoding = byteorder->swap32(encodings[c_encoding_idx]);
            return HMD_ESUCCESS;
        }

        default:
            HMDLOG_ERROR("Unsupported second-level CFE table kind: 0x%" PRIx32 " at 0x%" PRIx32,
                         byteorder->swap32(*second_level_kind), second_level_offset);
            return HMD_EINVAL;
    }

    return HMD_ENOTFOUND;
}

/**
 * Initialize a new decoded CFE entry using the provided encoded CFE data. Any resources held by a successfully
 * initialized instance must be freed via hmd_async_cfe_entry_free();
 *
 * @param entry The entry instance to initialize.
 * @param cpu_type The target architecture of the CFE data, encoded as a Mach-O CPU type. Interpreting CFE data is
 * architecture-specific, and Apple has not defined encodings for all supported architectures.
 * @param encoding The CFE entry data, in the hosts' native byte order.
 *
 * @internal
 * This code supports sparse register lists for the EBP_FRAME and RBP_FRAME modes. It's unclear as to whether these
 * actually ever occur in the wild, but they are supported by Apple's unwinddump tool.
 */
hmd_error_t hmd_async_cfe_entry_init(hmd_async_cfe_entry_t *entry, cpu_type_t cpu_type, uint32_t encoding) {
    if (cpu_type == CPU_TYPE_ARM64) {
        entry->encoding = encoding;
        uint32_t mode = encoding & UNWIND_ARM64_MODE_MASK;
        switch (mode) {
            case UNWIND_ARM64_MODE_FRAME:
                entry->type = HMD_ASYNC_CFE_ENTRY_TYPE_FRAME_PTR;
                return HMD_ESUCCESS;
            case UNWIND_ARM64_MODE_FRAMELESS:
                entry->type = HMD_ASYNC_CFE_ENTRY_TYPE_FRAMELESS;
                return HMD_ESUCCESS;
            case 0:
                /* Handle a NULL encoding. This interpretation is derived from Apple's actual implementation; the
                 * correct interpretation of a 0x0 value is not defined in what documentation exists. */
                entry->type = HMD_ASYNC_CFE_ENTRY_TYPE_NONE;
                return HMD_ESUCCESS;
            
            case UNWIND_ARM64_MODE_DWARF:
                entry->type = HMD_ASYNC_CFE_ENTRY_TYPE_DWARF;
                return HMD_ESUCCESS;
            default:
                HMDLOG_ERROR("Unexpected entry mode of %" PRIx32, mode);
                return HMD_ENOTSUP;
        }
    }

    HMDLOG_ERROR("Unsupported CPU type: %" PRIu32, cpu_type);
    return HMD_ENOTSUP;
}

/**
 * Apply the decoded @a entry to @a thread_state, fetching data from @a task, populating @a new_thread_state
 * with the result.
 *
 * @param function_address The task-relative in-memory address of the function containing @a entry. This may be computed
 * by adding the function_base returned by hmd_async_cfe_reader_find_pc() to the base address of the loaded image.
 * @param thread_state The current thread state corresponding to @a entry.
 * @param entry A CFE unwind entry.
 * @param new_thread_state The new thread state to be initialized.
 *
 * @return Returns HMD_ESUCCESS on success, or a standard hmd_error_t code if an error occurs.
 *
 * @todo This implementation assumes downwards stack growth.
 */
hmd_error_t hmd_async_cfe_entry_apply(hmd_vm_address_t function_address,
                                      const hmd_thread_state_t *thread_state,
                                      hmd_async_cfe_entry_t *entry,
                                      hmd_thread_state_t *new_thread_state) {
    /* Set up register load target */
    size_t greg_size = sizeof(uintptr_t);
    uintptr_t dest[2];
    
    *new_thread_state = *thread_state;
    
    uintptr_t savedRegisterLoc = 0;
    uint32_t encoding = entry->encoding;
    hmd_async_cfe_entry_type_t entry_type = entry->type;
    switch (entry_type) {
        case HMD_ASYNC_CFE_ENTRY_TYPE_FRAME_PTR: {
            hmd_error_t err;
            HMDLOG_TRACE("entry type frame");

            hmd_greg_t fp = hmd_thread_state_get_fp(thread_state);
            /* Read the saved fp and retaddr */
            err = hmd_async_read_memory(fp, dest, sizeof(dest));
            if (err != HMD_ESUCCESS) {
                HMDLOG_ERROR("Failed to read frame data at address %p %d", (uint64_t)fp, err);
                return err;
            }
            
            savedRegisterLoc = fp - greg_size;
            
            hmd_thread_state_set_fp(new_thread_state, dest[0]);
            hmd_thread_state_set_pc(new_thread_state, dest[1]);
            hmd_thread_state_set_sp(new_thread_state, fp + greg_size * 2);
            
            break;
        }
        case HMD_ASYNC_CFE_ENTRY_TYPE_FRAMELESS: {
            HMDLOG_TRACE("entry type frameless");
            uint32_t encoding = entry->encoding;
            uint32_t stackSize = 16 * EXTRACT_BITS(encoding, UNWIND_ARM64_FRAMELESS_STACK_SIZE_MASK);
            savedRegisterLoc = hmd_thread_state_get_sp(thread_state) + stackSize;

            /* Copy the return address value to the new thread state's IP */
            hmd_thread_state_set_pc(new_thread_state, hmd_thread_state_get_lr(thread_state));
            
            /* 防止死循环，在使用lr之后把lr清空 */
            hmd_thread_state_set_lr(new_thread_state, 0x0);
            
            HMDLOG_TRACE("return address in lr: %p", hmd_thread_state_get_pc(new_thread_state));

            break;
        }

        case HMD_ASYNC_CFE_ENTRY_TYPE_DWARF:
        case HMD_ASYNC_CFE_ENTRY_TYPE_NONE:
        default:
            HMDLOG_WARN("cfe entry type not support %x",entry_type);
            return HMD_ENOTSUP;
    }
        
    hmd_greg_t pre_pc = hmd_thread_state_get_pc(new_thread_state);
    hmd_greg_t pre_fp = hmd_thread_state_get_fp(new_thread_state);
    hmd_greg_t pre_sp = hmd_thread_state_get_sp(new_thread_state);
    
    HMDLOG_TRACE("pre fp: %p", pre_fp);
    HMDLOG_TRACE("pre sp: %p", pre_sp);
    HMDLOG_TRACE("pre pc: %p", pre_pc);

    //check if the terminal frame
    if (!HMD_IS_VALID_PTR(pre_pc)) {
        HMDLOG_ERROR("pre_pc is invalid %p, ending",pre_pc);
        return HMD_ENOTFOUND;
    }
    
    //recover calle saved registers
    if (encoding & UNWIND_ARM64_FRAME_X19_X20_PAIR) {
        if (hmd_async_read_memory(savedRegisterLoc, dest, sizeof(dest)) == HMD_ESUCCESS) {
            new_thread_state->__ss.__x[19] = dest[0];
            new_thread_state->__ss.__x[20] = dest[1];
        }
        savedRegisterLoc -= greg_size * 2;
    }
    if (encoding & UNWIND_ARM64_FRAME_X21_X22_PAIR) {
        if (hmd_async_read_memory(savedRegisterLoc, dest, sizeof(dest)) == HMD_ESUCCESS) {
          new_thread_state->__ss.__x[21] = dest[0];
          new_thread_state->__ss.__x[22] = dest[1];
        }
        savedRegisterLoc -= greg_size * 2;
    }
    if (encoding & UNWIND_ARM64_FRAME_X23_X24_PAIR) {
        if (hmd_async_read_memory(savedRegisterLoc, dest, sizeof(dest)) == HMD_ESUCCESS) {
          new_thread_state->__ss.__x[23] = dest[0];
          new_thread_state->__ss.__x[24] = dest[1];
        }
        savedRegisterLoc -= greg_size * 2;
    }
    if (encoding & UNWIND_ARM64_FRAME_X25_X26_PAIR) {
        if (hmd_async_read_memory(savedRegisterLoc, dest, sizeof(dest)) == HMD_ESUCCESS) {
          new_thread_state->__ss.__x[25] = dest[0];
          new_thread_state->__ss.__x[26] = dest[1];
        }
        savedRegisterLoc -= greg_size * 2;
    }
    if (encoding & UNWIND_ARM64_FRAME_X27_X28_PAIR) {
        if (hmd_async_read_memory(savedRegisterLoc, dest, sizeof(dest)) == HMD_ESUCCESS) {
          new_thread_state->__ss.__x[27] = dest[0];
          new_thread_state->__ss.__x[28] = dest[1];
        }
        savedRegisterLoc -= greg_size * 2;
    }

    return HMD_ESUCCESS;
}

hmd_error_t hmd_async_cfe_lookup_and_compute(hmd_async_image_t *image,
                                             const hmd_thread_state_t *cur_state,
                                             hmd_thread_state_t *new_state) {
    hmd_async_mem_range unwind_info = image->macho_image.unwind_info;
    cpu_type_t cputype = hmd_async_macho_cpu_type(&image->macho_image);
    hmd_vm_address_t image_base = image->macho_image.header_addr;
    hmd_async_cfe_reader_t reader;
    hmd_error_t err = hmd_async_cfe_reader_init(&reader, unwind_info, cputype);
    if (err != HMD_ESUCCESS) {
        HMDLOG_ERROR("cfe reader init failed");
        return err;
    }

    uintptr_t pc = hmd_thread_state_get_pc(cur_state) - 1;
    hmd_vm_address_t function_base;
    uint32_t encoding;
    err = hmd_async_cfe_reader_find_pc(&reader, pc - image_base, &function_base, &encoding);
    if (err != HMD_ESUCCESS) {
        HMDLOG_ERROR("cfe reader find pc failed");
        return err;
    }

    /* Decode the entry */
    hmd_async_cfe_entry_t entry;
    err = hmd_async_cfe_entry_init(&entry, cputype, encoding);
    if (err != HMD_ESUCCESS) {
        HMDLOG_ERROR("cfe entry init failed");
        return err;
    }

    /* Skip entries for which no unwind information is unavailable */
    if (entry.type == HMD_ASYNC_CFE_ENTRY_TYPE_NONE) {
        HMDLOG_ERROR("cfe entry type is none");
        return HMD_ENOTFOUND;
    }
    
    if (entry.type == HMD_ASYNC_CFE_ENTRY_TYPE_DWARF) {
        return hmd_unwind_with_dwarf(image->macho_image.eh_frame, (encoding&UNWIND_ARM64_DWARF_SECTION_OFFSET), cur_state, new_state);
    }

    /* Compute the in-core function address */
    hmd_vm_address_t function_address;
    if (!hmd_async_address_apply_offset(image_base, function_base, &function_address)) {
        HMDLOG_ERROR("address apply offset failed");
        return err;
    }

    /* Apply the frame delta -- this may fail. */
    err = hmd_async_cfe_entry_apply(function_address, cur_state, &entry, new_state);
    if (err != HMD_ESUCCESS) {
        HMDLOG_ERROR("cfe entry apply failed");
        return err;
    }
    
    return HMD_ESUCCESS;
}

#endif
