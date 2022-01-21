@echo off

IF DEFINED WORKSPACE_STIGMEE (echo [106m WORKSPACE_STIGMEE IS defined, continuing...[0m) ELSE (echo [101m WORKSPACE_STIGMEE is NOT set, please set it and retry ![0m )

echo [42m Setting environment... [0m 

set SCRIPT_PATH=%WORKSPACE_STIGMEE%/packages/install
set STIGMEE_PROJECT_PATH=%WORKSPACE_STIGMEE%/stigmee
set STIGMEE_BUILD_PATH=%STIGMEE_PROJECT_PATH%/build

set GODOT_VERSION=3.4.2-stable
set GODOT_ROOT_PATH=%WORKSPACE_STIGMEE%/godot/%GODOT_VERSION%
set GODOT_CPP_PATH=%GODOT_ROOT_PATH%/cpp
set GODOT_EDITOR_PATH=%GODOT_ROOT_PATH%/editor
set GODOT_EDITOR_BIN_PATH=%GODOT_EDITOR_PATH%/bin
set GODOT_EDITOR_ALIAS=%WORKSPACE_STIGMEE%/godot-editor

set GODOT_GDNATIVE_PATH=%WORKSPACE_STIGMEE%/godot/gdnative
set CEF_GDNATIVE_PATH=%GODOT_GDNATIVE_PATH%/browser
set STIGMARK_GDNATIVE_PATH=%GODOT_GDNATIVE_PATH%/stigmark

set GDCEF_PATH=%CEF_GDNATIVE_PATH%/gdcef
set GDCEF_PROCESSES_PATH=%CEF_GDNATIVE_PATH%/gdcef_subprocess
set GDCEF_THIRDPARTY_PATH=%CEF_GDNATIVE_PATH%/thirdparty
set CEF_PATH=%GDCEF_THIRDPARTY_PATH%/cef_binary

set WEBSITE=https://cef-builds.spotifycdn.com
set CEF_TARBALL=cef_binary_97.1.5%%2Bg2b00258%%2Bchromium-97.0.4692.71_windows64.tar.bz2

echo [42m Compiling godot-cpp: [0m 

cd %GODOT_CPP_PATH%
scons platform=windows target=release --jobs=8

echo [42m Compiling Editor: [0m 

cd %GODOT_EDITOR_PATH%
scons platform=windows --jobs=8 

if exist "%CEF_PATH%/Release/libcef.dll" (
    echo [106m CEF libraries already present, continuing...[0m 
) else (
    echo [101m CEF libraries Missing ![0m
    echo [45m Downloading CEF automated build... [0m 
    mkdir %GDCEF_THIRDPARTY_PATH%
    cd %GDCEF_THIRDPARTY_PATH%
    curl -o cef.tar.bz2 %WEBSITE%/%CEF_TARBALL%
    tar -xf cef.tar.bz2
	echo [45m Extracted CEF [0m 
    for /F "tokens=* USEBACKQ" %%G in (`dir /b cef_binary_*`) do (
	    echo renaming [93m %%G [0m into [94m cef_binary [0m 
    	rename "%%G" cef_binary
    )
)
cd %CEF_PATH%
echo [45m Patching cmake variables and MakeFile... [0m 
robocopy /NFL /NDL /NJH /nc /ns /np "%SCRIPT_PATH%" "%CEF_PATH%" libcef_dll_wrapper_cmake
robocopy /NFL /NDL /NJH /nc /ns /np "%SCRIPT_PATH%" "%CEF_PATH%/cmake" cef_variables_cmake
del CMakeLists.txt
ren libcef_dll_wrapper_cmake CMakeLists.txt
cd %CEF_PATH%/cmake
del cef_variables.cmake
ren cef_variables_cmake cef_variables.cmake
cd %CEF_PATH%
echo [45m Preparing the Release build... [0m 
cmake -DCMAKE_BUILD_TYPE=Release .
echo [45m Minimal build... [0m 
cmake --build . --config Release 2> nul


echo [42m Installing CEF to %STIGMEE_BUILD_PATH%...[0m 

echo [93m %CEF_PATH%/Release [v8_context_snapshot.bin icudtl.dat *.pak *.dll] [0m into [94m %STIGMEE_BUILD_PATH% [0m 
robocopy /NFL /NDL /NJH /nc /ns /np "%CEF_PATH%/Release" "%STIGMEE_BUILD_PATH%" v8_context_snapshot.bin *.dll
mkdir "%STIGMEE_BUILD_PATH%/locales"
echo [93m %CEF_PATH%/Resources [*.dat *.pak] [0m into [94m %STIGMEE_BUILD_PATH% [0m 
robocopy /NFL /NDL /NJH /nc /ns /np "%CEF_PATH%/Resources" "%STIGMEE_BUILD_PATH%" *.pak *.dat
echo [93m %CEF_PATH%/Resources/locales [*.*] [0m into [94m %STIGMEE_BUILD_PATH%/locales [0m 
robocopy /NFL /NDL /NJH /nc /ns /np "%CEF_PATH%/Resources/locales" "%STIGMEE_BUILD_PATH%/locales" *.*

echo [42m Compiling libgdcef.dll: [0m 
cd %GDCEF_PATH%
scons platform=windows target=release --jobs=8
echo [42m Compiling cefSubProcess.exe: [0m 
cd %GDCEF_PROCESSES_PATH%
scons platform=windows target=release --jobs=8

echo [42m Compiling Stigmark Client: [0m 
cd %STIGMARK_GDNATIVE_PATH%
set LIB_STIGMARK=%STIGMARK_GDNATIVE_PATH%/target/debug/stigmark_client
call build-windows.cmd
echo [42m Installing stigmark_client library as libstigmark_client.dll...[0m 
echo [93m %STIGMARK_GDNATIVE_PATH%/target/debug/ [stigmark_client.dll] [0m into [94m %STIGMEE_BUILD_PATH% [0m 
robocopy /NFL /NDL /NJH /nc /ns /np %STIGMARK_GDNATIVE_PATH%/target/debug/ %STIGMEE_BUILD_PATH% stigmark_client.dll
cd %STIGMEE_BUILD_PATH%
del libstigmark_client.dll
echo renaming as libstigmark_client.dll (for gdnative usage)
ren stigmark_client.dll libstigmark_client.dll
echo [106m Great, all work done ![0m 
cd %SCRIPT_PATH%