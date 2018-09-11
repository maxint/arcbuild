#ifndef __SAMPLE_LIB_H__
#define __SAMPLE_LIB_H__

#if defined(sample_lib_EXPORTS)
#   if defined(_WINDOWS) || defined(__CYGWIN__)
#       define SLIB_DLL __declspec(dllexport)
#   elif defined(__GNUC__) && __GNUC__ >= 4
#       define SLIB_DLL __attribute__ ((visibility ("default")))
#   else
#       define SLIB_DLL
#   endif
#else
#   define SLIB_DLL
#endif

#ifdef __cplusplus
extern "C" {
#endif

SLIB_DLL void SampleLib_Test();

#ifdef __cplusplus
}
#endif

#endif // end of header file
