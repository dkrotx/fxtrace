/*
 * fxtrace.c
 * 
 * Proxy for libc-wrappers like open,openat and also for libc' fopen.
 * Log absolute filepaths to logfile.
 * All arguments passed throught environment.
 */
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <dlfcn.h>

#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <linux/limits.h>
#include <err.h>

typedef int (open_2_t)(const char *pathname, int flags);
typedef int (open_t)(const char *pathname, int flags, mode_t mode);
typedef open_t open64_t;
typedef open_2_t open64_2_t;
typedef FILE *(fopen_t)(const char *filename, const char *modes);
typedef fopen_t fopen64_t;

typedef void *(dlopen_t)(const char *filename, int flag);

typedef int (openat_t)(int dirfd, const char *pathname, int flags, mode_t mode);
typedef openat_t openat64_t;

typedef int (stat_t)(int ver, const char *path, struct stat *buf);
typedef int (stat64_t)(int ver, const char *path, struct stat64 *buf);

/* original functions */
static open_t      *real_open;
static open_2_t    *real_open_2;
static open64_t    *real_open64;
static open64_2_t  *real_open64_2;
static fopen_t     *real_fopen;
static fopen64_t   *real_fopen64;
static openat_t    *real_openat;
static openat64_t  *real_openat64;
static dlopen_t    *real_dlopen;
static stat_t      *real_stat, *real_lstat;
static stat64_t    *real_stat64, *real_lstat64;

enum { FXTRACE_READ = 1, FXTRACE_WRITE = 2, FXTRACE_EXEC = 4, FXTRACE_STAT = 8 };
static int    log_mask = -1U; /* log all events */
static char   log_path_prefix[PATH_MAX];
static int    debug_mode;
static FILE  *log_file;
static int __initialized = 0;

#define CHECK_INITIALIZED do { if (!__initialized) fxtrace_init(); assert(__initialized ); } while(0)


/* ========================================================================= */
/* UTILITY FUNCTIONS                                                         */
/* ========================================================================= */

static void *
realfn(const char *func)
{
    return dlsym(RTLD_NEXT, func);
}


static int
logstr2mask(const char *s)
{
    int res = 0;

    for (; *s; s++) {
        switch (*s) {
            case 'r': res |= FXTRACE_READ;  break;
            case 'w': res |= FXTRACE_WRITE; break;
            case 'x': res |= FXTRACE_EXEC;  break;
            case 's': res |= FXTRACE_STAT;  break;
            default : return -1;
        }
    }

    return res;
}

static char *
mask2logstr(int mask, char *dst)
{
    char *p = dst;

    if (mask & FXTRACE_READ)  *p++ = 'r';
    if (mask & FXTRACE_WRITE) *p++ = 'w';
    if (mask & FXTRACE_EXEC)  *p++ = 'x';
    if (mask & FXTRACE_STAT)  *p++ = 's';

    *p = '\0';
    return dst;
}


int
mask_from_open(int mode)
{
    if (mode & O_RDWR)
        return FXTRACE_READ | FXTRACE_WRITE;
    if (mode & O_WRONLY)
        return FXTRACE_WRITE;

    return FXTRACE_READ;
}


int
mask_from_fopen(const char *mode)
{
    int res = 0;

    if (*mode == 'r') res = FXTRACE_READ;
    else if (*mode == 'a' || *mode == 'w') res = FXTRACE_WRITE;

    while (*++mode) {
        if (*mode == '+')
            res = FXTRACE_READ | FXTRACE_WRITE;
    }


    return res;
}


static void
log_access(const char *file, int mode)
{
    char path[PATH_MAX];
    
    // fprintf(log_file, "%s\t%d\n", file, mode);

    if (!log_file || !(mode & log_mask))
        return;

    if (realpath(file, path)) {
        char buf[8];

        if (!log_path_prefix[0] || !strncmp(path, log_path_prefix, strlen(log_path_prefix)))
            fprintf(log_file, "%s\t%s\n", mask2logstr(mode, &buf[0]), path);
    }
}


