# points(quake_df::DataFrame) = Shapefile.Point.(quake_df.lat, quake_df.lon)
#
# function mbr(quake_df::DataFrame)
#     left, right = extrema(df.lat); bottom, top = extrema(df.lon)
#     Shapefile.Rect(left, bottom, right, top)
# end
#
# function plotquakes(quake_df::DataFrame, canvas)
#     plotshape(points(quake_df), canvas, line_color="red",
#                        radius=[0.05cm], line_width=0.25mm)
# end
#
# function plotfaults(faultshapes, canvas)
#         plotshape(faultshapes, canvas, line_color="white",
#                   radius=[0.05cm], line_width=0.25mm)
# end
# cali = open_shapefile("s7059k.shp")
# cali_canvas = plotshape(cali)
#
# faults = open_shapefile("Qfaults_2018_shapefile/Qfaults_2018_shapefile.shp")
# fault_inds = Int.(readdlm("san_andreas_faults_historic_eq_USGS.csv", ',')[500:end,1])
# plotfaults(faults.shapes[fault_inds], canvas)
# canvas = plotshape(df.loc, mbr,


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

slice_step = 5
lon_size = 64
kdes, slice_times = get_kdes(1980:2018, slice_step, lon_size)
kde_sum = sum(kdes)
heatmap(kde_sum)

kde_matrix = permutedims(hcat([vec(kde_slice) for kde_slice in kdes]...))
lags = 0:1:20
plot(autocov(kde_matrix, lags), color="black", α=0.3, legend=false,
     xlabel="Days", ylabel="Autocovariance", xticks=(lags[1:2:end],
     lags[1:2:end]*slice_step))

savefig("/Users/cdaley/Documents/LSDSS2019/kyp_earthquakes/autocov.png")

train_start = 365
train_end = size(kde_matrix)[1] - 364
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
opt = Descent(0.001)

m(train_XY[1][1])
[loss(x,y) for (x,y) in train_XY[1:5]]


Flux.train!(loss, params(m), train_XY, opt, cb = evalcb)


lims = (0, maximum(maximum.(kdes)))
offset = 1
for (kde_slice, slice_time) in zip(kdes, slice_times)
    display(heatmap(log10.(kde_slice .+ offset),
            title=string(julian2datetime(slice_time)),
            clims=log10.(lims .+ offset), axis=false, grid=false))
end

anim = @animate for (kde_slice, slice_time) in zip(kdes, slice_times)
    heatmap(log10.(kde_slice .+ offset),
            title=string(julian2datetime(slice_time)),
            clims=log10.(lims .+ offset),
            axis=false, grid=false)
end
gif(anim, "/Users/cdaley/Downloads/kde.gif", fps=10)





heatmap(kdes[1], clims=(0,maximum(maximum.(kdes))))









pdf
KernelDensityEstimate.evaluate()
resample(pdf, 100)
KernelDensityEstimate.sample(pdf, 1)

KernelDensityEstimate.evaluate
KernelDensityEstimate.
marginal(pdf, [1,2,3])
