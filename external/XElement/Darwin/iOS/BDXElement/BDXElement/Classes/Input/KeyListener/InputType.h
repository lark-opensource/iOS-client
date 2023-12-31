//
//  InputType.h
//  XElement
//
//  Created by zhangkaijie on 2021/6/6.
//

// Bit definitions for input type
static NSInteger const TYPE_MASK_CLASS = 0x0000000f;
static NSInteger const TYPE_MASK_FLAGS = 0x00fff000;

// Class for normal text
static NSInteger const TYPE_CLASS_TEXT = 0x00000001;

// Class for numeric text
static NSInteger const TYPE_CLASS_NUMBER = 0x00000002;
static NSInteger const TYPE_NUMBER_FLAG_SIGNED = 0x00001000;
static NSInteger const TYPE_NUMBER_FLAG_DECIMAL = 0x00002000;

// Class for a phone number
static NSInteger const TYPE_CLASS_PHONE = 0x00000003;
