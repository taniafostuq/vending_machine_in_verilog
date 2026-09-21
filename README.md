# vending_machine_in_verilog


This repository contains the Verilog implementation and automated testbench for a 7-state Finite State Machine (FSM) vending machine controller with inventory management and error tracking[cite: 13, 14].

---

## 🏗️ State Machine Architecture

The controller processes transactions through a 3-bit 7-state FSM[cite: 13, 14]:

| State Code | State Name | Next State Logic / Condition | Output / Action |
| :---: | :--- | :--- | :--- |
| `3'b000` | **IDLE**[cite: 13, 14] | Transitions to `SELECT` if `select_item != 2'b00`[cite: 13, 14]. | Resets internal status flags[cite: 14]. |
| `3'b001` | **SELECT**[cite: 13, 14] | Unconditionally transitions to `SHOWPRICE`[cite: 13, 14]. | Latches `chosen_item` selection[cite: 14]. |
| `3'b010` | **SHOWPRICE**[cite: 13, 14] | Unconditionally transitions to `VALIDATE`[cite: 13, 14]. | Outputs product price on `price_shown`[cite: 14]. |
| `3'b011` | **VALIDATE**[cite: 13, 14] | • `stock == 0` $\rightarrow$ `Out_Of_Stock`[cite: 13, 14]<br>• `payment < price` $\rightarrow$ `INSUFFICIENT`[cite: 13, 14]<br>• `payment >= price` and `stock > 0` $\rightarrow$ `DISPENSE`[cite: 13, 14] | Evaluates payment vs price and inventory level[cite: 13, 14]. |
| `3'b100` | **DISPENSE**[cite: 13, 14] | Transitions back to `IDLE`[cite: 14]. | Asserts `dispense = 1` and decrements product inventory[cite: 13, 14]. |
| `3'b101` | **INSUFFICIENT**[cite: 13, 14] | Transitions back to `IDLE`[cite: 14]. | Asserts `error_of_insufficient = 1`[cite: 13, 14]. |
| `3'b110` | **Out_Of_Stock**[cite: 13, 14] | Transitions back to `IDLE`[cite: 14]. | Asserts `error_out_of_stock = 1`[cite: 13, 14]. |

---

## 🛒 Products & Pricing

The vending machine manages three items with an initial capacity of 20 units per item stored in an internal register array (`memo`)[cite: 14]:

| Item Code (`select_item`) | Item Name | Unit Price (`8-bit`) | Capacity |
| :---: | :--- | :---: | :---: |
| `2'b00` | **None**[cite: 14] | `8'd0`[cite: 14] | — |
| `2'b01` | **Chocolate**[cite: 14] | `8'd5`[cite: 14] | 20[cite: 14] |
| `2 me10` | **Juice**[cite: 14] | `8'd7`[cite: 14] | 20[cite: 14] |
| `2'b11` | **Chips**[cite: 14] | `8'd4`[cite: 14] | 20[cite: 14] |

---

## 🔌 Signal Specifications

### Inputs
* `clock`: System clock signal[cite: 14].
* `reset`: Active-high system reset[cite: 14].
* `select_item [1:0]`: 2-bit item selection bus[cite: 14].
* `payment [7:0]`: 8-bit payment input amount[cite: 14].

### Outputs
* `price_shown [7:0]`: Display price during `SHOWPRICE` state[cite: 14].
* `dispense`: Pulse set high during item release[cite: 14].
* `error_of_insufficient`: Flag asserted when inserted payment is less than item price[cite: 14].
* `error_out_of_stock`: Flag asserted when chosen item stock is zero[cite: 14].
* `chocolate_qty [4:0]`, `juice_qty [4:0]`, `chips_qty [4:0]`: Current stock counts[cite: 14].
* `chocolate_full`, `juice_full`, `chips_full`: Status indicators when stock $= 20$[cite: 14].
* `chocolate_empty`, `juice_empty`, `chips_empty`: Status indicators when stock $= 0$[cite: 14].

---

## 🧪 Testbench Verification

The included testbench (`testbench`) executes four test cases[cite: 14]:

1. **Initial Inventory Audit:** Validates default initialization (20 units per item, `full` flags set high)[cite: 14].
2. **Standard Purchase Operations:**
   * Purchases Chocolate (`select_item = 2'b01`, `payment = 5`)[cite: 14].
   * Purchases Juice (`select_item = 2'b10`, `payment = 7`)[cite: 14].
   * Purchases Chips (`select_item = 2'b11`, `payment = 4`)[cite: 14].
3. **Insufficient Payment Error:** Selects Juice (`price = 7`) with `payment = 3`, asserting `error_of_insufficient`[cite: 14].
4. **Out of Stock Error:** Forces Chips stock to 0 (`memo[2] = 0`), attempts purchase with `payment = 10`, asserting `error_out_of_stock`[cite: 14].
