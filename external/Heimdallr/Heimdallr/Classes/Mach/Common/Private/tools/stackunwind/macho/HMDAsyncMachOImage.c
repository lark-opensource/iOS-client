//
//  HMDAsyncMachOImage.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//

#include "HMDMacro.h"
#include "HMDAsyncMachOImage.h"
#include "hmd_crash_safe_tool.h"
#include <assert.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

#include <mach-o/fat.h>
#include "hmd_logger.h"
#include <mach-o/getsect.h>

/*!
    @name COMPILE_ASSERT
    @abstract compiler assert, there is a spelling error. I know. For backward compact, the only way is to keep it.
 */
#ifndef COMPILE_ASSERT
#define COMPILE_ASSERT(condition) ((void)sizeof(char[1 - 2*!(condition)]))
#endif

void *hmd_async_macho_next_command_type(hmd_async_macho_t *image, void *previous, uint32_t expectedCommand);
hmd_async_mem_range hmd_async_find_section(hmd_async_macho_t *image, const char *segname, const char *sectname);
static void read_interested_section(hmd_async_macho_t *image, struct segment_command_64 *cmd);

static int hmd_count_command_type(hmd_async_macho_t *image, uint32_t expectedCommand) {
    void *seg = NULL;
    int count = 0;
    while ((seg = hmd_async_macho_next_command_type(image, seg, image->m64 ? LC_SEGMENT_64 : LC_SEGMENT)) != 0) {
        count++;
    }
    return count;
}

static void read_all_segments(hmd_async_macho_t *image) {
    if (image->segments != NULL || image->segment_count > 0) {
        return;
    }
    
    if (image->interested_sections != NULL || image->interested_sections_allocated_count > 0) {
        return;
    }
    
    int cmdCount = hmd_count_command_type(image,image->m64 ? LC_SEGMENT_64 : LC_SEGMENT);
    if (cmdCount <= 0) {
        return;
    }
    
    image->segments = calloc(cmdCount, sizeof(hmd_async_segment));
    if (image->segments == NULL) {
        return;
    }
    
    int index = 0;
    void *seg = NULL;
    while (index < cmdCount && ((seg = hmd_async_macho_next_command_type(image, seg, image->m64 ? LC_SEGMENT_64 : LC_SEGMENT)) != 0)) {
        /* Read the load command */
        hmd_vm_address_t addr = 0;
        hmd_vm_size_t size = 0;
        int32_t initprot = 0;
        int32_t maxprot = 0;
        char seg_name[16] = {0};
        if (image->m64) {
            struct segment_command_64 *cmd = seg;
            if (strcmp(cmd->segname, SEG_PAGEZERO) == 0) {
                continue;
            }
            addr = (hmd_vm_address_t)image->byteorder->swap64(cmd->vmaddr) + image->vmaddr_slide;
            size = (hmd_vm_size_t)image->byteorder->swap64(cmd->vmsize);
            memcpy(seg_name, cmd->segname, sizeof(seg_name));
            if(cmd->nsects > 0) read_interested_section(image, cmd);
            initprot = cmd->initprot;
            maxprot = cmd->maxprot;
        } else {
            struct segment_command *cmd = seg;
            if (strcmp(cmd->segname, SEG_PAGEZERO) == 0) {
                continue;
            }
            addr = (hmd_vm_address_t)image->byteorder->swap32(cmd->vmaddr) + image->vmaddr_slide;
            size = (hmd_vm_size_t)image->byteorder->swap32(cmd->vmsize);
            memcpy(seg_name, cmd->segname, sizeof(seg_name));
            // not support 32 bit interesting sections
            initprot = cmd->initprot;
            maxprot = cmd->maxprot;
        }
        
        hmd_async_segment *segment = &image->segments[index];
        segment->range.addr = addr;
        segment->range.size = size;
        segment->initprot = initprot;
        segment->maxprot = maxprot;
        memcpy(segment->seg_name, seg_name, sizeof(seg_name));
        index++;
        image->segment_count = index;
    }
}

