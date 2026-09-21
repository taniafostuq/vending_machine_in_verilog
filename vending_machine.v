module vending_machine (
    input clock,
    input reset,
    input [1:0] select_item,     // 00 none, 01 choc, 10 juice, 11 chips
    input [7:0] payment,

  output reg [7:0] price_shown,
    output reg dispense,
    output reg error_of_insufficient,
    output reg error_out_of_stock,

  output reg [4:0] chocolate_qty,
    output reg [4:0] juice_qty,
    output reg [4:0] chips_qty,

    output reg chocolate_full, chocolate_empty,
    output reg juice_full, juice_empty,
    output reg chips_full, chips_empty
);

    parameter CHOCOLATE_PRICE  = 8'd5;
    parameter JUICE_PRICE = 8'd7;
    parameter CHIPS_PRICE = 8'd4;

    parameter IDLE      = 3'd0,SELECT = 3'd1,  SHOWPRICE = 3'd2,  VALIDATE  = 3'd3, DISPENSE= 3'd4,  
              INSUFFICIENT= 3'd5,Out_Of_Stock = 3'd6;
  
    reg [2:0] state, next_state;
    reg [1:0] chosen_item;
    reg [7:0] chosen_price;

  reg [4:0] memo [2:0];//memo[0]=chocolate // memo[1]=juice //  memo[2]=chips


    // State Register
  
  always @(posedge clock or posedge reset) begin
    if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Inventory Register (RAM init + decrement)

  always @(posedge clock or posedge reset) begin
    if (reset) begin
            memo[0]  <= 5'd20;
            memo[1] <= 5'd20;
            memo[2] <= 5'd20;
        end
        else if (state == DISPENSE) begin
            case (chosen_item)
              2'b01: if (memo[0]  > 0) memo[0]  <= memo[0]  - 1;
                2'b10: if (memo[1] > 0) memo[1] <= memo[1] - 1;
                2'b11: if (memo[2] > 0) memo[2] <= memo[2] - 1;
            endcase
        end
    end


    // Capture selected item at start of transaction

  always @(posedge clock or posedge reset) begin
    if (reset)
        chosen_item <= 2'b00;
    else if (state == SELECT)
        chosen_item <= select_item;
