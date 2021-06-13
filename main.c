#include <stdio.h>
#include <stdlib.h>

extern void decode_ean8(unsigned char *out, void *img, int bar_bytes);

int main(int argc, const char *argv[]) {
    if (argc != 2) {
        printf("No arguments, please enter file name");
        return 0;
    }
    const char* file_path = argv[1];
    FILE *img;
    img = fopen(file_path, "rb");
    if(!img){
        printf("File does not exist");
        return 1;
    }

    int bpp;
    fseek(img, 28, SEEK_SET);
    fread(&bpp, 2, 1, img);
    if(bpp != 1) {
        printf("Unsupported bpp format\n");
        return 1;
    }

    int img_width;
    fseek(img, 18, SEEK_SET);
    fread(&img_width, 4, 1, img);
    if(img_width < 67 || img_width%67 != 0) {
        printf("Invalid image size\n");
        return 1;
    }
    int pixels_per_column = img_width/67;

    unsigned int bmp_size, offset;
    fseek(img, 10, SEEK_SET);
    fread(&offset, 4, 1, img);

    fseek(img, 2, SEEK_SET);
    fread(&bmp_size, 4, 1, img);

    void *img_size = malloc(bmp_size);
    fseek(img, 0, SEEK_SET);
    fread(img_size, 1, bmp_size, img);

    void *data = offset + img_size;
    unsigned char* out = malloc(sizeof(unsigned char)*9);
    decode_ean8(out, data, pixels_per_column);

    printf("Decoded code: ");
    for(int i=0; i<8; i++){
        printf("%d", *out);
        out++;
    }
    printf("\n");
    fclose(img);
    return 0;
}
