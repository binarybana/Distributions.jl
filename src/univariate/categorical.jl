immutable Categorical <: DiscreteUnivariateDistribution
    K::Int
    prob::Vector{Float64}

    function Categorical(p::Vector{Float64})
        if !isprobvec(p)
            throw(ArgumentError("p = $p is not a probability vector."))
        end
        new(length(p), p)
    end
end

immutable CategoricalSampler <: DiscreteUnivariateDistribution
    d::Categorical
    alias::AliasTable
    function CategoricalSampler(d::Categorical)
        new(d, AliasTable(d.prob))
    end
end

sampler(d::Categorical) = CategoricalSampler(d)

Categorical(d::Integer) = Categorical(ones(d))

min(d::Categorical) = 1
max(d::Categorical) = d.K

function cdf(d::Categorical, x::Real)
    x < one(x) && return 0.0
    d.K <= x && return 1.0
    p = d.prob[1]
    for i in 2:ifloor(x)
        p += d.prob[i]
    end
    p
end

entropy(d::Categorical) = NumericExtensions.entropy(d.prob)

function insupport(d::Categorical, x::Real)
    isinteger(x) && one(x) <= x <= d.K && d.prob[x] != 0.0
end

function kurtosis(d::Categorical)
    m = mean(d)
    s = 0.0
    for i in 1:d.K
        s += (i - m)^4 * d.prob[i]
    end
    s / var(d)^2 - 3.0
end

mean(d::Categorical) = sum(Multiply(), [1:d.K], d.prob)

function median(d::Categorical)
    p = 0.
    n = d.K
    i = 0
    while p < 0.5 && i <= n
        i += 1
        p += d.prob[i]
    end
    i
end

function mgf(d::Categorical, t::AbstractVector)
    s = 0.0
    for i in 1:d.K
        s += d.prob[i] * exp(t[i])
    end
    s
end

function cf(d::Categorical, t::AbstractVector)
    s = 0.0 + 0.0im
    for i in 1:d.K
        s += d.prob[i] * exp(im * t[i])
    end
    s
end

mode(d::Categorical) = indmax(d.prob)

function modes(d::Categorical)
    K = d.K
    p = d.prob
    maxp = max(p)
    r = Array(Int, 0)
    for k = 1:K
        if p[k] == maxp
            push!(r, k)
        end
    end
    r
end


pdf(d::Categorical, x::Real) = isinteger(x) && one(x) <= x <= d.K ? d.prob[x] : 0.0

function quantile(d::Categorical, p::Real)
    zero(p) <= p <= one(p) || throw(DomainError())
    k = d.K
    pv = d.prob
    i = 1
    v = pv[1]
    while v < p && i < k
        i += 1
        v += pv[i]
    end
    i
end

function rand(d::Categorical)
    u = rand()
    sump = 0.0 
    for i in 1:d.K
        sump += d.prob[i]
        if u <= sump
            return i
        end
    end
    d.K
end

rand(s::CategoricalSampler) = rand(s.alias)

function skewness(d::Categorical)
    m = mean(d)
    s = 0.0
    for i in 1:d.K
        s += (i - m)^3 * d.prob[i]
    end
    s / std(d)^3
end

function var(d::Categorical)
    m = mean(d)
    s = 0.0
    for i in 1:d.K
        s += (i - m)^2 * d.prob[i]
    end
    s
end

function fit_mle{T<:Real}(::Type{Categorical}, k::Integer, x::Array{T})
    w = zeros(Int, k)
    n = length(x)
    for i in 1:n
         w[x[i]] += 1
    end

    p = Array(Float64, k)
    c = 1.0 / n
    for i = 1:k
        p[i] = w[i] * c
    end

    Categorical(w)
end

fit_mle{T<:Real}(::Type{Categorical}, x::Array{T}) = fit_mle(Categorical, max(x), x)
