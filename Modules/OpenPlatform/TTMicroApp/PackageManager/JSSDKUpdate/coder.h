#ifndef _CODER_H_
#define _CODER_H_

// 密码不需要特殊保护，这里仅仅是为了对代码进行混淆，防止苹果检测出JS代码，设置一个简单的密码即可，这个密码与 EncyptJS.sh 中 ZIP_PASSWORD 保持一致
// 这里建议用宏而不是常量，避免「PASSWORD」这样的敏感字段被打进代码内
#define ZIP_PASSWORD @"gadget"

#endif
