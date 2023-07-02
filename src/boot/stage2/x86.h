#ifndef X86_H
#define X86_H

#include "stdint.h"

void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t* qoutient_out, uint32_t* remainder_out);
void _cdecl x86_write_char_teletype(char c, uint8_t page);

#endif
