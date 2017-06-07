
"""
Dykstra

"""
type Dykstra <: FOSAlgorithm
    options
end
Dykstra(;kwargs...) = Dykstra(kwargs)

immutable DykstraData{T1,T2} <: FOSSolverData
    p::Array{Float64,1}
    q::Array{Float64,1}
    y::Array{Float64,1}
    S1::T1
    S2::T2
end

function init_algorithm!(::Dykstra, model::FOSMathProgModel)
    hsde = HSDE(model)
    DykstraData(zeros(hsde.n), zeros(hsde.n), Array{Float64,1}(hsde.n),
                hsde.indAffine, hsde.indCones)
end

function Base.step(alg::Dykstra, data::DykstraData, x, i, status::AbstractStatus, longstep=nothing)
    p,q,y,S1,S2 = data.p,data.q,data.y,data.S1,data.S2

    prox!(y, S1, x .+ p)
    addprojeq(longstep, y, x .+ p)
    p .= x .+ p .- y
    prox!(x, S2, y .+ q)
    checkstatus(status, x)
    addprojineq(longstep, x, y .+ q)
    q .= y .+ q .- x
    return
end

function getsol(alg::Dykstra, data::DykstraData, x)
    y,S1,S2 = data.y,data.S1,data.S2
    tmp1 = similar(x) #Ok to allocate here, could overwrite p, q, if safe warmstart?
    prox!(tmp1, S1, x)
    prox!(y, S2, tmp1)
    return y #We reuse y here
end

support_longstep(alg::Dykstra) = true
projections_per_step(alg::Dykstra) = (1,1)
