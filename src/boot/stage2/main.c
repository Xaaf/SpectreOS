#include "stdint.h"
#include "stdio.h"

void _cdecl cstart_(uint16_t boot_drive)
{
    printf("Entered stage 2, boot drive %d\r\n", boot_drive);
    for(;;);
}
