import numpy as np
import mikeio
import mikeio.generic
import pandas as pd
import math, time, matplotlib.pyplot as plt, pylab;
import matplotlib
# Force matplotlib to not use any Xwindows backend.
matplotlib.use('Agg')
import imageio.v3 as iio

filename = "./wetting-drying/unstruct/2D_wetting-drying-unstruct_SW/proj.mfm"+" "+"-"+" "+"Result Files"+"/global_2D.dfsu"
dfs = mikeio.open(filename)
dfs

ds = dfs.read(items="Total water depth")
ds.shape
date_ran = pd.date_range("2019-10-29 23", "2019-11-03 00", freq="15min")
len(date_ran)

import os
os.system("rm ./wetting-drying/unstruct/2D_wetting-drying-unstruct_SW/anim/Toronto-*.jpg")
# os.system("mkdir -p ./2039/anim/2/")

# Set font properties globally
plt.rcParams['font.family'] = "FreeSerif"
# Set font properties globally
plt.rcParams['font.size'] = 16
plt.rcParams['axes.unicode_minus'] = False
plt.figure(dpi=600)
plt.rcParams['text.usetex'] = False

ds_1 = ds[0]
def plot_wd_contours(time_step, fig_str, lon1, lat1, lon2, lat2):
    df_depth = ds_1[time_step]
    fig, ax = plt.subplots(figsize = (12.5, 9.5))
    df_depth.plot(ax=ax, vmin=0.0, vmax=1.0, levels=11, plot_type='shaded', cmap='winter_r', figsize=(12,9.5), title=date_ran[time_step], label='$h$ (m)');
    ax.set_xlim([lon1, lon2])
    ax.set_ylim([lat1, lat2])
    fig.savefig(fig_str, dpi=200)

for frame in np.arange(len(date_ran)):
    plot_wd_contours(frame, "./wetting-drying/unstruct/2D_wetting-drying-unstruct_SW/anim/Toronto-"+str(frame)+".jpg", -79.6738, 43.4505, -79.0783, 43.8209)

gif_path = "./Toronto.gif"
frames = np.stack([iio.imread(f"./wetting-drying/unstruct/2D_wetting-drying-unstruct_SW/anim/Toronto-"+{x}+".jpg") for x in range(len(date_ran))], axis=0)

iio.imwrite(gif_path, frames)
