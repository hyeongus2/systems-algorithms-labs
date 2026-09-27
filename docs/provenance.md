# 구현 배경과 설계 메모

## 교과 구성

| 경로 | 배경 |
|---|---|
| `riscv-cpu-cache/` | 2021년 가을 컴퓨터구조 EE312, Lab 1–6 |
| `digital-systems/hw3/`, `hw5/` | 2020년 봄 디지털시스템 EE303 |
| `software-tools/` | 2021년 가을 최신 SW 개발환경·도구 EE485A, 삽입정렬 디버깅과 간이 셸 |
| `tests/` | C 경계 입력, HDL 정적 분석과 단위 testbench |

컴퓨터구조·디지털시스템 구현은 수업 skeleton의 모듈 인터페이스와 일부 기본 부품을 사용합니다. 제공 memory/register/clock 모델, 공식 testbench와 프로그램 입력은 저장소에 포함하지 않습니다. 자판기 상수 헤더는 모듈의 차원과 대기시간을 정의합니다. 수업 제공 부분의 권리는 해당 저작자에게 있습니다.

## 경계 조건과 제어

- **ALU16:** 최솟값 뺄셈을 포함한 signed overflow 판정
- **RISC-V ALU:** 산술 우측 shift의 signed 변환, 5-bit shift amount, selector 기본 결과
- **Instruction control:** Reset·미지원 opcode의 제어신호 기본값, SRAI instruction bit decode
- **MUX·FSM:** 조합논리 기본값과 불법 상태 처리, 조합 블록의 blocking assignment
- **자판기:** Next-state 기본값, 출력 단일 구동, 카운터 underflow와 잔액 없는 반복 반환 방지
- **삽입정렬:** 입력 10개 제한, `strtol` 변환 오류와 정수 범위 검사
- **간이 셸:** EOF 종료, 줄 길이·인수 개수 경계, 마지막 개행 없는 명령, `fork`/`execvp`/`waitpid` 오류 처리

실행 방법과 테스트 결과는 [README](../README.md)를 참고하세요.
