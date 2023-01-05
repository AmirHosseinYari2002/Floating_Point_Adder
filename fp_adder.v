`timescale 1ns/1ns

module fp_adder(
//-----------------------Port directions and deceleration
   input [31:0] a, 
   input [31:0] b, 
   output [31:0] s
    );
//------------------------------------------------------
//----------------------------------- register and wire deceleration
wire sign_a;
wire [7:0] Exponent_a;
wire [22:0] Fraction_a;
wire sign_b;
wire [7:0] Exponent_b;
wire [22:0] Fraction_b;
wire sign_s;
wire [7:0] Exponent_s;
wire [22:0] Fraction_s;
wire [7:0] Exponent_s1;
wire [22:0] Fraction_s1;
wire [25:0] New_Fraction_a;
wire [25:0] New_Fraction_b;
wire [7:0] New_Exponent_a;
wire [7:0] New_Exponent_b;
wire [7:0] New_Exponent_c;
wire [7:0] New_Exponent_d;
wire sign_c;
wire [7:0] Exponent_c;
wire [22:0] Fraction_c;
wire [25:0] New_Fraction_c;
wire sign_d;
wire [7:0] Exponent_d;
wire [22:0] Fraction_d;
wire [25:0] New_Fraction_d;
wire [7:0] shift;
wire borrow;
wire borrow1;
wire borrow2;
wire sticky_b;
wire [27:0] Fraction_a_adder;
wire [27:0] Fraction_b_adder;
wire [27:0] Fraction_a_adder1;
wire [27:0] Fraction_b_adder1;
wire [28:0] Fraction_a_adder2;
wire [28:0] Fraction_b_adder2;
wire [29:0] add;
wire [29:0] add0;
wire [29:0] add1;
wire [7:0] first_one;
wire [27:0] inital_Fraction_s;
wire [25:0] shift_b;
wire [27:0] new_add;
wire [25:0] New_Fraction_d1;
wire [7:0] initial_Exponent_s;
wire Cout;
//-------------------------------------------------------
//-------------------------------------- combinational logic
//Step 1 (Extract Exponent and Fraction bits)
assign sign_a = a[31];
assign sign_b = b[31];
assign Exponent_a = a[30:23];
assign Exponent_b = b[30:23];
assign Fraction_a = a[22:0];
assign Fraction_b = b[22:0];
 
//Step 2 (Prepend leading 0 or 1 to form the Mantissa)
assign New_Exponent_a = (|Exponent_a) ? Exponent_a : 8'd1;
assign New_Fraction_a = (|Exponent_a) ? {1'b1 , Fraction_a , 2'b00} : {1'b0 , Fraction_a , 2'b00};
assign New_Exponent_b = (|Exponent_b) ? Exponent_b : 8'd1;
assign New_Fraction_b = (|Exponent_b) ? {1'b1 , Fraction_b , 2'b00} : {1'b0 , Fraction_b , 2'b00};

//Step 3 (Compare Exponents and swap numbers, if needed)
assign borrow1 = (Exponent_a > Exponent_b) ? 1'b0 : 1'b1;
assign borrow2 = (Exponent_a == Exponent_b) ? ((Fraction_a >= Fraction_b) ? 1'b0 : 1'b1) : 1'b0;
assign borrow = (Exponent_a == Exponent_b) ? borrow2 : borrow1;

assign Exponent_c = borrow ? Exponent_b : Exponent_a;
assign Exponent_d = borrow ? Exponent_a : Exponent_b;

assign New_Exponent_c = borrow ? New_Exponent_b : New_Exponent_a;
assign New_Exponent_d = borrow ? New_Exponent_a : New_Exponent_b;

assign sign_c = borrow ? sign_b : sign_a;
assign sign_d = borrow ? sign_a : sign_b;

assign Fraction_c = borrow ? Fraction_b : Fraction_a;
assign Fraction_d = borrow ? Fraction_a : Fraction_b;

assign New_Fraction_c = borrow ? New_Fraction_b : New_Fraction_a;
assign New_Fraction_d = borrow ? New_Fraction_a : New_Fraction_b;


assign shift = New_Exponent_c - New_Exponent_d;

//Step 4 (Shift Mantissa with smaller Exponent if necessary)
assign shift_b = (shift < 8'd27) ? (New_Fraction_d << (8'd26 - shift)) : 26'd0;
assign sticky_b = |shift_b;
assign New_Fraction_d1 = New_Fraction_d >> shift;

assign Fraction_a_adder = { New_Fraction_c , 1'b0};// 1+26+1
assign Fraction_b_adder = { New_Fraction_d1 , sticky_b};

//Step 5 (Add Mantissas)
// Sign-Magnitude to 2's complement
assign Fraction_a_adder1 = sign_c ? (~Fraction_a_adder + 1) : Fraction_a_adder;//28
assign Fraction_b_adder1 = sign_d ? (~Fraction_b_adder + 1) : Fraction_b_adder;

assign Fraction_a_adder2 = sign_c ? {2'b01, Fraction_a_adder1} : {2'b00, Fraction_a_adder1};//29
assign Fraction_b_adder2 = sign_d ? {2'b01, Fraction_b_adder1} : {2'b00, Fraction_b_adder1};
assign add = Fraction_a_adder2 + Fraction_b_adder2;//30
// 2's complement to Sign-Magnitude
assign add0 = add[28:0];//29
assign add1 = add0[28] ? ~(add0 - 1) : add;//29

assign new_add = add1[27:0];
assign sign_s = (Exponent_a==Exponent_b  && Fraction_a==Fraction_b) ? 0 : sign_c;

//Step 6 (Normalize Mantissa and adjust Exponent accordingly)
assign initial_Exponent_s = New_Exponent_c + 8'd1;
//loading one detector
assign first_one = new_add[27] ? 8'd0:
                   new_add[26] ? 8'd1:
                   new_add[25] ? 8'd2:
                   new_add[24] ? 8'd3:
                   new_add[23] ? 8'd4:
                   new_add[22] ? 8'd5:
                   new_add[21] ? 8'd6:
                   new_add[20] ? 8'd7:
                   new_add[19] ? 8'd8:
                   new_add[18] ? 8'd9:
                   new_add[17] ? 8'd10:
                   new_add[16] ? 8'd11:
                   new_add[15] ? 8'd12:
                   new_add[14] ? 8'd13:
                   new_add[13] ? 8'd14:
                   new_add[12] ? 8'd15:
                   new_add[11] ? 8'd16:
                   new_add[10] ? 8'd17:
                   new_add[9] ? 8'd18:
                   new_add[8] ? 8'd19:
                   new_add[7] ? 8'd20:
                   new_add[6] ? 8'd21:
                   new_add[5] ? 8'd22:
                   new_add[4] ? 8'd23:
                   new_add[3] ? 8'd24:
                   new_add[2] ? 8'd25:
                   new_add[1] ? 8'd26: 8'd27;

assign inital_Fraction_s = (initial_Exponent_s > first_one) ? (new_add << first_one) : (new_add << (initial_Exponent_s - 8'd1));
assign Exponent_s1 = (initial_Exponent_s > first_one  &&  first_one < 8'd27) ? (initial_Exponent_s - first_one) : 8'd0;
assign {Cout , Fraction_s1} = inital_Fraction_s[3] ? ((|inital_Fraction_s[2:0]) ? (inital_Fraction_s[26:4] + 23'd1) : (inital_Fraction_s[4] ? (inital_Fraction_s[26:4] + 23'd1) : inital_Fraction_s[26:4])) : inital_Fraction_s[26:4];
                                                                            //round up                                                      //tied                                                      //round down
assign Exponent_s = (shift <= 8'd25) ? (Cout ? (Exponent_s1 + 8'd1) : Exponent_s1) : Exponent_c;
assign Fraction_s = (shift <= 8'd25) ? (Cout ? ((|Fraction_s1) ? (Fraction_s1[22:0]) : 23'd0) : Fraction_s1) : Fraction_c;

assign s = {sign_s , Exponent_s , Fraction_s};

endmodule