static void
log_access_byfd(int fd, int mode)
{
    char proc_path[32];
    char buf[PATH_MAX + 1];
    ssize_t n;

    snprintf(proc_path, sizeof(proc_path), "/proc/self/fd/%d", fd);
    n = readlink(proc_path, buf, sizeof(buf) - 1);

    if (n > 0) {
        buf[n] = '\0';
        log_access(buf, mode);
    }
}


static void
log_self()
{
    char buf[PATH_MAX + 1];
    ssize_t n = readlink("/proc/self/exe", buf, sizeof(buf) - 1);

    if (n > 0) {
        buf[n] = '\0';
        log_access(buf, FXTRACE_EXEC);
    }
}

static void
log_debug(const char *fmt, ...)
{
    char buf[128];

    if (debug_mode &&
        snprintf(buf, sizeof(buf), "fxtrace: %s\n", fmt) < sizeof(buf))
    {
        va_list ap;
        va_start(ap, fmt);
        vfprintf(stderr, buf, ap);
        va_end(ap);
    }
}


/* ========================================================================= */
/* INITIALIZATION                                                            */
/* ========================================================================= */


static void __attribute__ ((constructor)) 
fxtrace_init(void)
{
    int fd;
    char *logname;
    char *logmode;
    const char *prefix;
    char *debug_param;

    if (__initialized)
        return;


    debug_param = getenv("FXTRACE_DEBUG");
    if (debug_param && debug_param[0])
        debug_mode = 1;

    log_debug("fxtrace_init");
    logname = getenv("FXTRACE_LOG");
    logmode = getenv("FXTRACE_MODE");


    prefix = getenv("FXTRACE_PREFIX");
    if (prefix) {
        /* some programs erase/move their env (dirty prctl(PR_SET_NAME)) */
        strncpy(log_path_prefix, prefix, sizeof(log_path_prefix));
    }

    if (logmode) {
        if ( -1 == (log_mask = logstr2mask(logmode)) )
            errx(1, "Wrong FXTRACE_MODE(\"%s\")", logmode);
    }


    real_open     = (open_t *)realfn("open");
    real_open_2   = (open_2_t *)realfn("__open_2");
    real_open64   = (open64_t *)realfn("open64");
    real_open64_2 = (open64_2_t *)realfn("__open64_2");
    real_openat   = (openat_t *)realfn("openat");
    real_openat64 = (openat64_t *)realfn("openat64");
    real_fopen    = (fopen_t *)realfn("fopen");
    real_fopen64  = (fopen64_t *)realfn("fopen64");
    real_dlopen   = (dlopen_t *)realfn("dlopen");
    real_stat     = (stat_t *)realfn("__xstat");
    real_lstat    = (stat_t *)realfn("__lxstat");
    real_stat64   = (stat64_t *)realfn("__xstat64");
    real_lstat64  = (stat64_t *)realfn("__lxstat64");

    if (logname) {
        fd = (*real_open)(logname, O_APPEND | O_WRONLY | O_CREAT, 0777);
        if (fd == -1) {
            err(1, "failed to open ftrace file: %s", logname);
        }
        fcntl(fd, F_SETFD, fcntl(fd, F_GETFD) | FD_CLOEXEC);

        log_file = fdopen(fd, "a");
        setvbuf(log_file, (char *) NULL, _IOLBF, 0);

        log_self();
    }

    __initialized = 1;
}


/* ========================================================================= */
/* MASKED FUNCTIONS                                                          */
/* ========================================================================= */

int
open(const char *pathname, int flags, ...)
{
    mode_t  creat_mode = 0;
    int fd;

    CHECK_INITIALIZED;
    log_debug("open(%s, %d)", pathname, flags);

    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        creat_mode = va_arg(ap, mode_t);
        va_end(ap);
    }

    fd = (*real_open)(pathname, flags, creat_mode);
    if (fd != -1) {
        log_access(pathname, mask_from_open(flags));
    }

    return fd;
}

int
open64(const char *pathname, int flags, ...)
{
    mode_t  creat_mode = 0;
    int fd;

    CHECK_INITIALIZED;
    log_debug("open64(%s, %d)", pathname, flags);

    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        creat_mode = va_arg(ap, mode_t);
        va_end(ap);
    }

    fd = (*real_open64)(pathname, flags, creat_mode);
    if (fd != -1) {
        log_access(pathname, mask_from_open(flags));
    }

    return fd;
}


