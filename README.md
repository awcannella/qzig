# qzig is a quantum circuit simulation library built using the Zig programming language

## Goals: 
  1. Implement basic quantum gate operations (Z, X, Hadamard, CNOT, SWAP)
  2. Support the application of these operations on multiple qubits
  3. Cleanly organize several layers of abstraction to separate the user interface programs (Circuit.zig) from the execution layers (executor.zig)
  4. Continuously optimize this project to explore the limits of classical simulation on quantum circuit behavior

## Results from run_all.zig

### Only Hadamard gates
| q | state | ns/op | GB/s |
|---|-------|-------|------|
| 6 | 64    | 320   | 38.4 |
| 10| 1024  | 5316  | 61.6 |
| 14| 16384 | 135176| 54.3 |

### Hadamard + Z + CNOT (added every two H and Z gates)
| q | state | ns/op | GB/s |
|---|-------|-------|------|
| 6 | 64    | 1654  | 13.6 |
| 10| 1024  | 30900 | 18.0 |
| 14| 16384 | 585664| 20.6 |

### Only CNOT gates
| q | state |  ns/op  | GB/s |
|---|-------|---------|------|
| 6 | 64    | 1338    | 1.53 |
| 10| 1024  | 128070  | 0.26 |
| 14| 16384 | 3869704 | 0.14 |
