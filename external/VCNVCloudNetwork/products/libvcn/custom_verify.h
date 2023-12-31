/*
* custom verify
*
* Author:taohaiqing(taohaiqing@bytedance.com)
* Date:2018-10-23
* Copyright (c) 2018 bytedance

* This file is part of verify.
*
*/
#pragma once
#include <openssl/ssl.h>
enum ssl_verify_result_t vcn_internal_custom_verify(void* context, void* ssl, const char* host, int port);
void init_custom_verify();
