package datatypesPkg;

    typedef enum bit [1:0] {nA = 2'b00, nC = 2'b01, nG = 2'b10, nT = 2'b11} dna_base;
    typedef enum bit [1:0] {Above = 2'b01, Left = 2'b10, Diagonal = 2'b11, Nil = 2'b00} direction;

    typedef enum bit [4:0] {
        A = 5'd0,
        B = 5'd1,
        C = 5'd2,
        D = 5'd3,
        E = 5'd4,
        F = 5'd5,
        G = 5'd6,
        H = 5'd7,
        I = 5'd8,
        J = 5'd9,
        K = 5'd10,
        L = 5'd11,
        M = 5'd12,
        N = 5'd13,
        O = 5'd14,
        P = 5'd15,
        Q = 5'd16,
        R = 5'd17,
        S = 5'd18,
        T = 5'd19,
        U = 5'd20,
        V = 5'd21,
        W = 5'd22,
        X = 5'd23,
        Y = 5'd24,
        Z = 5'd25
    } protein_base;

endpackage