end


  
    // Price Selector
    always @(*) begin
        case (chosen_item)
            2'b01: chosen_price = CHOCOLATE_PRICE;
            2'b10: chosen_price = JUICE_PRICE;
            2'b11: chosen_price = CHIPS_PRICE;
            default: chosen_price = 8'd0;
        endcase
    end

    // FSM Next State

  always @(*) begin
        next_state = state;

        case (state)

            IDLE: begin
                if (select_item != 2'b00)
                    next_state = SELECT;
                else
                    next_state = IDLE;
            end

            SELECT:  next_state = SHOWPRICE;
            SHOWPRICE: next_state = VALIDATE;

            VALIDATE: begin
                // out of stock
              if ((chosen_item == 2'b01 && memo[0]  == 0) ||
                    (chosen_item == 2'b10 && memo[1] == 0) ||
                    (chosen_item == 2'b11 && memo[2] == 0))
                    next_state = Out_Of_Stock;

                // insufficient
                else if (payment < chosen_price)
                    next_state = INSUFFICIENT;

                // ok dispense
                else
                    next_state = DISPENSE;
            end

            DISPENSE:    next_state = IDLE;
            INSUFFICIENT:next_state = IDLE;
            Out_Of_Stock:next_state = IDLE;

        endcase
    end

  
    // Outputs + Flags (and latch errors)

  always @(posedge clock or posedge reset) begin
    if (reset) begin
            dispense <= 0;
            error_of_insufficient <= 0;
            error_out_of_stock <= 0;
        end
        else begin
         
            if (state == IDLE && select_item != 2'b00) begin
                dispense <= 0;
                error_of_insufficient <= 0;
                error_out_of_stock <= 0;
            end

            // Latch dispense
            if (state == DISPENSE)
                dispense <= 1;

            // Latch errors
          if (state == INSUFFICIENT)
                error_of_insufficient <= 1;

          if (state == Out_Of_Stock)
                error_out_of_stock <= 1;
        end
    end

  
    // Combinational outputs
  always @(*) begin
        price_shown = 0;

        // output price
        if (state == SHOWPRICE)
            price_shown = chosen_price;

        // send quantities out
        chocolate_qty  = memo[0];
        juice_qty = memo[1];
        chips_qty = memo[2];

        // flags
      chocolate_full  = (memo[0]  == 20);
      chocolate_empty = (memo[0]  == 0);

       juice_full  = (memo[1] == 20);
        juice_empty = (memo[1] == 0);

        chips_full  = (memo[2] == 20);
        chips_empty = (memo[2] == 0);
    end

endmodule

////////////////////////////////////////////////////////////////////////

module testbench;

    reg clock, reset;
    reg [1:0] select_item;
    reg [7:0] payment;

  wire [7:0] price_shown;
    wire dispense, error_of_insufficient, error_out_of_stock;
  wire [4:0] chocolate_qty, juice_qty, chips_qty;
    wire chocolate_full, chocolate_empty, juice_full, juice_empty, chips_full, chips_empty;

  vending_machine m1(  clock, reset, select_item, payment, price_shown, dispense,error_of_insufficient, error_out_of_stock,
  chocolate_qty, juice_qty, chips_qty,chocolate_full, chocolate_empty, juice_full, juice_empty,  chips_full, chips_empty);


    always #5 clock = ~clock;

    

    initial begin
        clock = 0;
        reset = 1;
        select_item = 0;
        payment = 0;

        #20 reset = 0;
      repeat(2) @(posedge clock);
       $display("---------------------------------------------");

        // TEST 1
        $display("TEST 1: Initial Inventory (All Full)");
      
        $display("Chocolate: qty=%0d full=%0d empty=%0d", chocolate_qty, chocolate_full, chocolate_empty);
        $display("Juice:     qty=%0d full=%0d empty=%0d", juice_qty, juice_full, juice_empty);
        $display("Chips:     qty=%0d full=%0d empty=%0d", chips_qty, chips_full, chips_empty);
        $display("dispense=%0d insufficient=%0d out_of_stock=%0d",
                  dispense, error_of_insufficient, error_out_of_stock);
        $display("---------------------------------------------");

    
        // TEST 2: purchase each item
        $display("TEST 2: Buy Chocolate pay=5");
      
      select_item = 2'b01;
        payment = 8'd5;
      repeat(6) @(posedge clock);

        select_item = 2'b00;
        payment = 0;
      repeat(2) @(posedge clock);
      
        $display("Chocolate: qty=%0d full=%0d empty=%0d", chocolate_qty, chocolate_full, chocolate_empty);
        $display("Juice:     qty=%0d full=%0d empty=%0d", juice_qty, juice_full, juice_empty);
        $display("Chips:     qty=%0d full=%0d empty=%0d", chips_qty, chips_full, chips_empty);
        $display("dispense=%0d insufficient=%0d out_of_stock=%0d",
                  dispense, error_of_insufficient, error_out_of_stock);
      
      
        $display("---------------------------------------------");
    

        $display("TEST 2: Buy Juice pay=7");
      
      select_item = 2'b10;
        payment = 8'd7;
      repeat(6) @(posedge clock);

        select_item = 2'b00;
        payment = 0;
      repeat(2) @(posedge clock);
      
        $display("Chocolate: qty=%0d full=%0d empty=%0d", chocolate_qty, chocolate_full, chocolate_empty);
        $display("Juice:     qty=%0d full=%0d empty=%0d", juice_qty, juice_full, juice_empty);
        $display("Chips:     qty=%0d full=%0d empty=%0d", chips_qty, chips_full, chips_empty);
        $display("dispense=%0d insufficient=%0d out_of_stock=%0d",
                  dispense, error_of_insufficient, error_out_of_stock);
      
      
      
        $display("---------------------------------------------");
      
      
    
        $display("TEST 2: Buy Chips pay=4");
      
      select_item = 2'b11;
        payment = 8'd4;
      repeat(6) @(posedge clock);

        select_item = 2'b00;
        payment = 0;
      repeat(2) @(posedge clock);
      
        $display("Chocolate: qty=%0d full=%0d empty=%0d", chocolate_qty, chocolate_full, chocolate_empty);
        $display("Juice:     qty=%0d full=%0d empty=%0d", juice_qty, juice_full, juice_empty);
        $display("Chips:     qty=%0d full=%0d empty=%0d", chips_qty, chips_full, chips_empty);
        $display("dispense=%0d insufficient=%0d out_of_stock=%0d",
                  dispense, error_of_insufficient, error_out_of_stock);
      
      
      
        $display("---------------------------------------------");
    
      
      

        // TEST 3: insufficient
        $display("TEST 3: Insufficient (Juice pay=3)");
      
        select_item = 2'b10;
        payment = 8'd3;
        repeat(6) @(posedge clock);

        select_item = 2'b00;
        payment = 0;
        repeat(2) @(posedge clock);
      
        $display("Chocolate: qty=%0d full=%0d empty=%0d", chocolate_qty, chocolate_full, chocolate_empty);
        $display("Juice:     qty=%0d full=%0d empty=%0d", juice_qty, juice_full, juice_empty);
        $display("Chips:     qty=%0d full=%0d empty=%0d", chips_qty, chips_full, chips_empty);
        $display("dispense=%0d insufficient=%0d out_of_stock=%0d",
                  dispense, error_of_insufficient, error_out_of_stock);
      
      
      
        $display("---------------------------------------------");
      
      
    

        // TEST 4: out of stock
        $display("TEST 4: Out of Stock (chips qty=0 then buy)");
        m1.memo[2] = 0;
        select_item = 2'b11;
        payment = 8'd10;
        repeat(6) @(posedge clock);

        select_item = 2'b00;
        payment = 0;
        repeat(2) @(posedge clock);
      
        $display("Chocolate: qty=%0d full=%0d empty=%0d", chocolate_qty, chocolate_full, chocolate_empty);
        $display("Juice:     qty=%0d full=%0d empty=%0d", juice_qty, juice_full, juice_empty);
        $display("Chips:     qty=%0d full=%0d empty=%0d", chips_qty, chips_full, chips_empty);
        $display("dispense=%0d insufficient=%0d out_of_stock=%0d",
                  dispense, error_of_insufficient, error_out_of_stock);
      
      
      
        $display("---------------------------------------------");
    

      
        $finish;
    end

endmodule