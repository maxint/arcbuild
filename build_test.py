# coding: utf-8
# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>

from __future__ import print_function
import os
import subprocess
import glob
import sys
import zipfile


def build(platform, arch, extra_args):
    old_pwd = os.getcwd()
    build_dir = '_build/%s_%s' % (platform, arch)
    try:
        if not os.path.exists(build_dir):
            os.makedirs(build_dir)
        os.chdir(build_dir)
        args = [
            '-DPLATFORM=%s' % platform,
            '-DARCH=%s' % arch,
            '-DVERBOSE=4',
        ]
        args += ['-P', '../../arcbuild.cmake', '../..']
        args = ['cmake'] + args + (extra_args or [])
        cmd = ' '.join(args)
        print('Calling:', cmd)
        subprocess.check_call(cmd, shell=True)
        subprocess.check_call(['make'], shell=True)
    finally:
        os.chdir(old_pwd)


def batch_build(configs):
    for cfg in configs:
        if len(cfg) == 2:
            platform, arch = cfg
            extra_args = None
        elif len(cfg) == 3:
            platform, arch, extra_args = cfg
        build(platform, arch, extra_args)


def main():
    if os.name == 'nt':
        os.environ['PATH'] += r';{0}\CMake\bin'.format(os.environ['ProgramFiles(x86)'])
    # print os.environ['PATH']

    configs = []
    root = os.environ.get('ANDROID_NDK_ROOT')
    if os.name == 'nt':
        candidate_root = r'D:\sdk\android-ndk-r11b' # convenient for developement
        if not root and os.path.isdir(candidate_root):
            root = candidate_root
    if root and os.path.exists(root):
        configs += [
            ('android', 'armv7-a', ['-DROOT=%s' % root]),
            ('android', 'armv7-a', ['-DROOT=%s' % root, '-DSTL=stlport_static']),
            ('android', 'armv7-a', ['-DROOT=%s' % root, '-DSTL=c++_static']),
            ('android', 'arm64', ['-DROOT=%s' % root]),
            ('android', 'x86', ['-DROOT=%s' % root]),
            ('android', 'x64', ['-DROOT=%s' % root]),
        ]
    if os.name == 'nt':
        if os.path.exists(r'C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat'):
            configs += [
                ('vs2013', 'x86'),
                ('vs2013', 'x64'),
            ]
        if os.path.exists(r'C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat'):
            configs += [
                ('vs2015', 'x86'),
                ('vs2015', 'x64'),
            ]
        if os.path.exists(
                r'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat'):
            configs += [
                ('vs2017', 'x86'),
                ('vs2017', 'x64'),
            ]
    elif sys.platform.startswith('linux'):
        if sys.maxsize > 2**32:
            configs += [ ('linux', 'x64')]
        else:
            configs += [ ('linux', 'x86')]

    batch_build(configs)


if __name__ == '__main__':
    main()
