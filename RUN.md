# Libri2Mix 생성 — 이 서버 기준

wesep 의 target speaker extraction 학습에 쓸 **Libri2Mix** 를 만드는 방법.

이 포크는 `wip/libri2mix-only` 브랜치에서 **원본의 1/12 만** 만들도록 줄여 놓았음 —
`Libri2Mix` · `16k` · `min` · `mix_clean` 뿐임.

> 이 문서는 **이 서버에서 실제로 쓴 명령어**만 담음.
> LibriMix 일반 사용법은 [README.md](README.md) 에 있음 — 그 파일은 건드리지 않았음.

---

## 명령 — 한 줄

```bash
conda activate wesep2
cd /workspace/git_clone/SD-FiLM/LibriMix
bash generate_librimix.sh /workspace/DB
```

**인자가 필수임.** [generate_librimix.sh:2-4](generate_librimix.sh#L2-L4) 가 `set -eu` 아래에서
`storage_dir=$1` 을 읽으므로, 빼면 `unbound variable` 로 바로 죽음.

### 인자가 `/workspace/DB` 인 이유

[create_librimix_from_metadata.py:48](scripts/create_librimix_from_metadata.py#L48) 이
받은 경로 아래에 `Libri2Mix` 를 **자동으로 붙임**:

```python
librimix_outdir = os.path.join(librimix_outdir, f'Libri{n_src}Mix')
```

wesep 이 기대하는 곳은
[run.sh:17](../wesep/examples/librimix/tse/v2/run.sh#L17) 의 `Libri2Mix_dir=/workspace/DB/Libri2Mix` 임.

| 준 인자 | 만들어지는 곳 | 판정 |
|---|---|---|
| `/workspace/DB` | `/workspace/DB/Libri2Mix` | ✅ |
| `/workspace/DB/Libri2Mix` | `/workspace/DB/Libri2Mix/Libri2Mix` | ❌ 어긋남 |

---

## 이 한 줄이 하는 일

| 순서 | 단계 | 내용 | 걸린 시간 |
|---|---|---|---|
| 1 | 다운로드 | `dev-clean` · `test-clean` · `train-clean-100` · `wham_noise` 를 **동시에** ([줄 77-81](generate_librimix.sh#L77-L81)) | 약 12분 |
| 2 | 압축 해제 | `tar -xzf` 3개와 `unzip -q` 1개 | 약 5분 |
| 3 | 혼합 생성 | [create_librimix_from_metadata.py](scripts/create_librimix_from_metadata.py) | 약 40초 |

시간은 2026-09-17 측정값임. 회선 속도에 따라 1번이 크게 달라짐.

**이미 받아 둔 것은 건너뜀** — 각 함수가 `if ! test -e` 로 먼저 확인함.
그래서 중간에 끊겨도 **같은 명령을 그대로 다시 치면 됨.**

### 3번이 40초밖에 안 걸리는 이유

원본은 `8k·16k` × `min·max` × `mix_clean·mix_both·mix_single·noise` 를 다 만듦.
이 포크는 [줄 103-113](generate_librimix.sh#L103-L113) 에서 **`16k` · `min` · `mix_clean` 하나**로 줄였음.
작업량이 1/12 이라 빠른 것이고, 빠르다고 뭔가 빠진 것이 아님.

---

## 만들어지는 것

```
/workspace/DB/
├── LibriSpeech/          원본 음성 (dev-clean · test-clean · train-clean-100)
├── wham_noise/           잡음 (mix_clean 만 만들어도 인자로 필요함)
└── Libri2Mix/wav16k/min/
    ├── dev/{mix_clean,s1,s2}          각 3000개 · 502M
    ├── test/{mix_clean,s1,s2}         각 3000개 · 467M
    ├── train-100/{mix_clean,s1,s2}    각 13900개 · 4.7G
    └── metadata/
```

용량은 [metadata/Libri2Mix/Storage_info.txt](metadata/Libri2Mix/Storage_info.txt) 의
원본 수치와 일치함 — 누락 없이 나왔다는 확인이 됨.

| 항목 | 크기 |
|---|---|
| `Libri2Mix` (이 설정) | 약 17 GB |
| `LibriSpeech` 원본 | 약 7 GB |
| `wham_noise` 해제분 | 약 35 GB |
| **합계 증가분** | **약 59 GB** (126 GB → 185 GB 로 측정됨) |

**`train-360` 을 켜면 자릿수가 바뀜** — [줄 80](generate_librimix.sh#L80) 의 주석을 풀면
`wav16k/min/train-360` 만 102 GB 이고 원본 전체는 472 GB 임.
[Storage_info.txt](metadata/Libri2Mix/Storage_info.txt) 에 전체 표가 있음.

---

## 다음 단계 — wesep shard 만들기

`generate_librimix.sh` 는 **원본 오디오까지만** 만듦.
wesep 학습은 shard tar 를 쓰므로 이어서:

```bash
cd /workspace/git_clone/SD-FiLM/wesep/examples/librimix/tse/v2
bash run.sh --stage 1 --stop-stage 2
```

상세는 [RUN_TABLE2.md](../wesep/examples/librimix/tse/v2/RUN_TABLE2.md) 에 있음.

---

## 이 포크가 원본과 다른 점

`master` 대비 커밋 2개임.

| 커밋 | 무엇을 |
|---|---|
| `a05e6e4` | `Libri2Mix` · `16k` · `min` · `mix_clean` 만 만들도록 줄임 ([줄 103-113](generate_librimix.sh#L103-L113)).<br>`train-clean-360` 다운로드를 주석 처리 ([줄 80](generate_librimix.sh#L80)).<br>[create_librimix_from_metadata.py:168-175](scripts/create_librimix_from_metadata.py#L168-L175) 의 noise 버그 수정 |
| `7c28513` | 압축 해제 시작·끝을 `echo` 로 알림 — 다섯 함수 전부 |

### noise 버그가 무엇이었나

원본은 `types` 가 `mix_clean` 뿐이면 `subdirs` 에서 `noise` 를 빼서
`noise/` 폴더를 만들지 않는데, [create_librimix_from_metadata.py](scripts/create_librimix_from_metadata.py)
가 그것을 무시하고 무조건 써서 `LibsndfileError` 로 죽었음.
`'noise' in subdirs` 일 때만 쓰도록 고쳤음.

### `echo` 를 더한 이유

`tar -xzf` 와 `unzip -q` 가 아무것도 안 찍어서,
17 GB `wham_noise` 를 푸는 12분 동안 **멈춘 것처럼 보였음.**
다운로드는 `wget` 이 진행 막대를 찍어 주는데 그 다음이 통째로 조용했음.

---

## 자주 걸리는 것

| 증상 | 원인과 해결 |
|---|---|
| `storage_dir: unbound variable` | **인자를 안 줬음.** `bash generate_librimix.sh /workspace/DB` |
| 다운로드 뒤 한참 소식 없음 | 압축 해제 중임. 이 포크는 `echo` 로 시작·끝을 알림 — 안 보이면 옛 판임 |
| `Libri2Mix/Libri2Mix` 가 생김 | **인자에 `Libri2Mix` 를 붙였음.** 부모 폴더를 줄 것 |
| wesep 이 데이터를 못 찾음 | [run.sh:17](../wesep/examples/librimix/tse/v2/run.sh#L17) 의 `Libri2Mix_dir` 와 실제 경로가 다름 |
| 디스크가 모자람 | `train-360` 이 켜져 있는지 확인 ([줄 80](generate_librimix.sh#L80)). 켜면 100 GB 단위로 뜀 |
