#include <efi.h>
#include <efilib.h>

EFI_STATUS efi_main(EFI_HANDLE image_handle, EFI_SYSTEM_TABLE* system_table)
{
    EFI_STATUS status;
    EFI_INPUT_KEY key;

    // Store system table for use in other functions
    EFI_SYSTEM_TABLE* sys_table = system_table;

    // EFI Applications use Unicode and CRLF
    status = sys_table->ConOut->OutputString(sys_table->ConOut, L"Hello Spectre!\r\n");

    if (EFI_ERROR(status))
    {
        return status;
    }

    // Empty console input buffer
    status = sys_table->ConIn->Reset(sys_table->ConIn, FALSE);
    if (EFI_ERROR(status))
    {
        return status;
    }

    // Wait for keystroke
    while ((status = sys_table->ConIn->ReadKeyStroke(sys_table->ConIn, &key)) == EFI_NOT_READY);

    return status;
}