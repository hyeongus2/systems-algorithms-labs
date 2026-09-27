# 시스템·디지털 회로 구현 실습

C의 프로세스 실행부터 Verilog CPU·cache까지, 학업에서 직접 구현·수정한 코드를 모았습니다. 컴퓨터구조의 ALU·자판기·single-cycle·multi-cycle·pipeline·cache, 디지털 회로의 조합논리·FSM, 소프트웨어 개발도구 실습의 디버깅·간이 셸을 포함합니다.

## 구성과 본인 역할

| 폴더 | 목적과 구현 | 기반·결과 |
|---|---|---|
| `riscv-cpu-cache/lab1-alu/` | 16-bit 연산·shift·rotate와 signed overflow | EE312 2021 개인 제출 구현 |
| `riscv-cpu-cache/lab2-vending-machine/` | 입력·상품 선택·잔액·timeout을 상태로 처리 | 수업 인터페이스에 작성한 개인 조합·순차논리 |
| `riscv-cpu-cache/lab3-single-cycle/`, `lab4-multi-cycle/` | instruction decode, ALU, branch, 즉시값과 datapath 연결 | single/multi-cycle CPU 구현 |
| `riscv-cpu-cache/lab5-pipeline/`, `lab6-cache/` | pipeline register·forwarding·branch prediction·cache | CPU 단계별 확장과 실험 코드 |
| `digital-systems/` | mux, majority, population count, 5-state FSM | EE303 2020 개인 제출 HDL |
| `software-tools/` | 삽입정렬 예제 디버깅, `fork`/`execvp` 기반 간이 셸 | EE485A 2021 SW 개발환경·도구 실습 |
| `tests/` | 입력 경계, HDL 정적 분석, 자작 합성 입력 testbench | 공개판의 실행·검증 보조 코드 |

본인은 수업에서 제공한 모듈 인터페이스에 연산·제어·datapath를 구현하고 제출했습니다. 이후 공개판을 정리하면서 입력 경계, ALU 연산과 제어 기본값 등 확인한 오류를 수정했습니다. 제공 skeleton의 인터페이스가 포함된 파일은 수업 기반 구현이며, 모든 코드를 처음부터 독자 설계했다는 뜻은 아닙니다. 배포 testbench·메모리 모델·과제지·해답·시험 입력은 포함하지 않았습니다. [출처와 수정 내용](docs/provenance.md)을 함께 확인할 수 있습니다.

## C 실행

Linux 또는 macOS의 C11 compiler를 기준으로 합니다. `mini_shell.c`는 POSIX 환경이 필요합니다.

```sh
mkdir -p build
cc -std=c11 -Wall -Wextra -Werror software-tools/insertion_sort.c -o build/insertion_sort
./build/insertion_sort 7 -2 7 0
python tests/test_sort.py build/insertion_sort

cc -std=c11 -Wall -Wextra -Werror software-tools/mini_shell.c -o build/mini_shell
printf 'printf hello\nexit\n' | ./build/mini_shell
python tests/test_shell.py build/mini_shell
```

삽입정렬은 정수 10개까지 받으며 잘못된 정수·범위 초과를 거부합니다. 간이 셸은 공백으로 구분한 명령을 실행하고 자식 프로세스를 기다립니다. quoting, pipe, redirection은 이 작은 SW도구 과제의 기능 범위에 포함되지 않습니다. 별도 EE209 Unix shell 프로젝트의 공개 소스가 아닙니다.

## HDL 실행과 검증

동일한 모듈명이 실습별로 반복되므로 **한 번에 한 실습 폴더만** 컴파일합니다.

```sh
python -m pip install -r requirements-dev.txt
python tests/check_hdl.py

# Icarus Verilog를 설치한 경우 자작 입력으로 시뮬레이션
iverilog -g2012 -s alu16_tb -o build/alu16 tests/alu16_tb.v riscv-cpu-cache/lab1-alu/alu.v
vvp build/alu16
iverilog -g2012 -s alu32_tb -o build/alu32 tests/alu32_tb.v riscv-cpu-cache/lab3-single-cycle/ALU.v
vvp build/alu32
iverilog -g2012 -s digital_tb -o build/digital tests/digital_tb.v digital-systems/hw3/*.v
vvp build/digital
```

Lab4 ALU의 단독 testbench에는 `-DMULTICYCLE`을 추가합니다. 전체 CPU는 `RISCV_TOP`의 instruction/data memory 및 register-file 인터페이스에 사용자가 준비한 환경을 연결합니다. 원 과제의 제공 메모리 모델·프로그램 데이터는 별도로 필요하며 이 저장소에서 재배포하지 않습니다.

## 현재 확인한 결과

- 2026-09-28 공개판: pyslang 11.0.0으로 8개 HDL 구성의 문법·타입·모듈 연결 정적 검사에서 오류 0개. 일부 `case` 기본분기·형 변환 경고는 남아 있으며 검사 출력에서 확인할 수 있습니다.
- C 삽입정렬: Zig 0.16.0의 C compiler로 Windows native 빌드 후 정렬·중복·음수·INT 경계·잘못된 인수 등 **112개 CLI 사례 통과**.
- POSIX 간이 셸: Linux musl target object 컴파일 통과. Linux/macOS에서의 실제 프로세스 실행 검증은 아직 수행하지 않았습니다.
- HDL testbench는 새로 작성했으며, 이 공개판의 시뮬레이션·FPGA 실기기 실행 및 기존 과제 전체 프로그램 재현은 아직 수행하지 않았습니다. 정적 검사 통과를 CPU 동작·성능 검증으로 해석하지 않습니다.

[자료구조·경로탐색의 별도 수행 경험](docs/algorithms.md)도 요약했습니다. 해당 과목 원 제출 소스는 이 공개 저장소에 포함하지 않습니다.
