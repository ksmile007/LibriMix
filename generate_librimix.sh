#!/bin/bash
set -eu  # Exit on error

storage_dir=$1
librispeech_dir=$storage_dir/LibriSpeech
wham_dir=$storage_dir/wham_noise
librimix_outdir=$storage_dir/

function LibriSpeech_dev_clean() {
	if ! test -e $librispeech_dir/dev-clean; then
		echo "Download LibriSpeech/dev-clean into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 http://www.openslr.org/resources/12/dev-clean.tar.gz -P $storage_dir
		# <<<<< 더한 것 - tar -xzf 가 아무것도 안 찍어 멈춘 것처럼 보임
		echo "untar start  - dev-clean.tar.gz (322M)"
		tar -xzf $storage_dir/dev-clean.tar.gz -C $storage_dir
		echo "untar finish - dev-clean"
		rm -rf $storage_dir/dev-clean.tar.gz
	fi
}

function LibriSpeech_test_clean() {
	if ! test -e $librispeech_dir/test-clean; then
		echo "Download LibriSpeech/test-clean into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 http://www.openslr.org/resources/12/test-clean.tar.gz -P $storage_dir
		# <<<<< 더한 것 - tar -xzf 가 아무것도 안 찍어 멈춘 것처럼 보임
		echo "untar start  - test-clean.tar.gz (331M)"
		tar -xzf $storage_dir/test-clean.tar.gz -C $storage_dir
		echo "untar finish - test-clean"
		rm -rf $storage_dir/test-clean.tar.gz
	fi
}

function LibriSpeech_clean100() {
	if ! test -e $librispeech_dir/train-clean-100; then
		echo "Download LibriSpeech/train-clean-100 into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 http://www.openslr.org/resources/12/train-clean-100.tar.gz -P $storage_dir
		# <<<<< 더한 것 - tar -xzf 가 아무것도 안 찍어 멈춘 것처럼 보임.
		#       6GB 라 몇 분 걸림
		echo "untar start  - train-clean-100.tar.gz (5.95G)"
		tar -xzf $storage_dir/train-clean-100.tar.gz -C $storage_dir
		echo "untar finish - train-clean-100"
		rm -rf $storage_dir/train-clean-100.tar.gz
	fi
}

function LibriSpeech_clean360() {
	if ! test -e $librispeech_dir/train-clean-360; then
		echo "Download LibriSpeech/train-clean-360 into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 http://www.openslr.org/resources/12/train-clean-360.tar.gz -P $storage_dir
		# <<<<< 더한 것 - tar -xzf 가 아무것도 안 찍어 멈춘 것처럼 보임.
		#       23GB 라 오래 걸림 (아래 59-63 줄에서 이 함수 호출은 주석 처리돼 있음)
		echo "untar start  - train-clean-360.tar.gz (23G)"
		tar -xzf $storage_dir/train-clean-360.tar.gz -C $storage_dir
		echo "untar finish - train-clean-360"
		rm -rf $storage_dir/train-clean-360.tar.gz
	fi
}

function wham() {
	if ! test -e $wham_dir; then
		echo "Download wham_noise into $storage_dir"
		# If downloading stalls for more than 20s, relaunch from previous state.
		wget -c --tries=0 --read-timeout=20 https://my-bucket-a8b4b49c25c811ee9a7e8bba05fa24c7.s3.amazonaws.com/wham_noise.zip -P $storage_dir
		# <<<<< 더한 것 - unzip -q 가 아무것도 안 찍어서 17GB 푸는 동안
		#       멈춘 것처럼 보임. 시작·끝을 알리는 줄을 둠
		echo "unzip start  - wham_noise.zip (17G)"
		unzip -qn $storage_dir/wham_noise.zip -d $storage_dir
		echo "unzip finish - wham_noise"
		rm -rf $storage_dir/wham_noise.zip
	fi
}

LibriSpeech_dev_clean &
LibriSpeech_test_clean &
LibriSpeech_clean100 &
# LibriSpeech_clean360 &
wham &

wait

# Path to python
python_path=python

# # If you wish to rerun this script in the future please comment this line out.
# $python_path scripts/augment_train_noise.py --wham_dir $wham_dir

# for n_src in 2 3; do
#   metadata_dir=metadata/Libri$n_src"Mix"
#   $python_path scripts/create_librimix_from_metadata.py --librispeech_dir $librispeech_dir \
#     --wham_dir $wham_dir \
#     --metadata_dir $metadata_dir \
#     --librimix_outdir $librimix_outdir \
#     --n_src $n_src \
#     --freqs 8k 16k \
#     --modes min max \
#     --types mix_clean mix_both mix_single
# done

for n_src in 2; do	# <<<<<
  metadata_dir=metadata/Libri$n_src"Mix"
  $python_path scripts/create_librimix_from_metadata.py --librispeech_dir $librispeech_dir \
    --wham_dir $wham_dir \
    --metadata_dir $metadata_dir \
    --librimix_outdir $librimix_outdir \
    --n_src $n_src \
    --freqs 16k \
    --modes min \
    --types mix_clean
done
