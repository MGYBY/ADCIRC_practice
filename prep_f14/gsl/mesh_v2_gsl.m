clearvars; clc; close all
set(0,'defaultAxesFontSize',22);
% set(0,'DefaultFigurePaperPositionMode','auto')
set(0,'defaultAxesFontName','Times New Roman')
set(gcf,'position',[10,10,1200,750])
set(0, 'DefaultLineLineWidth', 0.5);
set(gca, 'OuterPosition', [0,0,1,1])

% refined grid
% max_el = 2.5e3;
% min_el = 0.2e3;
% max_el_ns = 0.3e3;
% slp = 10;
% R_val = 3.0;
% grade_val = 0.25;

% regular grid
% max_el = 5.0e3;
% min_el = 0.10e3;
% max_el_ns = 0.20e3;
% slp = 9;
% R_val = 3.0;
% grade_val = 0.2;

% moderately coarse grid
max_el = 10.0e3;
min_el = 0.500e3;
max_el_ns = 0.5e3;
slp = 7;
R_val = 3.0;
grade_val = 0.36;

% coarse grid
% max_el = 25e3;
% min_el = 0.79e3;
% max_el_ns = 0.8e3;
% slp = 8;
% R_val = 3.0;
% grade_val = 0.35;

dt_val = 5.50;

coastline = './outline';
nc_file = './main-basin_east-arm.nc';
% nc_file = './mike_depth.nc';
bbox = [-117.20 -109.0; 60.7 63.0];
% gdat = geodata('shp', coastline, 'dem', nc_file, 'bbox', bbox, 'h0', min_el, 'inner', 1, 'mainland', 0);
gdat = geodata('shp', coastline, 'dem', nc_file, 'bbox', bbox, 'h0', min_el);

gdat.inpoly_flip = mod(1,gdat.inpoly_flip) ;

fh1 = edgefx('geodata', gdat, 'fs', R_val, 'max_el', [(max_el*12.0) 0.0 1000.0; (max_el) -10.0 0.0; (max_el)/1.5 -30 -10.0; (max_el)/3.00 -100 -30; (max_el)/5.0 -1000 -100], 'dt', dt_val, 'g', grade_val, 'slp',[2 0.0 1000.1; slp -50 0.0; 10 -1000 -50]);

mshopts = meshgen('ef',fh1,'bou',gdat,'plot_on',1,'nscreen',5,'proj','trans', 'itmax', 205, 'qual_tol', 0.020);
mshopts = mshopts.build;
m = mshopts.grd;

m = m.clean;

% m = make_bc(m,'auto',gdat,'distance'); % make the boundary conditions
plot(m,'type','tri','LineWidth',0.25);

m = interp(m,gdat, 'type', 'depth' ,'mindepth', 0.2); % interpolate bathy to the mesh with minimum depth of 1 m
% m = interp(m,gdat);
m = lim_bathy_slope(m,0.1,0);
CFL = CalcCFL(m,dt_val);
max(CFL)
min(CFL)
m = bound_courant_number(m,dt_val);

%% Make the nodestring boundary conditions
% m = make_bc(m,'auto',gdat,'distance');
m = make_bc(m,'auto',gdat);

%% Identify vstart and vend of each riverine boundary
% use the comannd-line method to identify the vstart and vend for each...
% riverine boundary based on the coordinates of river edge.
% FIXME: this feature for OBC does not work now
% river_points1 = [-113.423	61.982; -112.766	61.4434]; % coordinates of river edge
% river_points2 = [-115.1815	62.506; -115.3264	62.2249]; % coordinates of river edge
% bc_k1 = ourKNNsearch(m.p',river_points1',1);
% bc_k2 = ourKNNsearch(m.p',river_points2',1);
% m = make_bc(m,'outer',1,bc_k1(1),bc_k1(2));
% m = make_bc(m,'outer',1,bc_k2(1),bc_k2(2));

% use the data cursor method to identify the vstart and vend for each...
% riverine boundary manually (GUI).
% m = make_bc(m,'outer',1); % 1,2206,2107,1(flux),22(River)
% m = make_bc(m,'outer',2); % 1,14784,14779,1(flux),22(River)

m = renum(m);

m = Calc_tau0(m);
% m = Calc_f13(m, 'average_horizontal_eddy_viscosity_in_sea_water_wrt_depth');

% m = Make_f15(obj=m, ts = '01-Jan-2018 03:00', te = '01-Feb-2018 22:00', dt=2);
m = Make_f15( m, '01-Jan-2018 03:00', '01-Feb-2018 22:00', 1) ; 

plot(m,'type','bd','LineWidth',0.1);

plot(m,'type','b');   % plot bathy on native projection

%% Export plots
figs = get(0,'children');
for f = 1:numel(figs)
    fname = sprintf('plot%i', figs(f).Number);
    print(figs(f).Number,fname,'-djpeg','-r800');
end

%% Save mesh files
% Save as a msh class
% save(sprintf('%s_msh.mat',PREFIX),'m');
% % Write an ADCIRC fort.14 compliant file to disk.
write(m, 'gsl')
% writefort15(m, 'lo15')

%% mean projection coordinate of CPP
xy = m.p;
x = xy(:,1);
y = xy(:,2);
mean_x = mean(x);
mean_y = mean(y);