//
//  HMDCrashExceptionFD.c
//  Pods
//
//  Created by wangyinhui on 2022/1/5.
//

#include "HMDCrashExceptionExtend.h"
#include "HMDCrashFileBuffer.h"
#include "HMDCrashSDKLog.h"
#include <errno.h>
#include <unistd.h>
#include "HMDCrashDirectory_LowLevel.h"
#include <sys/fcntl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <string.h>
#include "HMDMacro.h"


#pragma mark - fd

#define MAX_IP_LEN 20

#define FD_END_MARK 10

//record fd info when crash
static FileBuffer fd_buffer = FileBufferInvalid;

static int home_path_len;

//just get file path
void hmd_write_base_info(int fd, char *fd_type) {
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
    char buf[MAXPATHLEN];
    fcntl(fd , F_GETPATH, buf);
    if (errno != 0){
        strncpy(buf, "unknown", MAXPATHLEN - 1);
        COMPILE_ASSERT(MAXPATHLEN - 1 >= 0);
    }else{
        if(strncmp(buf, HMDApplication_home_path(), home_path_len) == 0){
            size_t len = strlen(buf);
            memmove(buf, buf + home_path_len, len - home_path_len);
            buf[len - home_path_len] = '\0';
        }
    }
    hmd_file_write_key(fd_buffer, "path");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_string_value(fd_buffer, buf);
    hmd_file_end_json_object(fd_buffer);
    return;
}

void hmd_write_socket_info(int fd) {
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
void hmd_write_fifo_info(int fd, uint64_t inode) {
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
    char buf[MAXPATHLEN+1];
    fcntl(fd , F_GETPATH, buf);
    if (errno != 0){
        strncpy(buf, "unknown", MAXPATHLEN);
    }else{
        if(strncmp(buf, HMDApplication_home_path(), home_path_len) == 0 ){
            strncpy(buf, buf+home_path_len, MAXPATHLEN);
        }
    }
    hmd_file_write_key(fd_buffer, "path");
    hmd_file_write_string(fd_buffer, ":");
    hmd_file_write_string_value(fd_buffer, buf);
    hmd_file_end_json_object(fd_buffer);
}

int create_exception_fd(void) {
    home_path_len = (int)strlen(HMDApplication_home_path());
    if (fd_buffer != FileBufferInvalid) {
        close(fd_buffer);
        fd_buffer = FileBufferInvalid;
    }
    const char *fd_path = HMDCrashDirectory_fd_info_path();
    FileBuffer fd = FileBufferInvalid;
    if((fd = hmd_file_open_buffer(fd_path)) != FileBufferInvalid) {
        if (fd_buffer == FileBufferInvalid) {
            fd_buffer = fd;
        }
        else {
            close(fd);
        }
        return fd;
    }
    SDKLog_error("failed to create fd exception file for path %s", fd_path);
    return errno;
}

int remove_exception_fd(void) {
    if (fd_buffer != FileBufferInvalid) {
        close(fd_buffer);
    }
    const char *fd_path = HMDCrashDirectory_fd_info_path();
    int ret = remove(fd_path);
    if (ret != 0) {
        SDKLog_error("remove file error, errno:%d, path:%s", errno, fd_path);
    }
    return ret;
}

void hmd_fetch_current_fds(void) {
    if (fd_buffer == FileBufferInvalid){
        SDKLog_error("failed to write fd exception file");
        return;
    }
    
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
    
    close(fd_buffer);
    
}