static void read_interested_section(hmd_async_macho_t *image, struct segment_command_64 *cmd) {
#define INTERESTED_SECTION_INIT_COUNT     5
#define INTERESTED_SECTION_INCREASE_COUNT 5
    
    DEBUG_ASSERT(image->m64);
    if (!image->m64) return;

    struct section_64 *section = (struct section_64 *)((uintptr_t)cmd + sizeof(struct segment_command_64));
    for(uint32_t index = 0; index < cmd->nsects; index++) {
        
        if(hmd_async_mem_range_verify(image->load_cmds, (hmd_vm_address_t)(section + index), sizeof(struct segment_command_64))) {
            if(strncmp(section[index].sectname, "__objc_classlist"  , 16) == 0 ||
               strncmp(section[index].sectname, "__objc_data"       , 16) == 0 ||
               strncmp(section[index].sectname, "__objc_const"      , 16) == 0 ||
               strncmp(section[index].sectname, "__objc_const_ax"   , 16) == 0 ||
               strncmp(section[index].sectname, "__objc_methlist"   , 16) == 0 ||
               strncmp(section[index].sectname, "__objc_catlist"    , 16) == 0) {
                if(image->interested_sections == NULL) {
                    image->interested_sections = calloc(INTERESTED_SECTION_INIT_COUNT, sizeof(hmd_async_section));
                    if(image->interested_sections != NULL) {
                        DEBUG_ASSERT(image->interested_sections_count == 0);
                        image->interested_sections_allocated_count = INTERESTED_SECTION_INIT_COUNT;
                    } else break;
                }
                if(image->interested_sections_count == image->interested_sections_allocated_count) {
                    hmd_async_section *temp = realloc(image->interested_sections,
                                                      sizeof(hmd_async_section) * (image->interested_sections_allocated_count + INTERESTED_SECTION_INCREASE_COUNT));
                    if(temp != NULL) {
                        image->interested_sections = temp;
                        image->interested_sections_allocated_count += INTERESTED_SECTION_INCREASE_COUNT;
                    } else break;
                }
                DEBUG_ASSERT(image->interested_sections_count < image->interested_sections_allocated_count);
                
                memcpy(&image->interested_sections[image->interested_sections_count].seg_name, section[index].segname, sizeof(char[16]));
                memcpy(&image->interested_sections[image->interested_sections_count].sec_name, section[index].sectname, sizeof(char[16]));
                
                COMPILE_ASSERT(sizeof(image->interested_sections[image->interested_sections_count].seg_name) >= sizeof(char[17]));
                
                image->interested_sections[image->interested_sections_count].seg_name[16] = '\0';
                image->interested_sections[image->interested_sections_count].sec_name[16] = '\0';
                
                image->interested_sections[image->interested_sections_count].range.addr = (hmd_vm_address_t)image->byteorder->swap64(section[index].addr) + image->vmaddr_slide;
                image->interested_sections[image->interested_sections_count].range.size = (hmd_vm_address_t)image->byteorder->swap64(section[index].size);
                
                image->interested_sections_count += 1;
            }
        } else {
            DEBUG_POINT;
            break;
        }
    } // break exit point
}

static bool hmd_async_macho_is_from_app(hmd_async_macho_t *image) {
    if (image == NULL) {
        return false;
    }
    
    if (hmd_async_macho_is_executable(image)) {
        return true;
    }
    
    if (strlen(hmd_main_bundle_path) == 0) {
#ifdef DEBUG
        assert(0);
#endif
        return false;
    }
    
    if (hmd_reliable_has_suffix(image->name, ".dylib")) {
        return false;
    }
    
    // image->name may begin with /private/var or /var as they indicate same file
    // https://bytedance.feishu.cn/wiki/wikcnabwhvYJh52MOAhEgtDKUWc#
    if (image->name != NULL && strstr(image->name, hmd_main_bundle_path)) {
        return true;
    }
    
    return false;
}

