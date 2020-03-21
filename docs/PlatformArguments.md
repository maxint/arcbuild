# Arguments for Platforms


### Windows (Visual Studio)

```
-DPLATFORM={vc6,vs2012,vs2013,vs2015,vs2017}
-DARCH={x86,x64,arm} (x86 by default)
```


### Linux (gcc)

```
-DPLATFORM=linux
-DARCH={x86,x64} (x86 by default)
```


### Android (gcc)

```
-DROOT=<NDK root directory> (default is from ANDROID_NDK_ROOT enviroment variable)
-DPLATFORM=android
-DARCH={arm,armv7-a,arm64,x86,x64} (armv7-a by default)
-DSTL={c++_static,c++_shared,system,gnustl_static,gnustl_shared,stlport_static,stlport_shared,gabi++_static,gabi++_shared} (default is determined by NDK version)
```


### iOS (gcc)

```
-DPLATFORM=ios
-DARCH=[armv7;][armv7s;][arm64;][arm64e] (armv7;armv7s;arm64;arm64e by default)
-DIOS_BITCODE=(ON,OFF) (OFF by default)
```


### TODO

- More platforms
