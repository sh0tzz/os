#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef struct {
    uint8_t     boot_jump_instruction[3];
    uint8_t     oem_identifier[8];
    uint16_t    bytes_per_sector;
    uint8_t     sectors_per_cluster;
    uint16_t    reserver_sectors;
    uint8_t     fat_count;
    uint16_t    dir_entry_count;
    uint16_t    total_sectors;
    uint8_t     media_descriptor_type;
    uint16_t    sectors_per_fat;
    uint16_t    sectors_per_track;
    uint16_t    heads;
    uint32_t    hidden_sectors;
    uint32_t    large_sectors;
    // extended boot record
    uint8_t     drive_number;
    uint8_t     _reserved;
    uint8_t     signature;
    uint8_t     volume_id;
    uint8_t     volume_label[11];
    uint8_t     system_id[8];
} __attribute__((packed)) bootsec;

typedef struct {
    uint8_t name[11];
    uint8_t attributes;
    uint8_t _reserved;
    uint8_t created_time_tenths;
    uint16_t created_time;
    uint16_t created_date;
    uint16_t accessed_date;
    uint16_t first_cluster_high;
    uint16_t modified_time;
    uint16_t modified_date;
    uint16_t first_cluster_low;
    uint32_t size;
} __attribute__((packed)) directory_entry;

bootsec g_bootsec;
uint8_t* g_fat = NULL;
directory_entry* g_rootdir = NULL;
uint32_t g_rootdir_end;


bool read_bootsec(FILE* disk)
{
    return fread(&g_bootsec, sizeof(g_bootsec), 1, disk) > 0;
}

bool read_sectors(FILE* disk, uint32_t lba, uint32_t count, void* buffer_out)
{
    bool ok = true;
    ok = ok && (fseek(disk, lba * g_bootsec.bytes_per_sector, SEEK_SET) == 0);
    ok = ok && (fread(buffer_out, g_bootsec.bytes_per_sector, count, disk) == count);
    return ok;
}

bool read_fat(FILE* disk)
{
    g_fat = (uint8_t*) malloc(g_bootsec.sectors_per_fat * g_bootsec.bytes_per_sector);
    return read_sectors(disk, g_bootsec.reserver_sectors, g_bootsec.sectors_per_fat, g_fat);
}

bool read_rootdir(FILE* disk)
{
    uint32_t lba = g_bootsec.reserver_sectors + g_bootsec.sectors_per_fat * g_bootsec.fat_count;
    uint32_t size = sizeof(directory_entry) * g_bootsec.dir_entry_count;
    uint32_t sectors = (size / g_bootsec.bytes_per_sector);
    if (size % g_bootsec.bytes_per_sector > 0) {
        sectors++;
    }
    g_rootdir_end = lba + sectors;
    g_rootdir = (directory_entry*) malloc(sectors * g_bootsec.bytes_per_sector);
    return read_sectors(disk, lba, sectors, g_rootdir);
}

directory_entry* find_file(const char* name)
{
    for (uint32_t i = 0; i < g_bootsec.dir_entry_count; i++) {
        if (memcmp(name, g_rootdir[i].name, 11) == 0) {
            return &g_rootdir[i];
        }
    }
    return NULL;
}

bool read_file(directory_entry* file_entry, FILE* disk, uint8_t* output_buffer)
{
    bool ok = true;
    uint16_t current_cluster = file_entry->first_cluster_low;
    while (true) {
        printf("cluster: %x\n", current_cluster);
        uint32_t lba = g_rootdir_end + (current_cluster - 2) * g_bootsec.sectors_per_cluster;
        ok = ok && read_sectors(disk, lba, g_bootsec.sectors_per_cluster, output_buffer);
        output_buffer += g_bootsec.sectors_per_cluster * g_bootsec.bytes_per_sector;

        uint32_t fat_index = current_cluster * 3 / 2;
        if (current_cluster % 2 == 0) {
            current_cluster = (*(uint16_t*)(g_fat + fat_index)) & 0x0FFF;
        } else {
            current_cluster = (*(uint16_t*)(g_fat + fat_index)) >> 4;
        }

        if (!ok || !(current_cluster < 0x0FF8)) {
            break;
        }
    }
    return ok;
}

int main(int argc, char** argv)
{
    if (argc < 3) {
        printf("USAGE: %s <diskimage> <filename>\n", argv[0]);
        return -1;
    }

    FILE *disk = fopen(argv[1], "rb");
    if (!disk) {
        fprintf(stderr, "ERROR: Could not open disk image %s\n", argv[1]);
        return -1;
    }

    if (!read_bootsec(disk)) {
        fprintf(stderr, "ERROR: Could not read boot sector\n");
        return -1; 
    }

    if (!read_fat(disk)) {
        fprintf(stderr, "ERROR: Could not read FAT\n");
        return -1; 
    }

    if (!read_rootdir(disk)) {
        fprintf(stderr, "ERROR: Could not read rootdir\n");
        free(g_fat);
        free(g_rootdir);
        return -1; 
    }

    directory_entry* file_entry = find_file(argv[2]);
    if (!file_entry) {
        fprintf(stderr, "ERROR: Could not find file %s\n", argv[2]);
        free(g_fat);
        free(g_rootdir);
        return -1;
    }

    uint8_t* buffer = (uint8_t*) malloc(file_entry->size + g_bootsec.bytes_per_sector);
    if (!read_file(file_entry, disk, buffer)) {
        fprintf(stderr, "ERROR: Could not read file %s\n", argv[2]);
        free(g_fat);
        free(g_rootdir);
        free(buffer);
        return -1;
    }

    for (size_t i = 0; i < file_entry->size; i++) {
        if (isprint(buffer[i])) {
            fputc(buffer[i], stdout);
        } else {
            printf("<%02x>", buffer[i]);
        }
    }
    printf("\n");

    free(g_fat);
    free(g_rootdir);
    return 0;
}