hmd_error_t hmd_nasync_macho_init(hmd_async_macho_t *image, const char *name, hmd_vm_address_t header) {
    hmd_error_t ret;

    if (image == NULL) {
        ret = HMD_EINVAL;
        goto error;
    }
    /* Defaults checked in the  error cleanup handler */
    memset(image, 0, sizeof(*image));

    /* Basic initialization */
    image->header_addr = header;
    
    if (name == NULL) {
        name = "";
    }
    image->name = strdup(name);

    /* Read in the Mach-O header */
    ret = hmd_async_read_memory(header, &image->header, sizeof(image->header));
    if (ret != HMD_ESUCCESS) {
        ret = HMD_EINTERNAL;
        goto error;
    }
    
    /* Set the default byte order*/
    image->byteorder = &hmd_async_byteorder_direct;

    /* Parse the Mach-O magic identifier. */
    switch (image->header.magic) {
        case MH_CIGAM:
            // Enable byte swapping
            image->byteorder = &hmd_async_byteorder_swapped;
            // Fall-through

        case MH_MAGIC:
            image->m64 = false;
            break;

        case MH_CIGAM_64:
            // Enable byte swapping
            image->byteorder = &hmd_async_byteorder_swapped;
            // Fall-through

        case MH_MAGIC_64:
            image->m64 = true;
            break;

        case FAT_CIGAM:
        case FAT_MAGIC:
            HMDLOG_ERROR("%s called with an unsupported universal Mach-O archive in: %s", __func__, image->name);
            ret = HMD_EINVAL;
            goto error;

        default:
            HMDLOG_ERROR("Unknown Mach-O magic: 0x%" PRIx32 " in: %s", image->header.magic, image->name);
            ret = HMD_EINVAL;
            goto error;
    }

    /* Save the header size */
    if (image->m64) {
        image->header_size = sizeof(struct mach_header_64);
    } else {
        image->header_size = sizeof(struct mach_header);
    }

    /* Map in header + load commands */
    hmd_vm_size_t cmd_len = image->byteorder->swap32(image->header.sizeofcmds);
    hmd_vm_size_t cmd_offset = image->header_addr + image->header_size;
    image->ncmds = image->byteorder->swap32(image->header.ncmds);
    
    image->load_cmds.addr = cmd_offset;
    image->load_cmds.size = cmd_len;
    
    struct uuid_command *cmd = (struct uuid_command *)hmd_async_macho_find_command(image, LC_UUID);
    if (cmd != NULL) {
        static char hex_table[] = "0123456789abcdef";
        for(size_t index = 0; index < 16; index++) {
            unsigned char current = (unsigned char)cmd->uuid[index];
            image->uuid[index * 2] = hex_table[(current >> 4) & 0xF];
            image->uuid[index * 2 + 1] = hex_table[current & 0xF];
        }
        image->uuid[32] = 0;
        COMPILE_ASSERT(sizeof(cmd->uuid) == sizeof(uuid_t));
        memcpy(image->raw_uuid, cmd->uuid, sizeof(uuid_t));
    }
    
    struct entry_point_command *lc_main_cmd = (struct entry_point_command *)hmd_async_macho_find_command(image, LC_MAIN);
    
    if (lc_main_cmd != NULL) {
        image->entryOff = lc_main_cmd->entryoff;
    }else {
        image->entryOff = 0;
    }
    

    /* Now that the image has been sufficiently initialized, determine the __TEXT segment size */
    
    hmd_async_macho_segment_t text_segment = hmd_async_find_segment(image, SEG_TEXT);

    if (text_segment.obj.size == 0) {
        HMDLOG_ERROR("Could not find __TEXT segment!");
        ret = HMD_EINVAL;
        goto error;
    }
    
    image->text_segment = text_segment.obj;

    /* Compute the vmaddr slide */
    if (image->text_segment.addr < header) {
        image->vmaddr_slide = header - image->text_segment.addr;
    } else if (image->text_segment.addr > header) {
        image->vmaddr_slide = -((hmd_vm_off_t)(image->text_segment.addr - header));
    } else {
        image->vmaddr_slide = 0;
    }
    
    image->text_segment.addr = header;
    
    read_all_segments(image);
    
    image->unwind_info = hmd_async_find_section(image, SEG_TEXT, "__unwind_info");
    image->eh_frame = hmd_async_find_section(image, SEG_TEXT, "__eh_frame");
    image->crash_info = hmd_async_find_section(image, SEG_DATA, "__crash_info");
        
    image->is_app_image = hmd_async_macho_is_from_app(image);

    return HMD_ESUCCESS;

error:
    
    if (image->name != NULL) free(image->name);

    return ret;
}

