# 출처와 유지관리

| 공개 코드 | 원본 |
|---|---|
| `riscv-cpu-cache/` | 2021 가을 컴퓨터구조 EE312, Lab1~6의 심현성 개인 제출 Verilog |
| `digital-systems/hw3/`, `hw5/` | 2020 봄 디지털시스템 EE303, 개인 제출 ZIP의 P*.v |
| `software-tools/` | 2021 가을 최신 SW 개발환경·도구 EE485A, Assignment5 삽입정렬 디버깅 및 Assignment11 간이 셸 |
| `tests/` | 2026 공개판 정리 중 작성한 테스트·검증 도구 |

컴퓨터구조·디지털시스템 파일은 수업 skeleton의 모듈 선언·일부 기본 부품과 본인 구현이 함께 있는 학습용 코드입니다. 제공본과 개인 제출본을 대조해 구현 파일을 선별했으며, 동일한 배포 memory/register/clock 모델과 공식 testbench·solution·입력 데이터는 제외했습니다. 자판기 상수 헤더는 기존 모듈의 차원·대기시간을 맞추는 호환 설정입니다. 다른 저작자의 제공 부분에 새 일괄 라이선스를 부여하지 않습니다.

## 2026 유지관리 변경

- ALU16: 최솟값을 빼는 경우에도 signed overflow를 올바르게 판단하도록 보완.
- RISC-V ALU: 산술 우측 shift의 signed 변환과 5-bit shift amount, selector 기본 결과 보완.
- instruction control: reset·지원하지 않는 opcode에서 위험한 제어신호가 이전 값에 남지 않도록 기본값을 지정하고 SRAI의 instruction bit를 decode.
- MUX·FSM: 조합논리 기본값과 불법 상태 처리를 명시. 조합 블록은 blocking assignment 사용.
- 자판기: 조합 next-state 기본값, 출력의 중복 구동 제거, 카운터 underflow 방지, 잔액이 없는 반복 return 신호 방지.
- 삽입정렬: 10개 입력 경계와 `strtol` 변환 오류·정수 범위 검사.
- 간이 셸: EOF 종료, 줄 길이·인수 개수 경계, 마지막 개행 없는 명령, `fork`/`execvp`/`waitpid` 오류 처리.

이 버전은 당시 제출본을 보관한 원본과 별도로 관리하는 정리본입니다. 수정 후 정적 검사·C 테스트와 아직 수행하지 않은 검증을 README에 구분했습니다.
