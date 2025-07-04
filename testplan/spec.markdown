# 1hot_lookup_table IP 设计规范解析

## 1. 核心功能

该模块是一个可配置的查找表 (Look-Up Table, LUT)。其核心功能是根据一个 "one-hot" 的输入选择信号 (`input_i`)，从一个预设的数据表 (`lookup_table_i`) 中为多个并行的“查找项”分别选出对应的数据，最终将所有结果拼接成一个总的输出向量 (`output_o`)。

## 2. 可配置参数

-   `NUM_LOOKUPS`: 定义了同时进行多少个独立的查找任务。这对应于逻辑上数据表的行数。
-   `NUM_CHOICES`: 定义了每个查找任务有多少个可选项。这对应于逻辑上数据表的列数。
-   `RESULT_WIDTH`: 定义了查找表中每个数据单元（例如 d0, d1, d2...）的数据位宽。

## 3. 端口描述

-   **输入 `lookup_table_i`**: 一个一维向量，包含了所有可供选择的数据。在逻辑上，它被组织成一个 `NUM_LOOKUPS` x `NUM_CHOICES` 的二维矩阵。
-   **输入 `input_i`**: 一个一维向量，作为选择信号。它在逻辑上也被组织成一个 `NUM_LOOKUPS` x `NUM_CHOICES` 的二维矩阵。它的每一行都应该是 "one-hot"（只有一个bit为1）或全0。
-   **输出 `output_o`**: 一个一维向量，是所有查找任务结果的拼接。其总位宽为 `NUM_LOOKUPS * RESULT_WIDTH`。

## 4. 工作逻辑与场景

对于第 `f` 个查找项（`f` 的范围从 0 到 `NUM_LOOKUPS-1`），模块的逻辑如下：

1.  **One-Hot 选择 (正常情况)**: 模块检查 `input_i` 中对应于第 `f` 行的部分。如果这一行是 one-hot 的（例如，只有第 `g` 位为 '1'），那么模块就会从 `lookup_table_i` 中找到对应于 `(f, g)` 位置的数据，并将其作为第 `f` 个查找项的输出。

2.  **全零选择**: 如果 `input_i` 的第 `f` 行是全 0，表示不选择任何数据，那么第 `f` 个查找项的输出就是全 0。

3.  **多重选择 (不支持)**: 如果 `input_i` 的第 `f` 行有多个 '1'（不是 one-hot），这种场景是不被支持的，输出结果将是非预期的。

## 5. 图示理解 (Mermaid Diagram)

下图展示了单个查找项（以第 `f` 项为例）的数据处理流程。整个模块会并行地为所有 `NUM_LOOKUPS` 个查找项执行此流程。

```mermaid
graph TD
    subgraph "数据流: 单个查找项 (Item 'f')"
        direction LR

        A["lookup_table_i (1D)"] -- Reshape --> B["lookup_table_t (2D)"];
        B -- "Slice row 'f'" --> C["Data Choices: lookup_table_t[f]"];

        D["input_i (1D)"] -- Reshape --> E["input_i_matrix (2D)"];
        E -- "Slice row 'f'" --> F["Selector: input_i[f] (one-hot)"];
        
        subgraph "核心选择逻辑"
            C --"Data"--> G["Bitwise AND (&)"];
            F --"Selector"--> G;
            G --"所有结果"--> H["Reduction OR (|)"];
        end

        H --> I["Result for Item 'f'"];
    end

    subgraph "最终输出"
        R0["Result for Item 0"] --> Z;
        R1["..."] --> Z;
        RN["Result for Item NUM_LOOKUPS-1"] --> Z[Concatenate All Results];
        Z --> output_o["Final Output: output_o"];
    end

    I --> R1;
