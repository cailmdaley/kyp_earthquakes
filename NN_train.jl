using KernelDensity: kde, default_bandwidth
using StatsBase, Statistics, DelimitedFiles, DataFrames, Dates, Random, Plots

function get_earthquakes(year)
    dlm = readdlm("SCEC_DC/$(year).catalog")
    data = dlm[11:end-1, :]

    times = Vector{String}()
    for i in 1:size(data)[1]
        timestring = data[i,1] * " " * data[i,2]
        if parse(Float64, timestring[end-4:end]) > 59.99
            timestring = timestring[1:end-5] * "59.99"
        end
        push!(times, timestring)
    end
    times = datetime2julian.(DateTime.(times, dateformat"y/m/d H:M:S.s"))

    lats, lons = Float64.(data[:,8]), Float64.(data[:,7])
    magnitudes = Float64.(data[:,5])

    DataFrame(time = times, lat=lats, lon=lons, mag=magnitudes)
end



function get_kdes(years, slice_width, lon_size)
    df = vcat([get_earthquakes(year) for year in years]...)

    bounds = extrema(df.lat), extrema(df.lon)
    #lat_size = Int(lon_size * diff([bounds[2]...])[1]/ diff([bounds[1]...])[1])
    lat_size = Int(lon_size * 5/8)

    nslices = round(Int, (df.time[end] - df.time[1]) / slice_width) - 1
    slice_times = range(df.time[1], df.time[end], length=nslices + 1)

    bws = Vector{Float64}()
    for i in 1:nslices
        mask = slice_times[i] .< df.time .< slice_times[i+1]
        push!(bws, mean(default_bandwidth((df.lat[mask], df.lon[mask]))))
    end
    bw = median(bws)

    kdes = Vector{Matrix{Float64}}(undef, nslices)
    for i in 1:nslices
        mask = slice_times[i] .< df.time .< slice_times[i+1]
        n_quakes = sum(mask)
        quake_kde = kde((df.lat[mask], df.lon[mask]), bandwidth=(bw, bw),
                        boundary=bounds, npoints=(lat_size,lon_size))
        kdes[i] = n_quakes .* quake_kde.density
    end
    return kdes, slice_times
end

slice_step = 1
lon_size = 32
kdes, slice_times = get_kdes(1980:2018, slice_step, lon_size)

kde_matrix = permutedims(hcat([vec(kde_slice) for kde_slice in kdes]...))

train_start = 3*365
train_end = size(kde_matrix)[1] - 3*365 - 1
nslices = Int(75/slice_step)

train_XY = [(vec(view(kde_matrix, i:i+nslices-1, :)),
             view(kde_matrix, i+nslices, :)) for i in train_start:train_end]
test_XY =  [(vec(view(kde_matrix, i:i+nslices-1, :)),
             view(kde_matrix, i+nslices, :))
            for i in [1:train_start; train_end:size(kde_matrix)[1]-nslices]]

using Flux
using Flux: throttle
m = Chain(
  Dense(length(train_XY[1][1]), 32, relu),
  Dense(32, 64, relu),
  Dense(64, 64, relu),
  Dense(64, length(train_XY[1][2])))



loss(x, y) = Flux.mse(m(x), y)
evalcb() = @show(mean([loss(x, y) for (x, y) in test_XY]))
opt = Descent(0.1)

m(train_XY[1][1])
[loss(x,y) for (x,y) in train_XY[1:5]]


using Juno
Flux.train!(loss, params(m), train_XY, opt, cb = throttle(evalcb, 20))
