# 시스템·디지털 회로 구현 실습

Verilog로 조합·순차회로와 RISC-V CPU·cache를 구현한 학업 프로젝트입니다. 연산과 상태 제어를 작은 모듈로 구성하고, 이를 datapath로 연결하는 데 초점을 두었습니다.

## 구현

| 폴더 | 내용 |
|---|---|
| `riscv-cpu-cache/lab1-alu/` | 16-bit 연산·shift·rotate, signed overflow |
| `riscv-cpu-cache/lab2-vending-machine/` | 입력·상품 선택·잔액·timeout을 처리하는 자판기 제어 |
| `riscv-cpu-cache/lab3-single-cycle/`, `lab4-multi-cycle/` | Instruction decode, ALU, branch, 즉시값과 datapath |
| `riscv-cpu-cache/lab5-pipeline/`, `lab6-cache/` | Pipeline register, forwarding, branch prediction, cache |
| `digital-systems/` | Mux, majority, population count, 5-state FSM |
| `software-tools/` | 부록: EE485A의 삽입정렬 디버깅과 간이 셸 실습 |
| `tests/` | C 경계 입력 검사, HDL 정적 분석과 testbench |

교과 실습의 모듈 인터페이스와 기본 부품을 바탕으로 연산·제어·datapath를 구현했습니다. [구현 배경과 설계 메모](docs/provenance.md)에 과목별 구성과 주요 경계 조건을 설명했습니다.

## HDL 실행

동일한 모듈명이 반복되므로 **한 번에 한 실습 폴더만** 컴파일합니다.

```sh
python -m pip install -r requirements-dev.txt
python tests/check_hdl.py

# Icarus Verilog 시뮬레이션
mkdir -p build
iverilog -g2012 -s alu16_tb -o build/alu16 tests/alu16_tb.v riscv-cpu-cache/lab1-alu/alu.v
vvp build/alu16
iverilog -g2012 -s alu32_tb -o build/alu32 tests/alu32_tb.v riscv-cpu-cache/lab3-single-cycle/ALU.v
vvp build/alu32
iverilog -g2012 -s digital_tb -o build/digital tests/digital_tb.v digital-systems/hw3/*.v
vvp build/digital
```

Lab4 ALU의 단독 testbench에는 `-DMULTICYCLE`을 추가합니다. 전체 CPU 실행에는 `RISCV_TOP`의 instruction/data memory와 register-file 인터페이스에 맞는 모델·프로그램 입력이 필요합니다. 수업 제공 메모리 모델과 프로그램 데이터는 별도로 준비합니다.

## 테스트

| 대상 | 환경 | 결과 |
|---|---|---|
| HDL 8개 구성 | pyslang 11.0.0 | 문법·타입·모듈 연결 정적 검사 오류 0개 |
| C 삽입정렬 | Zig 0.16.0 C compiler, Windows | 정렬·중복·음수·INT 경계·잘못된 인수 등 112개 CLI 사례 통과 |
| POSIX 간이 셸 | Linux musl target | Object 컴파일 통과 |

HDL의 일부 `case` 기본분기·형 변환 경고는 검사 출력에 표시됩니다. HDL 시뮬레이션·FPGA 실행과 POSIX 셸의 프로세스 실행은 검증 전입니다.

관련 학습 내용은 [자료구조·경로탐색](docs/algorithms.md)에도 정리했습니다.

## 부록: EE485A C 실습

SW 개발환경·도구 실습의 삽입정렬과 간이 셸입니다. Linux 또는 macOS의 C11 compiler를 사용하며, `mini_shell.c`는 POSIX 환경이 필요합니다.

```sh
mkdir -p build
cc -std=c11 -Wall -Wextra -Werror software-tools/insertion_sort.c -o build/insertion_sort
./build/insertion_sort 7 -2 7 0
python tests/test_sort.py build/insertion_sort

cc -std=c11 -Wall -Wextra -Werror software-tools/mini_shell.c -o build/mini_shell
printf 'printf hello\nexit\n' | ./build/mini_shell
python tests/test_shell.py build/mini_shell
```

삽입정렬은 정수 10개까지 받으며 잘못된 정수와 범위 초과를 거부합니다. 간이 셸은 공백으로 구분한 명령을 실행하고 자식 프로세스를 기다립니다. Quoting, pipe, redirection은 지원하지 않습니다.
