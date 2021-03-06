using FirstOrderSolvers: HSDEMatrixQ, HSDEMatrix
using ProximalOperators: IndAffine, prox!

function getQ1Q2(A)
    m, n = size(A)
    b = randn(m)
    c = randn(n)

    Q1 = [zeros(n,n) A'         c;
        -A         zeros(m,m) b;
        -c'        -b'        0]

    Q2 = HSDEMatrixQ(A, b, c)
    return Q1, Q2
end

function getHSDEMatrix(Q1,Q2)
    M1 = [speye(size(Q1)...) Q1'                ;
          Q1                 -speye(size(Q1)...)]
    M2 = HSDEMatrix(Q2)
    return M1, M2
end

function testHSDEQ_A_mul_B(Q1, Q2, m, n)
    rhs1 = randn(m+n+1)
    rhs2 = copy(rhs1)

    y1, y2 = randn(m+n+1), randn(m+n+1)

    A_mul_B!(y1, Q1, rhs1)
    A_mul_B!(y2, Q2, rhs2)

    @test rhs1 == rhs2
    @test y1 ≈ y2

    At_mul_B!(y1, Q1, rhs1)
    At_mul_B!(y2, Q2, rhs2)

    @test rhs1 == rhs2
    @test y1 ≈ y2
end

function testHSDEMatrix_A_mul_B(M1, M2, m, n)
    rhs1 = randn(2m+2n+2)
    rhs2 = copy(rhs1)

    y1, y2 = randn(2m+2n+2), randn(2m+2n+2)

    A_mul_B!(y1, M1, rhs1)
    A_mul_B!(y2, M2, rhs2)

    @test rhs1 == rhs2
    @test y1 ≈ y2

    At_mul_B!(y1, M1, rhs1)
    At_mul_B!(y2, M2, rhs2)

    @test rhs1 == rhs2
    @test y1 ≈ y2
end

function testHSDE(A, m, n)
    Q1, Q2 = getQ1Q2(A)
    testHSDEQ_A_mul_B(Q1, Q2, m, n)

    M1, M2 = getHSDEMatrix(Q1, Q2)
    testHSDEMatrix_A_mul_B(M1, M2, m, n)

    b = randn(size(M2)[1])
    S1 = IndAffine([Q1 -speye(size(Q1,1))], zeros(size(Q1,1)))
    y1 = similar(b)
    y2 = similar(b)
    FirstOrderSolvers.prox!(y2, M2, b)
    prox!(y1, S1, b)

    y3 = M1\b
    y3[(size(Q1,1)+1):end] .= Q1*y3[1:size(Q1,1)]
    @test y1 ≈ y2
    @test y2 ≈ y3
end

srand(1)
ma,na = 10,20
A = randn(10*ma,10*na)
testHSDE(A, size(A)...)

A = sprandn(100*ma,100*na,0.001)
testHSDE(A, size(A)...)
