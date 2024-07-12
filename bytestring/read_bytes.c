#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>
#include <fcntl.h>
#include "kklib.h"
/*  */
/* int kk_os_read_text_file2(kk_string_t path, kk_bytes_t* result, kk_context_t* ctx) */
/* { */
/*   kk_file_t f; */
/*   int err = kk_posix_open(path, O_RDONLY, 0, &f, ctx); */
/*   if (err != 0) return err; */
/*  */
/*   kk_ssize_t len; */
/*   err = kk_posix_fsize(f, &len); */
/*   if (err != 0) { */
/*     kk_posix_close(f); */
/*     return err; */
/*   } */
/*  */
/*   FILE *f = fopen("textfile.txt", "rb"); */
/*   fseek(f, 0, SEEK_END); */
/*   long fsize = ftell(f); */
/*   fseek(f, 0, SEEK_SET);  #<{(| same as rewind(f); |)}># */
/*  */
/*   char *string = malloc(fsize + 1); */
/*   fread(string, fsize, 1, f); */
/*   fclose(f); */
/*  */
/* string[fsize] = 0; */
/*  */
/* // use the string, then ... */
/*  */
/* free(string); */
/*   uint8_t* cbuf; */
/*   kk_bytes_t buf = kk_bytes_alloc_buf(len, &cbuf, ctx); */
/*  */
/*   kk_ssize_t nread; */
/*   err = kk_posix_read_retry(f, cbuf, len, &nread); */
/*   kk_posix_close(f); */
/*   if (err < 0) { */
/*     kk_bytes_drop(buf, ctx); */
/*     return err; */
/*   } */
/*   if (nread < len) { */
/*     buf = kk_bytes_adjust_length(buf, nread, ctx); */
/*   } */
/*  */
/*   *result = buf; */
/*   return 0; */
/* } */

static kk_vector_t kk_os_read_bytes( kk_string_t path, kk_context_t* ctx ) {
    FILE *f;
  kk_with_string_as_qutf8_borrow(path, bpath, ctx) {
      f = fopen(bpath, "rb");
  }
  fseek(f, 0, SEEK_END);
  long fsize = ftell(f);
  fseek(f, 0, SEEK_SET);  /* same as rewind(f); */

  char *str = malloc(fsize + 1);
  fread(str, fsize, 1, f);
  fclose(f);

  kk_box_t* v;
  kk_vector_t vec = kk_vector_alloc_uninit(fsize, &v, ctx);

  for (kk_ssize_t i = 0; i < fsize; i++) {
    v[i] = kk_integer_box(kk_integer_from_int8(str[i], ctx), ctx);
  }
    
  free(str);
  return vec;
}

/* static kk_std_core_exn__error kk_os_read_text_file_error( kk_string_t path, kk_context_t* ctx ) { */
/* static kk_vector_t kk_os_read_bytes( kk_string_t path, kk_context_t* ctx ) { */
/*   kk_bytes_t buf; */
/*  */
/*   const int err = kk_os_read_text_file2(path,&buf,ctx); */
/*  */
/*   kk_ssize_t len; */
/*   const uint8_t* const s = kk_bytes_buf_borrow(str, &len, ctx); */
/*  */
/*   int8_t* v; */
/*   kk_vector_t vec = kk_vector_alloc_uninit(len, &v, ctx); */
/*  */
/*   for (kk_size_t i = 0; i < len; i++) { */
/*     v[i] = s[i]; */
/*   } */
/*      */
/*   return vec; */
/*   // if (err != 0) return kk_error_from_errno(err,ctx); */
/*   //          else return kk_error_ok(kk_string_box(content),ctx); */
/* } */
/*  */
