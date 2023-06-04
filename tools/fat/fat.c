#include <ctype.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef uint8_t bool;
#define true 1
#define false 0

typedef struct 
{
    uint8_t BootJumpInstruction[3];
    uint8_t OemIdentifier[8];
    uint16_t BytesPerSector;
    uint8_t SectorsPerCluster;
    uint16_t ReservedSectors;
    uint8_t FatCount;
    uint16_t DirEntryCount;
    uint16_t TotalSectors;
    uint8_t MediaDescriptorType;
    uint16_t SectorsPerFat;
    uint16_t SectorsPerTrack;
    uint16_t Heads;
    uint32_t HiddenSectors;
    uint32_t LargeSectorCount;

    // Extended boot record
    uint8_t DriveNumber;
    uint8_t _Reserved;
    uint8_t Signature;
    uint32_t VolumeId;          // Serial number, value doesn't matter
    uint8_t VolumeLabel[11];    // 11 bytes, padded with spaces
    uint8_t SystemId[8];

    // ...boot sector code isn't important here
} __attribute__((packed)) BootSector;

typedef struct 
{
    uint8_t Name[11];
    uint8_t Attributes;
    uint8_t Reserved_;
    uint8_t CreationTimeTenths;
    uint16_t CreationTime;
    uint16_t CreationDate;
    uint16_t LastAccessDate;
    uint16_t FirstClusterHigh;
    uint16_t LastWriteTime;
    uint16_t LastWriteDate;
    uint16_t FirstClusterLow;
    uint32_t FileSize;
} __attribute__((packed)) DirectoryEntry;

BootSector g_BootSector;
uint8_t* g_Fat = NULL;
DirectoryEntry* g_RootDirectory = NULL;
uint32_t g_RootDirectoryEnd;

bool read_boot_sector(FILE* disk)
{
    return fread(&g_BootSector, sizeof(g_BootSector), 1, disk) > 0;
}

bool read_sectors(FILE* disk, uint32_t lba, uint32_t readCount, void* bufferOut)
{
    bool ok = true;

    ok = ok && (fseek(disk, lba * g_BootSector.BytesPerSector, SEEK_SET) == 0);
    ok = ok && (fread(bufferOut, g_BootSector.BytesPerSector, readCount, disk) == readCount);

    return ok;
}

bool read_fat(FILE* disk)
{
    g_Fat = (uint8_t*) malloc(g_BootSector.SectorsPerFat * g_BootSector.BytesPerSector);
    return read_sectors(disk, g_BootSector.ReservedSectors, g_BootSector.SectorsPerFat, g_Fat);
}

bool read_root_directory(FILE* disk)
{
    uint32_t lba = g_BootSector.ReservedSectors + g_BootSector.SectorsPerFat * g_BootSector.FatCount;
    uint32_t size = sizeof(DirectoryEntry) * g_BootSector.DirEntryCount;
    uint32_t sectors = size / g_BootSector.BytesPerSector;

    // Round up to prevent issues
    if (size % g_BootSector.BytesPerSector > 0)
        sectors++;

    g_RootDirectoryEnd = lba + sectors;
    g_RootDirectory = (DirectoryEntry*) malloc(sectors * g_BootSector.BytesPerSector);
    return read_sectors(disk, lba, sectors, g_RootDirectory);
}

DirectoryEntry* find_file(const char* name)
{
    for (uint32_t i = 0; i < g_BootSector.DirEntryCount; i++) 
    {
        if (memcmp(name, g_RootDirectory[i].Name, 11) == 0)     // memcmp(src, dest, size)
        {
            return &g_RootDirectory[i];
        }
    }

    return NULL;
}

bool read_file(DirectoryEntry* fileEntry, FILE* disk, uint8_t* outputBuffer)
{
    bool ok = true;
    uint16_t currentCluster = fileEntry->FirstClusterLow;

    do {
        uint32_t lba = g_RootDirectoryEnd + (currentCluster - 2) * g_BootSector.SectorsPerCluster;
        ok = ok && read_sectors(disk, lba, g_BootSector.SectorsPerCluster, outputBuffer);
        outputBuffer += g_BootSector.SectorsPerCluster * g_BootSector.BytesPerSector;

        uint32_t fatIndex = currentCluster * 3 / 2;

        if (currentCluster % 2 == 0)
            currentCluster = (*(uint16_t*)(g_Fat + fatIndex)) & 0x0FFF; // Bitmask the top bits to get the lower 12 bits
        else
            currentCluster = (*(uint16_t*)(g_Fat + fatIndex)) >> 4;     // Take the upper 12 bits
    } while (ok && currentCluster < 0xFF8);                             // 0xFF8 marks the end of a file's data chain

    return ok;
}

int main(int argc, char** argv) 
{
    if (argc < 3)
    {
        printf("Syntax: %s <disk image> <file name>\n", argv[0]);
        return -1;
    }

    FILE* disk = fopen(argv[1], "rb");
    if (!disk)
    {
        fprintf(stderr, "Cannot open disk image %s!\n", argv[1]);
        return -1;
    }

    if (!read_boot_sector(disk))
    {
        fprintf(stderr, "Failed to read boot sector!\n");
        return -2;
    }

    if (!read_fat(disk))
    {
        fprintf(stderr, "Failed to read FAT!\n");
        free(g_Fat);
        return -3;
    }

    if (!read_root_directory(disk))
    {
        fprintf(stderr, "Failed to read root directory!\n");
        free(g_Fat);
        free(g_RootDirectory);
        return -4;
    }

    DirectoryEntry* fileEntry = find_file(argv[2]);
    if (!fileEntry)
    {
        fprintf(stderr, "Failed to find file '%s'!\n", argv[2]);
        free(g_Fat);
        free(g_RootDirectory);
        return -5;
    }

    uint8_t* buffer = (uint8_t*) malloc(fileEntry->FileSize + g_BootSector.BytesPerSector); // Allocate an extra sector to prevent segfault
    if (!read_file(fileEntry, disk, buffer))
    {
        fprintf(stderr, "Failed to read file '%s'!\n", argv[2]);
        free(g_Fat);
        free(g_RootDirectory);
        free(buffer);
        return -6;
    }

    for (size_t i = 0; i < fileEntry->FileSize; i++)
    {
        if (isprint(buffer[i]))
            fputc(buffer[i], stdout);
        else
            fprintf("<%02x>", buffer[i]);
    }

    printf("\n");

    free(buffer);
    free(g_Fat);
    free(g_RootDirectory);
    return 0;
}