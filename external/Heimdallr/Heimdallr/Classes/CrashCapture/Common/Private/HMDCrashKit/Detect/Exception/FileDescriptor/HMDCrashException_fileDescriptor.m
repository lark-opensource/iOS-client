//
//  HMDCrashExceptionFD.c
//  Pods
//
//  Created by wangyinhui on 2022/1/5.
//

#include <errno.h>
#include <unistd.h>

#include <sys/fcntl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <string.h>
#include "HMDMacro.h"
#include "HMDCrashDirectory_LowLevel.h"
#include "HMDCrashException_fileDescriptor.h"
#include "HMDCrashFileBuffer.h"
#include "HMDCrashSDKLog.h"

#define MAX_IP_LEN 20
#define FD_END_MARK 10

//record fd info when crash
static FileBuffer fd_buffer = FileBufferInvalid;

static void hmd_write_base_info(int fd, char *fd_type);
static void hmd_write_socket_info(int fd);
static void hmd_write_fifo_info(int fd, uint64_t inode);

static const char * _Nullable NSHomeDirectory_path = NULL;
static size_t NSHomeDirectory_path_length;


#pragma mark - Open and Close


bool hmd_exception_create_FD_info_file(void) {
    const char *fd_path = HMDCrashDirectory_fd_info_path();
    
    if((fd_buffer = hmd_file_open_buffer(fd_path)) == FileBufferInvalid)
        return false;
    
    return true;
}

bool hmd_exception_close_FD_info_file(void) {
    if(fd_buffer == FileBufferInvalid)
        DEBUG_RETURN(false);
    
    return close(fd_buffer) == 0;
}

#pragma mark - Write

void hmd_exception_write_FD_info(void) {
    if (fd_buffer == FileBufferInvalid) {
        SDKLog_error("failed to write fd info file");
        DEBUG_RETURN_NONE;
    }
    
    SDKLog_basic("start writing fd info file");
    
    NSHomeDirectory_path = HMDCrashDirectory_NSHomeDirectory_path();
    NSHomeDirectory_path_length = HMDCrashDirectory_NSHomeDirectory_path_length();
    
    int flags;
    int fd;
    int current_fd = 0;
    int max_fd_count = getdtablesize();
    struct stat filestat;
    //unable to obtain the current active maximum fd, set the end mark, and break when the query fails 10 times
    int fd_end_mark = FD_END_MARK;
    
    hmd_file_begin_json_object(fd_buffer);
    
    //fds array
    hmd_file_write_key(fd_buffer, "fds");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_begin_json_array(fd_buffer);
    for (fd = 0; fd < max_fd_count; fd++) {
        errno = 0;
        flags = fcntl(fd, F_GETFD, 0);
        if (flags == -1 && errno) {
            fd_end_mark--;
            if (errno != EBADF || fd_end_mark < 0) {
                break;
            }
            else
                continue;
        }
        current_fd = fd;
        int result = fstat(fd, &filestat);
        if (result != -1){
            if (fd > 0) {
                hmd_file_write_string(fd_buffer, ",");
            }
            if(S_ISBLK(filestat.st_mode)){
                hmd_write_base_info(fd, "block_special");
                continue;
            }
            if(S_ISCHR(filestat.st_mode)){
                hmd_write_base_info(fd, "char_special");
                continue;
            }
            if(S_ISDIR(filestat.st_mode)){
                hmd_write_base_info(fd, "directory");
                continue;
            }
            if(S_ISFIFO(filestat.st_mode)){
                hmd_write_fifo_info(fd, filestat.st_ino);
                continue;
            }
            if (S_ISREG(filestat.st_mode)){
                hmd_write_base_info(fd, "regular_file");
                continue;
            }
            if(S_ISLNK(filestat.st_mode)){
                hmd_write_base_info(fd, "symbolic_link");
                continue;
            }
            if (S_ISSOCK(filestat.st_mode)){
                hmd_write_socket_info(fd);
                continue;
            }
            hmd_write_base_info(fd, "other");
        }
    }
    hmd_file_end_json_array(fd_buffer);
    hmd_file_write_string(fd_buffer, ",");
    
    //max fd
    hmd_file_write_key(fd_buffer, "max_fd");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_uint64(fd_buffer, max_fd_count);
    hmd_file_write_string(fd_buffer, ",");
    
    //current fd
    hmd_file_write_key(fd_buffer, "current_fd");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_uint64(fd_buffer, current_fd);
    
    hmd_file_end_json_object(fd_buffer);
}

#pragma mark - Private