int
__open_2(const char *pathname, int flags)
{
    int fd;

    CHECK_INITIALIZED;
    log_debug("__open_2(%s, %d)", pathname, flags);

    fd = (*real_open_2)(pathname, flags);
    if (fd != -1) {
        log_access(pathname, mask_from_open(flags));
    }

    return fd;
}


int
__open64_2(const char *pathname, int flags)
{
    int fd;

    CHECK_INITIALIZED;
    log_debug("__open64_2(%s, %d)", pathname, flags);

    fd = (*real_open64_2)(pathname, flags);
    if (fd != -1) {
        log_access(pathname, mask_from_open(flags));
    }

    return fd;
}


int
openat(int dirfd, const char *pathname, int flags, ...)
{
    mode_t  creat_mode = 0;
    int fd;

    CHECK_INITIALIZED;
    log_debug("openat(%s, %d)", pathname, flags);

    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        creat_mode = va_arg(ap, mode_t);
        va_end(ap);
    }

    fd = (*real_openat)(dirfd, pathname, flags, creat_mode);
    if (fd != -1) {
        log_access_byfd(fd, mask_from_open(flags));
    }

    return fd;
}


int
openat64(int dirfd, const char *pathname, int flags, ...)
{
    mode_t  creat_mode = 0;
    int fd;

    CHECK_INITIALIZED;
    log_debug("openat64(%s, %d)", pathname, flags);

    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        creat_mode = va_arg(ap, mode_t);
        va_end(ap);
    }

    fd = (*real_openat64)(dirfd, pathname, flags, creat_mode);
    if (fd != -1) {
        log_access_byfd(fd, mask_from_open(flags));
    }

    return fd;
}


FILE *
fopen(const char *pathname, const char *modes)
{
    FILE *res;
    
    CHECK_INITIALIZED;
    log_debug("fopen(%s, %s)", pathname, modes);

    res = (*real_fopen)(pathname, modes);
    if (res) {
        log_access(pathname, mask_from_fopen(modes));
    }

    return res;
}

FILE *
fopen64(const char *pathname, const char *modes)
{
    FILE *res;

    CHECK_INITIALIZED;
    log_debug("fopen64(%s, %s)", pathname, modes);

    res = (*real_fopen64)(pathname, modes);
    if (res) {
        log_access(pathname, mask_from_fopen(modes));
    }

    return res;
}


static int
generic_stat(int ver, stat_t *pfn, const char *path, struct stat *buf)
{
    int ret;

    CHECK_INITIALIZED;
    log_debug("stat(%s)", path);

    ret = (*pfn)(ver, path, buf);
    if (ret == 0) {
        /* TODO: actualli we have to differ `stat' and `lstat' */
        log_access(path, FXTRACE_STAT);
    }

    return ret;
}


static int
generic_stat64(int ver, stat64_t *pfn, const char *path, struct stat64 *buf)
{
    int ret;

    CHECK_INITIALIZED;
    log_debug("stat64(%s)", path);

    ret = (*pfn)(ver, path, buf);
    if (ret == 0) {
        /* TODO: actualli we have to differ `stat' and `lstat' */
        log_access(path, FXTRACE_STAT);
    }

    return ret;
}


int __xstat(int ver, const char *path, struct stat *buf) { return generic_stat(ver, real_stat, path, buf); }
int __lxstat(int ver, const char *path, struct stat *buf) { return generic_stat(ver, real_lstat, path, buf); }
int __xstat64(int ver, const char *path, struct stat64 *buf) { return generic_stat64(ver, real_stat64, path, buf); }
int __lxstat64(int ver, const char *path, struct stat64 *buf) { return generic_stat64(ver, real_lstat64, path, buf); }
/* we don't care about fstat/fstat64 because fd should appeared from open() */


void *
dlopen(const char *filename, int flag)
{
    void *addr;

    CHECK_INITIALIZED;
    log_debug("dlopen(%s, %d)", filename, flag);

    addr = (*real_dlopen)(filename, flag);
    if (addr) {
        log_access(filename, FXTRACE_EXEC | FXTRACE_READ);
    }

    return addr;
}
