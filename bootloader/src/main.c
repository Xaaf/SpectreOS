#include <efi.h>
#include <efilib.h>

EFI_STATUS
EFIAPI
efi_main(EFI_HANDLE image_handle, EFI_SYSTEM_TABLE* system_table)
{
    InitializeLib(image_handle, system_table);
    Print(L"SpectreOS!\n");

    return EFI_SUCCESS;
}