//just get file path
static void hmd_write_base_info(int fd, char *fd_type) {
    hmd_file_begin_json_object(fd_buffer);
    //fd type
    hmd_file_write_key(fd_buffer, "type");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_string_value(fd_buffer, fd_type);
    hmd_file_write_string(fd_buffer, ",");
    //fd
    hmd_file_write_key(fd_buffer, "fd");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_uint64(fd_buffer, fd);
    hmd_file_write_string(fd_buffer, ",");
    //fd path
    char buffer[MAXPATHLEN + 1];
    
    if(fcntl(fd, F_GETPATH, buffer) == -1) {
        COMPILE_ASSERT(sizeof((char[]){"unknown"}) <= MAXPATHLEN);
        strncpy(buffer, "unknown", MAXPATHLEN);
    }
    
    buffer[MAXPATHLEN] = '\0';
    
    size_t absolute_path_length = strlen(buffer);
    
    if(absolute_path_length > NSHomeDirectory_path_length &&
       strncmp(buffer, NSHomeDirectory_path, NSHomeDirectory_path_length) == 0) {
        size_t relative_path_length = absolute_path_length - NSHomeDirectory_path_length;
        memmove(buffer, buffer + NSHomeDirectory_path_length, relative_path_length + 1);
        buffer[relative_path_length] = '\0';
    }
    
    hmd_file_write_key(fd_buffer, "path");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_string_value(fd_buffer, buffer);
    hmd_file_end_json_object(fd_buffer);
    return;
}

static void hmd_write_socket_info(int fd) {
    hmd_file_begin_json_object(fd_buffer);
    
    //fd type
    hmd_file_write_key(fd_buffer, "type");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_string_value(fd_buffer, "socket");
    hmd_file_write_string(fd_buffer, ",");
    
    //fd
    hmd_file_write_key(fd_buffer, "fd");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_uint64(fd_buffer, fd);
    hmd_file_write_string(fd_buffer, ",");
    
    struct sockaddr_in local, peer;
    socklen_t local_len = sizeof(local);
    socklen_t peer_len = sizeof(peer);
    char local_ip[MAX_IP_LEN];
    char peer_ip[MAX_IP_LEN];
    int local_port, peer_port;
    int result = getsockname(fd, (struct sockaddr *)&local, &local_len);
    if (result < 0){
        strncpy(local_ip, "unknown", MAX_IP_LEN);
        local_port = 0;
    }else{
        inet_ntop(AF_INET, &local.sin_addr, local_ip, sizeof(local_ip));
        local_port = ntohs(local.sin_port);
    }
    result = getpeername(fd, (struct sockaddr *)&peer, &peer_len);
    if (result < 0){
        strncpy(peer_ip, "unknown", MAX_IP_LEN);
        peer_port = 0;
    }else{
        inet_ntop(AF_INET, &peer.sin_addr, peer_ip, sizeof(peer_ip));
        peer_port = ntohs(peer.sin_port);
    }
    //local_ip
    hmd_file_write_key(fd_buffer, "local_ip");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_string_value(fd_buffer, local_ip);
    hmd_file_write_string(fd_buffer, ",");
    
    //local_port
    hmd_file_write_key(fd_buffer, "local_port");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_int64(fd_buffer, local_port);
    hmd_file_write_string(fd_buffer, ",");
    
    
    //peer_ip
    hmd_file_write_key(fd_buffer, "peer_ip");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_string_value(fd_buffer, peer_ip);
    hmd_file_write_string(fd_buffer, ",");
    
    //peer_port
    hmd_file_write_key(fd_buffer, "peer_port");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_int64(fd_buffer, peer_port);
    
    hmd_file_end_json_object(fd_buffer);
    
    return;
}

static void hmd_write_fifo_info(int fd, uint64_t inode) {
    hmd_file_begin_json_object(fd_buffer);
    
    //fd type
    hmd_file_write_key(fd_buffer, "type");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_string_value(fd_buffer, "fifo_or_socket");
    hmd_file_write_string(fd_buffer, ",");
    
    //fd
    hmd_file_write_key(fd_buffer, "fd");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_uint64(fd_buffer, fd);
    hmd_file_write_string(fd_buffer, ",");
    
    //fd
    hmd_file_write_key(fd_buffer, "inode");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_uint64(fd_buffer, inode);
    hmd_file_write_string(fd_buffer, ",");
    
    //fd path
    char buffer[MAXPATHLEN + 1];
    
    if(fcntl(fd, F_GETPATH, buffer) == -1) {
        COMPILE_ASSERT(sizeof((char[]){"unknown"}) <= MAXPATHLEN);
        strncpy(buffer, "unknown", MAXPATHLEN);
    }
    
    if(strncmp(buffer, NSHomeDirectory_path, NSHomeDirectory_path_length) == 0){
        strncpy(buffer, buffer + NSHomeDirectory_path_length, MAXPATHLEN);
    }
    
    hmd_file_write_key(fd_buffer, "path");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_string_value(fd_buffer, buffer);
    hmd_file_end_json_object(fd_buffer);
}