/**
 * Return true if @a address is mapped within @a image's __TEXT segment, false otherwise.
 *
 * @param image The Mach-O image.
 * @param address The address to be searched for.
 */
bool hmd_async_macho_contains_address(hmd_async_macho_t *image, hmd_vm_address_t address) {
    for (int i = 0; i < image->segment_count; i++) {
        hmd_async_segment *segment = &image->segments[i];
        if ((address >= segment->range.addr) && (address < (segment->range.addr + segment->range.size))) {
            return true;
        }
    }
    
    return false;
}

/**
 * Return the Mach CPU type of @a image.
 *
 * @param image The image from which the CPU type should be returned.
 */
cpu_type_t hmd_async_macho_cpu_type(hmd_async_macho_t *image) {
    return image->byteorder->swap32(image->header.cputype);
}

/**
 * Return the Mach CPU subtype of @a image.
 *
 * @param image The image from which the CPU subtype should be returned.
 */
cpu_subtype_t hmd_async_macho_cpu_subtype(hmd_async_macho_t *image) {
    return image->byteorder->swap32(image->header.cpusubtype);
}

bool hmd_async_macho_is_executable(hmd_async_macho_t *image) {
    return (image->byteorder->swap32(image->header.filetype) == MH_EXECUTE);
}

/**
 * Iterate over the available Mach-O LC_CMD entries.
 *
 * @param image The image to iterate
 * @param previous The previously returned LC_CMD address value, or 0 to iterate from the first LC_CMD.
 * @return Returns the address of the next load_command on success, or NULL on failure.
 *
 * @note A returned command is gauranteed to be readable, and fully within mapped address space. If the command
 * command can not be verified to have available MAX(sizeof(struct load_command), cmd->cmdsize) bytes, NULL will be
 * returned.
 */
void *hmd_async_macho_next_command(hmd_async_macho_t *image, void *previous) {
    struct load_command *cmd;

    /* On the first iteration, determine the LC_CMD offset from the Mach-O header. */
    if (previous == NULL) {
        /* Sanity check */
        if (image->byteorder->swap32(image->header.sizeofcmds) < sizeof(struct load_command)) {
            HMDLOG_ERROR("Mach-O sizeofcmds is less than sizeof(struct load_command) in %s", image->name);
            return NULL;
        }

        if (hmd_async_mem_range_verify(image->load_cmds, image->load_cmds.addr, sizeof(struct load_command))) {
            return (void *)image->load_cmds.addr;
        }
        
        return NULL;
    }

    /* We need the size from the previous load command; first, verify the pointer. */
    cmd = previous;
    if (!hmd_async_mem_range_verify(image->load_cmds, (uintptr_t)cmd, sizeof(*cmd))) {
        HMDLOG_ERROR("Failed to map LC_CMD at address %p in: %s", cmd, image->name);
        return NULL;
    }

    /* Advance to the next command */
    uint32_t cmdsize = image->byteorder->swap32(cmd->cmdsize);
    void *next = ((uint8_t *)previous) + cmdsize;

    /* Avoid walking off the end of the cmd buffer */
    if ((uintptr_t)next >= image->load_cmds.addr + image->load_cmds.size) return NULL;

    /* Verify that it holds at least load_command */
    if (!hmd_async_mem_range_verify(image->load_cmds, (uintptr_t)next, sizeof(struct load_command))) {
        HMDLOG_ERROR("Failed to map LC_CMD at address %p in: %s", cmd, image->name);
        return NULL;
    }

    /* Verify the actual size. */
    cmd = next;
    if (!hmd_async_mem_range_verify(image->load_cmds, (uintptr_t)next,
                                                image->byteorder->swap32(cmd->cmdsize))) {
        HMDLOG_ERROR("Failed to map LC_CMD at address %p in: %s", cmd, image->name);
        return NULL;
    }

    return next;
}

