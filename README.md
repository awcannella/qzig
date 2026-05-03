# qzig is a quantum circuit simulation library built using the Zig programming language

## Goals: 
  1. Implement basic quantum gate operations (Z, X, Hadamard, CNOT, SWAP)
  2. Support the application of these operations on multiple qubits
  3. Cleanly organize several layers of abstraction to separate the user interface programs (Circuit.zig) from the execution layers (executor.zig)
  4. Continuously optimize this project to explore the limits of classical simulation on quantum circuit behavior

## Results from run_all.zig

### Only Hadamard gates
| q | state |  ns/op  | total ns  |
|---|-------|---------|-----------|
| 6 | 64    | 398     | 199000    |
| 10| 1024  | 13364   | 6682000   |
| 14| 16384 | 252346  | 126173000 |

### Hadamard + Z + CNOT (added every two H and Z gates)
| q | state |  ns/op  | total ns  |
|---|-------|---------|-----------|
| 6 | 64    | 864     | 432000    |
| 10| 1024  | 21902   | 10951000  |
| 14| 16384 | 423558  | 211779000 |

### Only CNOT gates
| q | state |  ns/op  | total ns |
|---|-------|---------|----------|
| 6 | 64    | 70      | 35000    |
| 10| 1024  | 1720    | 860000   |
| 14| 16384 | 32984   | 16492000 |
