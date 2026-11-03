#!/bin/bash

## Output directory
##  -o dir
## Target
##  -t debug|release

target=release
out_dir=package

while getopts o:t: arg
do
    case $arg in
    o)
        out_dir=$OPTARG
        ;;
    t)
        target=$OPTARG
        ;;
    *)
        echo "Unknown parameter $arg" >&2
        exit 1
    esac
done

dst_dir=${out_dir}/TvtPlay

rm -rf "${dst_dir}"
mkdir -p "${dst_dir}"

copy_file()
{
    cp -fp "$1" "$2"
    if [ $? -ne 0 ]
    then
        echo "Failed to copy $1" >&2
        exit 1
    fi
}

for data_file in src/Buttons24.bmp src/Buttons32.bmp TvtPlay_Blacklist.txt TvtPlay_Readme.txt TvtPlay_hsw_Readme.txt
do
    copy_file "${data_file}" "${dst_dir}/"
done

for arch in x86 x64
do
    if [ "$arch" = x86 ]
    then
        bin_dir=${target}
    else
        bin_dir=${arch}/${target}
    fi

    mkdir -p "${dst_dir}/${arch}"
    copy_file "src/${bin_dir}/TvtPlay.tvtp" "${dst_dir}/${arch}/"
    copy_file "BonDriver_Pipe_src/${bin_dir}/BonDriver_Pipe.dll" "${dst_dir}/${arch}/"
    copy_file "TvtAudioStretchFilter_src/${bin_dir}/TvtAudioStretchFilter.ax" "${dst_dir}/${arch}/"
done

## Archive name: TvtPlay-<version>-<INFO_FORK>-<git hash>
version=$(grep -aoE "\(ver\.[0-9.]+" src/TvtPlay.cpp | head -n 1 | sed -E 's/^\(ver\.//')
if [[ $(grep -aE "^#define[[:space:]]+INFO_FORK[[:space:]]" src/TvtPlay.cpp) =~ \"(.+)\" ]]
then
    fork=-${BASH_REMATCH[1]}
fi
git_hash=$(git rev-parse --short HEAD)

archive_name=${out_dir}/TvtPlay-${version}${fork}-${git_hash}.zip

sevenz_exe='/c/Program Files/7-Zip/7z.exe'
if [ ! -f "$sevenz_exe" ]
then
    sevenz_exe='/c/Program Files (x86)/7-Zip/7z.exe'
    if [ ! -f "$sevenz_exe" ]
    then
        echo "Unable to find 7z.exe" >&2
        exit 1
    fi
fi

rm -f "${archive_name}"
"$sevenz_exe" a -tzip "${archive_name}" "./${dst_dir}/*" -mx=9