/**
 * Iterate over the available Mach-O LC_CMD entries.
 *
 * @param image The image to iterate
 * @param previous The previously returned LC_CMD address value, or 0 to iterate from the first LC_CMD.
 * @param expectedCommand The LC_* command type to be returned. Only commands matching this type will be returned by the
 * iterator.
 * @return Returns the address of the next load_command on success, or 0 on failure.
 *
 * @note A returned command is gauranteed to be readable, and fully within mapped address space. If the command
 * command can not be verified to have available MAX(sizeof(struct load_command), cmd->cmdsize) bytes, NULL will be
 * returned.
 */
void *hmd_async_macho_next_command_type(hmd_async_macho_t *image, void *previous, uint32_t expectedCommand) {
    struct load_command *cmd = previous;

    /* Iterate commands until we either find a match, or reach the end */
    while ((cmd = hmd_async_macho_next_command(image, cmd)) != NULL) {
        /* Return a match */
        if (image->byteorder->swap32(cmd->cmd) == expectedCommand) {
            return cmd;
        }
    }

    /* No match found */
    return NULL;
}

/**
 * Find the first LC_CMD matching the given @a cmd type.
 *
 * @param image The image to search.
 * @param expectedCommand The LC_CMD type to find.
 *
 * @return Returns the address of the matching load_command on success, or 0 on failure.
 *
 * @note A returned command is gauranteed to be readable, and fully within mapped address space. If the command
 * command can not be verified to have available MAX(sizeof(struct load_command), cmd->cmdsize) bytes, NULL will be
 * returned.
 */
void *hmd_async_macho_find_command(hmd_async_macho_t *image, uint32_t expectedCommand) {
    struct load_command *cmd = NULL;

    /* Iterate commands until we either find a match, or reach the end */
    while ((cmd = hmd_async_macho_next_command(image, cmd)) != NULL) {
        /* Read the load command type */
        if (!hmd_async_mem_range_verify(image->load_cmds, (uintptr_t)cmd, sizeof(*cmd))) {
            HMDLOG_ERROR("Failed to map LC_CMD at address %p in: %s", cmd, image->name);
            return NULL;
        }

        /* Return a match */
        if (image->byteorder->swap32(cmd->cmd) == expectedCommand) {
            return cmd;
        }
    }

    /* No match found */
    return NULL;
}

/**
 * Find a named segment.
 *
 * @param image The image to search for @a segname.
 * @param segname The name of the segment to search for.
 *
 * @return Returns a mapped pointer to the segment on success, or NULL on failure.
 */
void *hmd_async_macho_find_segment_cmd(hmd_async_macho_t *image, const char *segname) {
    void *seg = NULL;

    while ((seg = hmd_async_macho_next_command_type(image, seg, image->m64 ? LC_SEGMENT_64 : LC_SEGMENT)) != 0) {
        /* Read the load command */
        if (image->m64) {
            struct segment_command_64 *cmd_64 = seg;
            if (hmd_async_strncmp(segname, cmd_64->segname, sizeof(cmd_64->segname)) == 0) return seg;
        } else {
            struct segment_command *cmd_32 = seg;
            if (hmd_async_strncmp(segname, cmd_32->segname, sizeof(cmd_32->segname)) == 0) return seg;
        }
    }

    return NULL;
}

