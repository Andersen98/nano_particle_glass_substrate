#!/usr/bin/gnuplot

reset session

set fontpath ""

set term gif large font '/usr/share/fonts/TTF/DejaVuSans.ttf' size 1920,1080 animate delay 15 loop 0
set output 'energy_runtime_10_steps_25.gif'

index(tt) = sprintf("%09.2f",tt)
output_filename(quantity, tt, suffix) = quantity . '-' .  index(tt) . '.' . suffix
my_image_ii(t_init,dt,ii) = "data/" . output_filename("ez",t_init+dt*ii,"png")

#print  ('ez-000000.40.png' eq name("ez", 0.4, "png")


do for [ii=1:24] {
    filename = my_image_ii(0.4,.4,ii)
    set multiplot layout 1,2
    plot [t = 0:2] [0:0.001] 'data/sanity.dat' index ii with lp
    plot filename binary filetype=png with rgbimage
    unset multiplot
}
