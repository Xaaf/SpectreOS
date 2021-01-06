#include <efi.h>
#include <efilib.h>

EFIAPI
EFI_STATUS efi_main (EFI_HANDLE imageHandle, EFI_SYSTEM_TABLE *systemTable)
{
    InitializeLib(imageHandle, systemTable);
    Print(L"Hello, SpectreOS!\r\n");

    return EFI_SUCCESS;
}