/**
 * Find and map a named segment, initializing @a mobj. It is the caller's responsibility to dealloc @a mobj after
 * a successful initialization
 *
 * @param image The image to search for @a segname.
 * @param segname The name of the segment to be mapped.
 * @param seg The segment data to be initialized. It is the caller's responsibility to dealloc @a seg after
 * a successful initialization.
 *
 * @warning Due to bugs in the update_dyld_shared_cache(1), the segment vmsize defined in the Mach-O load commands may
 * be invalid, and the declared size may be unmappable. As such, it is possible that this function will return a mapping
 * that is less than the total requested size. All accesses to this mapping should be done (as is already the norm)
 * through range-checked pointer validation (eg, hmd_async_mobject_remap_address()). This bug appears to be caused
 * by a bug in computing the correct vmsize when update_dyld_shared_cache(1) generates the single shared LINKEDIT
 * segment, and has been reported to Apple as rdar://13707406.
 *
 * @return Returns HMD_ESUCCESS on success, or an error result on failure.
 */
hmd_error_t hmd_async_macho_find_segment(hmd_async_macho_t *image, const char *segname,
                                        hmd_async_macho_segment_t *seg) {
    
    hmd_async_macho_segment_t restult = hmd_async_find_segment(image, segname);
    if (seg) {
        *seg = restult;
    }
    return HMD_ESUCCESS;
}


/**
 * Free all Mach-O binary image resources.
 *
 * @warning This method is not async safe.
 */
void hmd_nasync_macho_free(hmd_async_macho_t *image) {
    if (image->name != NULL) free(image->name);
    if (image->segments && image->segment_count > 0) {
        free(image->segments);
        image->segment_count = 0;
    }
    if(image->interested_sections && image->interested_sections_allocated_count > 0) {
        free(image->interested_sections);
        image->interested_sections_count = 0;
        image->interested_sections_allocated_count = 0;
    }
}

hmd_async_macho_segment_t hmd_async_find_segment(hmd_async_macho_t *image, const char *segname) {
    hmd_async_macho_segment_t result = {0};
    void * seg_cmd = hmd_async_macho_find_segment_cmd(image, segname);
    if (seg_cmd) {
        hmd_vm_address_t addr = 0;
        hmd_vm_size_t size = 0;
        hmd_vm_address_t fileoff = 0;
        hmd_vm_size_t filesize = 0;
        if (image->m64) {
            struct segment_command_64 *segment = seg_cmd;
            addr = (hmd_vm_address_t)image->byteorder->swap64(segment->vmaddr);
            size = (hmd_vm_size_t)image->byteorder->swap64(segment->vmsize);
            fileoff = (hmd_vm_address_t)image->byteorder->swap64(segment->fileoff);
            filesize = (hmd_vm_size_t)image->byteorder->swap64(segment->filesize);
        }else{
            struct segment_command *segment = seg_cmd;
            addr = (hmd_vm_address_t)image->byteorder->swap32(segment->vmaddr);
            size = (hmd_vm_size_t)image->byteorder->swap32(segment->vmsize);
            fileoff = image->byteorder->swap32(segment->fileoff);
            filesize = image->byteorder->swap32(segment->filesize);
        }
        result.obj.addr = addr + image->vmaddr_slide;
        result.obj.size = size;
        result.fileoff = fileoff;
        result.filesize = filesize;
    }
    return result;
}

hmd_async_mem_range hmd_async_find_section(hmd_async_macho_t *image, const char *segname, const char *sectname) {
    hmd_async_mem_range result = {
        .addr = 0,
        .size = 0
    };
    hmd_vm_address_t addr = 0;
    hmd_vm_size_t size = 0;
    if (image->m64) {
        const struct section_64 *sect = getsectbynamefromheader_64((struct mach_header_64 *)image->header_addr, segname, sectname);
        if (sect) {
            addr = (hmd_vm_address_t)image->byteorder->swap64(sect->addr);
            size = (hmd_vm_size_t)image->byteorder->swap64(sect->size);
        }
    } else {
        const struct section *sect = getsectbynamefromheader((struct mach_header *)image->header_addr, segname, sectname);
        if (sect) {
            addr = (hmd_vm_address_t)image->byteorder->swap32(sect->addr);
            size = (hmd_vm_size_t)image->byteorder->swap32(sect->size);
        }
    }
    if(addr != 0 && size > 0) {
        addr = addr + image->vmaddr_slide;
        result.addr = addr;
        result.size = size;
    }
    return result;
}
